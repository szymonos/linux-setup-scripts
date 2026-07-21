#!/usr/bin/env -S uv run --frozen python
"""
Bundled helpers for /prepare-pr.

Subcommands: sync-trunk, trunk, trunk-name, trunk-ref, branch-safety,
preflight-wip, phase2-base, signals, architecture.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # Python < 3.11 - config support degrades to no-op
    tomllib = None  # type: ignore[assignment]

WELL_KNOWN_TRUNK_NAMES = ("main", "master", "trunk", "prod")
WELL_KNOWN_PROTECTED_BRANCHES = ("main", "master", "develop", "trunk", "prod")
PROTECTED_BRANCH_PATTERNS = (re.compile(r"^release/"),)

LINT_FIX_RE = re.compile(
    r"(?:fix|fixup|fix up)\s*(?:lint|hook|linter|format|whitespace|trailing)",
    re.IGNORECASE,
)
CORRECTION_RE = re.compile(
    r"^(?:fix:|revert:|actually|no,|oops|wrong)",
    re.IGNORECASE,
)

# Per-repo config keeps this script portable: repo-specific layout (the
# ARCHITECTURE staleness map, doc/lessons paths) lives in `.claude/prepare-pr.toml`
# at the repo root, NOT baked into this file. Absent config -> graceful no-op
# (the `architecture` staleness check simply finds nothing). See SKILL.md and the
# `[architecture_sections]` example in the repo's own `.claude/prepare-pr.toml`.
CONFIG_RELPATH = ".claude/prepare-pr.toml"
DEFAULT_LESSONS_PATH = "design/lessons.md"
DEFAULT_ARCHITECTURE_DOC = "ARCHITECTURE.md"


def _run(cmd: list[str], **kwargs: object) -> str:
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, **kwargs)
    except FileNotFoundError:
        # Executable not on PATH - treat as soft failure so callers can fall
        # back through the resolution chain (e.g., trunk detection probes
        # well-known refs when `gh` is unavailable).
        return ""
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def _repo_root() -> Path:
    """Return the git worktree root, or cwd if `git` can't resolve it."""
    top = _run(["git", "rev-parse", "--show-toplevel"])
    return Path(top) if top else Path.cwd()


def _load_config() -> dict[str, object]:
    """
    Load `.claude/prepare-pr.toml` from the repo root, if present.

    Returns {} when the file is absent, unreadable, malformed, or when tomllib is
    unavailable (Python < 3.11). Every consumer must treat {} as "no repo-specific
    config" and fall back to defaults - this is what keeps the script portable to
    repos that ship no config at all.
    """
    if tomllib is None:
        return {}
    cfg_path = _repo_root() / CONFIG_RELPATH
    if not cfg_path.is_file():
        return {}
    try:
        with cfg_path.open("rb") as fh:
            return tomllib.load(fh)
    except (OSError, tomllib.TOMLDecodeError):
        return {}


def _config_architecture_sections(cfg: dict[str, object]) -> dict[str, list[str]]:
    """
    Extract the {section_name: [path_prefix, ...]} map from config.

    Accepts only string keys mapping to lists of strings; silently drops malformed
    entries so a partly-broken config still yields the usable sections rather than
    erroring the whole run.
    """
    raw = cfg.get("architecture_sections")
    if not isinstance(raw, dict):
        return {}
    sections: dict[str, list[str]] = {}
    for name, prefixes in raw.items():
        if isinstance(name, str) and isinstance(prefixes, list):
            clean = [p for p in prefixes if isinstance(p, str) and p]
            if clean:
                sections[name] = clean
    return sections


def _commits_since(base: str) -> list[dict[str, str]]:
    log = _run(["git", "log", "--format=%H|%s", f"{base}..HEAD"])
    if not log:
        return []
    commits = []
    for line in log.splitlines():
        if "|" not in line:
            continue
        sha, subject = line.split("|", 1)
        commits.append({"sha": sha.strip(), "subject": subject.strip()})
    return commits


def _files_in_commit(sha: str) -> list[str]:
    out = _run(["git", "diff-tree", "--no-commit-id", "--name-only", "-r", sha])
    return [f for f in out.splitlines() if f] if out else []


