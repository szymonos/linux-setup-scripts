"""
Check nix-path shell scripts for bash 3.2 / BSD sed compatibility violations.

Enforces the constraints documented in ARCHITECTURE.md: nix-path .sh files
must not use bash 4+ features or GNU-only sed/grep syntax, because they
run on macOS where bash 3.2 and BSD tools are the system default.

The set of constrained files is defined by ARCHITECTURE.md "nix-path" table.

# :example
python3 -m tests.hooks.check_bash32 nix/setup.sh
python3 -m tests.hooks.check_bash32
"""

import re
import sys
from pathlib import Path
from typing import NamedTuple

# ---------------------------------------------------------------------------
# Checked file patterns (nix-path files + bats tests that run on macOS CI)
# ---------------------------------------------------------------------------
NIX_PATH_PATTERNS: tuple[str, ...] = (
    "nix/setup.sh",
    "nix/configure/*.sh",
    ".assets/lib/scopes.sh",
    ".assets/lib/profile_block.sh",
    ".assets/config/bash_cfg/aliases_nix.sh",
    ".assets/config/bash_cfg/aliases_git.sh",
    ".assets/config/bash_cfg/aliases_kubectl.sh",
    ".assets/config/bash_cfg/functions.sh",
    ".assets/setup/setup_common.sh",
    ".assets/provision/install_copilot.sh",
    "tests/bats/*.bats",
)

# ---------------------------------------------------------------------------
# Rules: each is (compiled regex, human description)
# ---------------------------------------------------------------------------


class Rule(NamedTuple):
    pattern: re.Pattern[str]
    description: str


# Lines starting with # are comments - we skip them during checking.
# We also skip lines inside : '...' heredoc-style comment blocks.

RULES: tuple[Rule, ...] = (
    # -- bash 4+ builtins / syntax ------------------------------------------
    Rule(
        re.compile(r"\bmapfile\b"),
        "mapfile is bash 4+ - use while IFS= read -r loop",
    ),
    Rule(
        re.compile(r"\breadarray\b"),
        "readarray is bash 4+ - use while IFS= read -r loop",
    ),
    Rule(
        re.compile(r"\bdeclare\s+-A\b"),
        "declare -A (associative array) is bash 4+ - use space-delimited strings",
    ),
    Rule(
        re.compile(r"\bdeclare\s+-n\b"),
        "declare -n (nameref) is bash 4+ - pass variable name as string",
    ),
    Rule(
        re.compile(r"\$\{[a-zA-Z_][a-zA-Z0-9_]*,,\}"),
        "${var,,} (lowercase) is bash 4+ - use tr '[:upper:]' '[:lower:]'",
    ),
    Rule(
        re.compile(r"\$\{[a-zA-Z_][a-zA-Z0-9_]*\^\^\}"),
        "${var^^} (uppercase) is bash 4+ - use tr '[:lower:]' '[:upper:]'",
    ),
    Rule(
        re.compile(r"\$\{[a-zA-Z_][a-zA-Z0-9_]*\[-(0*[1-9][0-9]*)\]\}"),
        "negative array index is bash 4.3+ - use ${arr[$((${#arr[@]}-N))]}",
    ),
    # -- GNU sed / grep extensions ------------------------------------------
    Rule(
        re.compile(r"\bsed\b.*\\s"),
        r"sed \s is a GNU extension - use [[:space:]]",
    ),
    Rule(
        re.compile(r"\bsed\s+(-[^E ]*\s+)?-i\s+''"),
        "sed -i '' is not portable - write to temp file + mv",
    ),
    Rule(
        re.compile(r"\bsed\s+.*-r\b"),
        "sed -r is GNU only - use sed -E",
    ),
    Rule(
        re.compile(r"\bgrep\s+.*-P\b"),
        "grep -P (PCRE) is GNU only - use grep -E or sed",
    ),
    Rule(
        re.compile(r"\bgrep\b.*\\S"),
        r"grep \S is a PCRE/GNU extension - use [^[:space:]]",
    ),
    Rule(
        re.compile(r"\bgrep\b.*\\w"),
        r"grep \w is a PCRE/GNU extension - use [a-zA-Z0-9_]",
    ),
    Rule(
        re.compile(r"\bgrep\b.*\\d"),
        r"grep \d is a PCRE/GNU extension - use [0-9]",
    ),
    # -- BSD sed grouping ---------------------------------------------------
    Rule(
        re.compile(r"\bsed\b.*\{.*[;/].*\}"),
        "sed { cmd } on one line fails on BSD sed - put commands on separate lines",
    ),
)


def _resolve_nix_path_files(repo_root: Path) -> set[Path]:
    """Resolve glob patterns to actual files under repo_root."""
    files: set[Path] = set()
    for pattern in NIX_PATH_PATTERNS:
        for match in repo_root.glob(pattern):
            if match.is_file():
                files.add(match)
    return files


def _is_nix_path_file(filepath: Path, nix_files: set[Path]) -> bool:
    """Check if a resolved filepath is in the nix-path set."""
    return filepath.resolve() in nix_files


def check_file(filepath: Path) -> list[str]:
    """Check a single file for bash 3.2 / BSD compatibility violations."""
    problems: list[str] = []
    try:
        lines = filepath.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return problems

    in_colon_heredoc = False
    for lineno, line in enumerate(lines, start=1):
        stripped = line.lstrip()

        # track : '...' comment blocks (used for runnable examples)
        if not in_colon_heredoc and stripped.startswith(": '"):
            in_colon_heredoc = True
            continue
        if in_colon_heredoc:
            if stripped.rstrip() == "'":
                in_colon_heredoc = False
            continue

        # skip comments
        if stripped.startswith("#"):
            continue

        for rule in RULES:
            if rule.pattern.search(line):
                rel = filepath.as_posix()
                problems.append(f"{rel}:{lineno}: {rule.description}")
    return problems


def main(argv: list[str]) -> int:
    repo_root = Path(__file__).resolve().parents[2]
    nix_files = _resolve_nix_path_files(repo_root)

    if not nix_files:
        return 0

    # if filenames passed, filter to nix-path only; otherwise check all
    if argv:
        targets = [Path(f).resolve() for f in argv if Path(f).resolve() in nix_files]
    else:
        targets = sorted(nix_files)

    if not targets:
        return 0

    problems: list[str] = []
    for filepath in targets:
        # make paths relative for readable output
        try:
            rel = filepath.relative_to(repo_root)
        except ValueError:
            rel = filepath
        problems.extend(check_file(rel if rel.exists() else filepath))

    if problems:
        print("Bash 3.2 / BSD compatibility violations:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        print(
            f"\n{len(problems)} violation(s) found. "
            "See ARCHITECTURE.md 'Bash 3.2 / BSD sed constraints' for details.",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