def _changed_files_since(base: str) -> list[str]:
    out = _run(["git", "diff", "--name-only", f"{base}..HEAD"])
    return [f for f in out.splitlines() if f] if out else []


def _next_lesson_id(lessons_path: Path) -> int:
    if not lessons_path.exists():
        return 1
    text = lessons_path.read_text(encoding="utf-8", errors="replace")
    ids = [int(m.group(1)) for m in re.finditer(r"^## L-(\d{3})", text, re.MULTILINE)]
    return (max(ids) + 1) if ids else 1


def _existing_lessons(lessons_path: Path) -> list[str]:
    if not lessons_path.exists():
        return []
    text = lessons_path.read_text(encoding="utf-8", errors="replace")
    return re.findall(r"^## L-\d{3} - .+$", text, re.MULTILINE)


def _emit(payload: dict[str, object], code: int = 0) -> int:
    """Emit JSON payload to stdout and return exit code."""
    json.dump(payload, sys.stdout, indent=2)
    print()
    return code


def _resolve_trunk_name() -> str:
    """Resolve trunk name via the SKILL.md fallback chain."""
    ref = _run(["git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD"])
    if ref:
        return ref.removeprefix("origin/")
    gh_default = _run(
        [
            "gh",
            "repo",
            "view",
            "--json",
            "defaultBranchRef",
            "-q",
            ".defaultBranchRef.name",
        ]
    )
    if gh_default:
        return gh_default
    for name in WELL_KNOWN_TRUNK_NAMES:
        if _ref_exists(f"refs/heads/{name}") or _ref_exists(
            f"refs/remotes/origin/{name}"
        ):
            return name
    return ""


def _ref_exists(ref: str) -> bool:
    """Return True if ref resolves under `git show-ref --verify`."""
    try:
        result = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", ref], capture_output=True
        )
    except FileNotFoundError:
        return False
    return result.returncode == 0


def _run_ok(cmd: list[str]) -> bool:
    """Run a command, returning True only on a zero exit (git binary present)."""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
    except FileNotFoundError:
        return False
    return result.returncode == 0


def _is_ancestor(ancestor: str, descendant: str) -> bool:
    """Return True if `ancestor` is an ancestor of `descendant`."""
    return _run_ok(["git", "merge-base", "--is-ancestor", ancestor, descendant])


def _resolve_trunk_ref(name: str) -> str:
    """
    Pick a usable trunk ref, preferring origin/<name> over the local branch.

    origin/<name> is authoritative - it's what the PR/merge is computed against,
    and it stays current on fetch. A local trunk branch can lag behind (nobody
    runs `git checkout main && git pull` on a feature-branch workflow), and using
    a stale local ref makes every merge-base (phase2-base, architecture, signals)
    resolve too far back, pulling already-merged commits into the diff/reset.
    Fall back to the local branch only when there's no remote-tracking ref.
    """
    if _ref_exists(f"refs/remotes/origin/{name}"):
        return f"origin/{name}"
    if _ref_exists(f"refs/heads/{name}"):
        return name
    return ""


def cmd_sync_trunk(args: argparse.Namespace) -> int:
    """
    Fetch origin and fast-forward the local trunk branch if it is behind.

    Runs once at the very start of Phase 1, before any merge-base/diff/lint uses
    the trunk. Fetching de-stales origin/<name>; fast-forwarding the local branch
    keeps consumers that read the LOCAL ref correct too (notably this repo's
    `make lint-diff --from-ref main`). The working tree is untouched - trunk is
    never checked out; the local ref is moved with `git update-ref`.

    Outcomes (JSON `action`):
      up-to-date    - local trunk already equals origin
      fast-forwarded- local trunk moved forward to origin
      diverged      - local trunk has commits not on origin -> ABORT (exit 1)
      no-local      - no local trunk branch; origin/<name> is used directly
      no-origin     - no remote-tracking ref (nothing to sync against)
      offline       - fetch failed (no network/remote) -> warn, continue
    """
    name = args.trunk_name or _resolve_trunk_name()
    if not name:
        return _emit(
            {
                "synced": False,
                "action": "error",
                "reason": (
                    "could not resolve trunk name; run: git remote set-head origin -a"
                ),
            },
            code=1,
        )

    local_ref = f"refs/heads/{name}"
    origin_ref = f"refs/remotes/origin/{name}"
    has_local = _ref_exists(local_ref)

    # Fetch so origin/<name> is current. Non-fatal: offline dev must still work.
    fetched = _run_ok(["git", "fetch", "origin", name])
    if not fetched:
        return _emit(
            {
                "synced": False,
                "action": "offline",
                "name": name,
                "reason": (
                    f"git fetch origin {name} failed; proceeding with existing refs"
                ),
            }
        )

    if not _ref_exists(origin_ref):
        return _emit({"synced": False, "action": "no-origin", "name": name})

    origin_sha = _run(["git", "rev-parse", origin_ref])
    if not has_local:
        return _emit(
            {"synced": False, "action": "no-local", "name": name, "origin": origin_sha}
        )

    local_sha = _run(["git", "rev-parse", local_ref])
    if local_sha == origin_sha:
        return _emit(
            {"synced": True, "action": "up-to-date", "name": name, "local": local_sha}
        )

    # Behind: local is a strict ancestor of origin -> safe fast-forward.
    if _is_ancestor(local_sha, origin_ref):
        # Never fast-forward a checked-out branch; on a feature branch this is
        # safe, but guard anyway so we don't desync the index/working tree.
        current = _run(["git", "branch", "--show-current"])
        if current == name:
            return _emit(
                {
                    "synced": False,
                    "action": "on-trunk",
                    "name": name,
                    "reason": (
                        f"currently on '{name}'; run `git pull --ff-only` yourself"
                    ),
                },
                code=1,
            )
        if not _run_ok(["git", "update-ref", local_ref, origin_sha]):
            return _emit(
                {
                    "synced": False,
                    "action": "error",
                    "name": name,
                    "reason": (
                        f"git update-ref {local_ref} failed; local trunk left unchanged"
                    ),
                },
                code=1,
            )
        return _emit(
            {
                "synced": True,
                "action": "fast-forwarded",
                "name": name,
                "local_before": local_sha,
                "local_after": origin_sha,
            }
        )

    # Diverged: local has commits not on origin. Abort per design.
    return _emit(
        {
            "synced": False,
            "action": "diverged",
            "name": name,
            "local": local_sha,
            "origin": origin_sha,
            "reason": (
                f"local '{name}' has commits not on origin/{name}; "
                f"resolve manually (e.g. git checkout {name} && git pull --ff-only) "
                "before rewriting history"
            ),
        },
        code=1,
    )


def cmd_trunk(_args: argparse.Namespace) -> int:
    """Resolve the trunk branch into name + usable git ref (diagnostic JSON)."""
    name = _resolve_trunk_name()
    if not name:
        return _emit(
            {
                "error": "Could not resolve trunk; run: git remote set-head origin -a",
            },
            code=1,
        )
    ref = _resolve_trunk_ref(name)
    if not ref:
        return _emit(
            {
                "name": name,
                "error": (
                    f"Trunk '{name}' has no local or remote ref; "
                    f"run: git fetch origin {name}"
                ),
            },
            code=1,
        )
    return _emit({"name": name, "ref": ref})


def cmd_trunk_name(_args: argparse.Namespace) -> int:
    """Print just the trunk branch name (plain text, for gh pr create --base)."""
    name = _resolve_trunk_name()
    if not name:
        print(
            "Could not resolve trunk; run: git remote set-head origin -a",
            file=sys.stderr,
        )
        return 1
    print(name)
    return 0


def cmd_trunk_ref(_args: argparse.Namespace) -> int:
    """Print just the trunk git ref (plain text, for git log/diff/merge-base/reset)."""
    name = _resolve_trunk_name()
    if not name:
        print(
            "Could not resolve trunk; run: git remote set-head origin -a",
            file=sys.stderr,
        )
        return 1
    ref = _resolve_trunk_ref(name)
    if not ref:
        print(
            f"Trunk '{name}' has no local or remote ref; run: git fetch origin {name}",
            file=sys.stderr,
        )
        return 1
    print(ref)
    return 0


def cmd_branch_safety(args: argparse.Namespace) -> int:
    """Refuse if current branch matches trunk or any protected name."""
    current = _run(["git", "branch", "--show-current"])
    if not current:
        return _emit({"safe": False, "current": "", "reason": "detached HEAD"}, code=1)
    trunk_name = args.trunk_name or _resolve_trunk_name()
    if not trunk_name:
        return _emit(
            {
                "safe": False,
                "current": current,
                "reason": (
                    "could not resolve trunk name - fail-closed to prevent "
                    "destructive rewrite; pass --trunk-name or run: "
                    "git remote set-head origin -a"
                ),
            },
            code=1,
        )
    if current == trunk_name:
        return _emit(
            {
                "safe": False,
                "current": current,
                "trunk_name": trunk_name,
                "reason": "current branch is the trunk",
            },
            code=1,
        )
    if current in WELL_KNOWN_PROTECTED_BRANCHES:
        return _emit(
            {
                "safe": False,
                "current": current,
                "trunk_name": trunk_name,
                "reason": "current branch is a well-known protected name",
            },
            code=1,
        )
    if any(p.match(current) for p in PROTECTED_BRANCH_PATTERNS):
        return _emit(
            {
                "safe": False,
                "current": current,
                "trunk_name": trunk_name,
                "reason": "current branch matches a release/* pattern",
            },
            code=1,
        )
    return _emit({"safe": True, "current": current, "trunk_name": trunk_name})


def cmd_preflight_wip(args: argparse.Namespace) -> int:
    """
    Self-applying WIP guard: print 'created-wip' or 'skip' and act accordingly.

    By default (no flag), this subcommand BOTH decides AND acts: if a WIP commit
    is needed, it runs `git add -A && git commit --no-verify -m "WIP for review"`
    itself, then prints 'created-wip' on stdout. If the tree is already clean or
    the branch is at parity with trunk, it prints 'skip'. The agent's job is one
    line: run the command. No stdout parsing, no conditional follow-up commands -
    that's the failure mode this design eliminates.

    `--dry-run` restores the old behavior: print 'create-wip' or 'skip' but do
    not commit. Useful for tests and for callers that want to inspect first.
    """
    trunk_ref = args.trunk_ref or _resolve_trunk_ref(_resolve_trunk_name())
    if not trunk_ref:
        print(
            "could not resolve trunk_ref - pass --trunk-ref or run: "
            "git remote set-head origin -a",
            file=sys.stderr,
        )
        return 1
    base = _run(["git", "merge-base", trunk_ref, "HEAD"])
    head = _run(["git", "rev-parse", "HEAD"])
    porcelain = _run(["git", "status", "--porcelain", "--untracked-files=all"])
    if not base or not head:
        print("git merge-base or rev-parse failed", file=sys.stderr)
        return 1
    dirty = bool(porcelain)
    at_parity = base == head
    if not dirty and at_parity:
        print("skip")
        print(
            "branch clean and at parity with trunk - nothing to review",
            file=sys.stderr,
        )
        return 0
    if not dirty:
        print("skip")
        print(
            "working tree clean - existing commits ARE the review scope",
            file=sys.stderr,
        )
        return 0
    reason = (
        "branch at parity with trunk AND working tree dirty"
        if at_parity
        else "branch has commits ahead of trunk AND working tree dirty - "
        "WIP needed so /second-opinion sees committed + uncommitted together"
    )
    if args.dry_run:
        print("create-wip")
        print(reason, file=sys.stderr)
        return 0
    add_rc = subprocess.run(
        ["git", "add", "-A"], capture_output=True, text=True, check=False
    )
    if add_rc.returncode != 0:
        print(f"git add -A failed: {add_rc.stderr.strip()}", file=sys.stderr)
        return 1
    commit_rc = subprocess.run(
        ["git", "commit", "--no-verify", "-m", "WIP for review"],
        capture_output=True,
        text=True,
        check=False,
    )
    if commit_rc.returncode != 0:
        err = commit_rc.stderr.strip() or commit_rc.stdout.strip()
        print(f"git commit failed: {err}", file=sys.stderr)
        return 1
    print("created-wip")
    print(f"{reason} - WIP commit created", file=sys.stderr)
    return 0


def cmd_phase2_base(args: argparse.Namespace) -> int:
    """Print the merge-base SHA to soft-reset to in Phase 2 (plain text on stdout)."""
    trunk_ref = args.trunk_ref or _resolve_trunk_ref(_resolve_trunk_name())
    if not trunk_ref:
        print("could not resolve trunk_ref", file=sys.stderr)
        return 1
    sha = _run(["git", "merge-base", trunk_ref, "HEAD"])
    if not sha:
        print(f"git merge-base {trunk_ref} HEAD returned nothing", file=sys.stderr)
        return 1
    print(sha)
    return 0


def cmd_signals(args: argparse.Namespace) -> int:
    """Extract learning signals from WIP history."""
    if args.base:
        base = args.base
    else:
        trunk_ref = _resolve_trunk_ref(_resolve_trunk_name())
        if not trunk_ref:
            return _emit(
                {
                    "error": (
                        "Could not resolve trunk; pass --base or run: "
                        "git remote set-head origin -a"
                    )
                },
                code=1,
            )
        base = _run(["git", "merge-base", trunk_ref, "HEAD"])
    if not base:
        return _emit({"error": "Could not determine merge-base"}, code=1)

    if args.lessons:
        # resolve a relative --lessons against the repo root too (absolute paths
        # pass through unchanged), so behavior matches the config/default path and
        # doesn't depend on the cwd the command happens to run from
        lessons_path = _repo_root() / args.lessons
    else:
        cfg = _load_config()
        cfg_lessons = cfg.get("lessons_path")
        rel = (
            cfg_lessons
            if isinstance(cfg_lessons, str) and cfg_lessons
            else DEFAULT_LESSONS_PATH
        )
        lessons_path = _repo_root() / rel

    commits = _commits_since(base)
    if not commits:
        json.dump(
            {
                "signals": [],
                "next_lesson_id": _next_lesson_id(lessons_path),
                "existing_entries": _existing_lessons(lessons_path),
                "lessons_exists": lessons_path.exists(),
            },
            sys.stdout,
            indent=2,
        )
        print()
        return 0

    file_counts: dict[str, int] = {}
    for c in commits:
        for f in _files_in_commit(c["sha"]):
            file_counts[f] = file_counts.get(f, 0) + 1

    signals = []

    repeated = [
        {"file": f, "commit_count": n}
        for f, n in sorted(file_counts.items(), key=lambda x: -x[1])
        if n >= 3
    ]
    if repeated:
        signals.append({"type": "repeated_edits", "items": repeated})

    lint_fixes = [
        {"sha": c["sha"][:7], "subject": c["subject"]}
        for c in commits
        if LINT_FIX_RE.search(c["subject"])
    ]
    if lint_fixes:
        signals.append({"type": "lint_fixes", "items": lint_fixes})

    corrections = [
        {"sha": c["sha"][:7], "subject": c["subject"]}
        for c in commits
        if CORRECTION_RE.match(c["subject"])
    ]
    if corrections:
        signals.append({"type": "corrections", "items": corrections})

    next_id = _next_lesson_id(lessons_path)
    existing = _existing_lessons(lessons_path)

    result = {
        "signals": signals,
        "next_lesson_id": next_id,
        "existing_entries": existing,
        "lessons_exists": lessons_path.exists(),
    }

    json.dump(result, sys.stdout, indent=2)
    print()
    return 0


def cmd_architecture(args: argparse.Namespace) -> int:
    """Check ARCHITECTURE.md for staleness against the branch diff."""
    if args.base:
        base = args.base
    else:
        trunk_ref = _resolve_trunk_ref(_resolve_trunk_name())
        if not trunk_ref:
            return _emit(
                {
                    "error": (
                        "Could not resolve trunk; pass --base or run: "
                        "git remote set-head origin -a"
                    )
                },
                code=1,
            )
        base = _run(["git", "merge-base", trunk_ref, "HEAD"])
    if not base:
        return _emit({"error": "Could not determine merge-base"}, code=1)

    cfg = _load_config()
    arch_doc = cfg.get("architecture_doc")
    if not isinstance(arch_doc, str) or not arch_doc:
        arch_doc = DEFAULT_ARCHITECTURE_DOC
    sections = _config_architecture_sections(cfg)

    arch_path = _repo_root() / arch_doc
    if not arch_path.exists():
        json.dump(
            {
                "stale_sections": [],
                "architecture_exists": False,
                "architecture_doc": arch_doc,
                "config_present": bool(cfg),
                "changed_files_count": len(_changed_files_since(base)),
            },
            sys.stdout,
            indent=2,
        )
        print()
        return 0

    # No section map configured -> nothing to key staleness off. This is the
    # portable default: a repo with no `[architecture_sections]` gets a clean
    # no-op rather than an error, so Phase 1.5c simply finds nothing to update.
    if not sections:
        json.dump(
            {
                "stale_sections": [],
                "architecture_exists": True,
                "architecture_doc": arch_doc,
                "config_present": bool(cfg),
                "changed_files_count": len(_changed_files_since(base)),
            },
            sys.stdout,
            indent=2,
        )
        print()
        return 0

    changed_files = _changed_files_since(base)
    stale = [
        section_name
        for section_name, path_prefixes in sections.items()
        if any(
            f.startswith(prefix) for prefix in path_prefixes for f in changed_files
        )
    ]

    result = {
        "stale_sections": stale,
        "architecture_exists": True,
        "architecture_doc": arch_doc,
        "config_present": bool(cfg),
        "changed_files_count": len(changed_files),
    }

    json.dump(result, sys.stdout, indent=2)
    print()
    return 0


def main() -> int:
    """CLI entry point for /prepare-pr helpers."""
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    st = sub.add_parser(
        "sync-trunk",
        help="Fetch origin and fast-forward local trunk if behind (abort if diverged)",
    )
    st.add_argument("--trunk-name", help="Override trunk name (default: autoresolve)")

    sub.add_parser("trunk", help="Resolve trunk name + ref (JSON, diagnostic)")
    sub.add_parser(
        "trunk-name", help="Print trunk branch name (plain text, for gh pr create)"
    )
    sub.add_parser(
        "trunk-ref",
        help="Print trunk git ref (plain text, for git log/diff/merge-base/reset)",
    )

    bs = sub.add_parser(
        "branch-safety", help="Verify current branch is safe to rewrite"
    )
    bs.add_argument("--trunk-name", help="Override trunk name (default: autoresolve)")

    pf = sub.add_parser(
        "preflight-wip",
        help=(
            "Self-applying WIP guard for Phase 1.5: commits dirty work itself "
            "(use --dry-run to inspect without committing)."
        ),
    )
    pf.add_argument("--trunk-ref", help="Override trunk ref (default: autoresolve)")
    pf.add_argument(
        "--dry-run",
        action="store_true",
        help="Print 'create-wip'/'skip' but do NOT commit (legacy behavior).",
    )

    pb = sub.add_parser(
        "phase2-base",
        help="Emit the merge-base SHA to soft-reset to in Phase 2",
    )
    pb.add_argument("--trunk-ref", help="Override trunk ref (default: autoresolve)")

    sig = sub.add_parser("signals", help="Extract learning signals from WIP history")
    sig.add_argument(
        "--base", help="Git ref to diff against (default: merge-base with trunk)"
    )
    sig.add_argument(
        "--lessons", help="Path to lessons.md (default: design/lessons.md)"
    )

    arch = sub.add_parser("architecture", help="Check ARCHITECTURE.md for staleness")
    arch.add_argument(
        "--base", help="Git ref to diff against (default: merge-base with trunk)"
    )

    args = parser.parse_args()

    dispatch = {
        "sync-trunk": cmd_sync_trunk,
        "trunk": cmd_trunk,
        "trunk-name": cmd_trunk_name,
        "trunk-ref": cmd_trunk_ref,
        "branch-safety": cmd_branch_safety,
        "preflight-wip": cmd_preflight_wip,
        "phase2-base": cmd_phase2_base,
        "signals": cmd_signals,
        "architecture": cmd_architecture,
    }
    handler = dispatch.get(args.command)
    if handler is None:
        return 1
    return handler(args)


if __name__ == "__main__":
    raise SystemExit(main())
