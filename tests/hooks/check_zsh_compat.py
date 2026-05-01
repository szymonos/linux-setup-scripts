"""
Check shell scripts for zsh compatibility.

This hook is rule-driven and scope-agnostic: pre-commit-config.yaml decides
which files to feed in (`files:` regex), the hook applies all rules to
whatever it receives. Inline suppression: append `# zsh-ok` to a line.

Rules catch patterns that break or behave incorrectly under zsh:

- Bare function definitions (`name() {`) - zsh expands aliases during
  parsing, so `function name() {` is required to suppress expansion.
- Numeric array subscripts - zsh arrays are 1-based (bash is 0-based).
- For-loops over unquoted globs - zsh's `nomatch` option aborts the
  command on no-match instead of leaving the literal pattern; use
  `find ... | while IFS= read -r f` instead.
- Bash-only variables/builtins (BASH_SOURCE, compgen, COMP_WORDS, etc.)
  that must be inside a `[ -n "$BASH_VERSION" ]` guard.

Optionally runs `zsh -n` (syntax check) when zsh is available.

# :example
python3 -m tests.hooks.check_zsh_compat .assets/config/bash_cfg/aliases_git.sh
python3 -m tests.hooks.check_zsh_compat .assets/config/bash_cfg/functions.sh
"""

import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import NamedTuple

# ---------------------------------------------------------------------------
# Rules: each is (compiled regex, human description, guarded)
#   guarded=False  → always flag (code should be rewritten)
#   guarded=True   → skip when inside a BASH_VERSION guard block
# ---------------------------------------------------------------------------


class Rule(NamedTuple):
    pattern: re.Pattern[str]
    description: str
    guarded: bool = False


RULES: tuple[Rule, ...] = (
    # -- always flag (rewrite needed) ---------------------------------------
    Rule(
        re.compile(r"^\s*(?!function\s)[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{"),
        "bare function definition - use `function name() {` "
        "to prevent zsh alias expansion conflicts",
    ),
    Rule(
        re.compile(r"\$\{?[a-zA-Z_]\w*\[\s*[0-9]"),
        "numeric array subscript - zsh arrays are 1-based; "
        "avoid indexed arrays or guard with BASH_VERSION",
        guarded=True,
    ),
    Rule(
        re.compile(r"^\s*for\s+\w+\s+in\s+[^#\n]*\*"),
        "for-loop with unquoted glob - zsh's `nomatch` option aborts "
        "the command on no-match (`no matches found: ...`) instead of "
        'leaving the literal pattern for a `[ -f "$f" ]` guard. '
        "Use `find ... | while IFS= read -r f` instead",
    ),
    # -- guarded (need BASH_VERSION check) ----------------------------------
    Rule(
        re.compile(r"\bBASH_SOURCE\b"),
        "BASH_SOURCE does not exist in zsh - "
        'guard with [ -n "$BASH_VERSION" ] or add fallback',
        guarded=True,
    ),
    Rule(
        re.compile(r"\bBASH_REMATCH\b"),
        "BASH_REMATCH does not exist in zsh (use $match) - "
        'guard with [ -n "$BASH_VERSION" ]',
        guarded=True,
    ),
    Rule(
        re.compile(r"\bcompgen\b"),
        'compgen is a bash-only builtin - guard with [ -n "$BASH_VERSION" ]',
        guarded=True,
    ),
    Rule(
        re.compile(r"\bcomplete\s+-[FW]"),
        'complete is a bash-only builtin - guard with [ -n "$BASH_VERSION" ]',
        guarded=True,
    ),
    Rule(
        re.compile(r"\b(COMP_WORDS|COMP_CWORD|COMPREPLY)\b"),
        'bash-only completion variable - guard with [ -n "$BASH_VERSION" ]',
        guarded=True,
    ),
)

# ---------------------------------------------------------------------------
# Guard detection patterns
# ---------------------------------------------------------------------------
_RE_IF = re.compile(r"^\s*(if|elif)\b")
_RE_IF_BASH = re.compile(r"BASH_VERSION")
_RE_FI = re.compile(r"^\s*fi\b")


def check_file(filepath: Path) -> list[str]:
    """Check a single file for zsh compatibility violations."""
    problems: list[str] = []
    try:
        lines = filepath.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return problems

    in_colon_heredoc = False
    if_nesting = 0
    bash_guard_depth = 0

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

        # skip comments and lines with inline suppression
        if stripped.startswith("#"):
            continue
        if "# zsh-ok" in line:
            continue

        # track if/fi nesting for BASH_VERSION guard detection
        if _RE_IF.match(stripped):
            if_nesting += 1
            if _RE_IF_BASH.search(stripped):
                bash_guard_depth = if_nesting
        elif _RE_FI.match(stripped):
            if if_nesting == bash_guard_depth:
                bash_guard_depth = 0
            if_nesting -= 1

        in_guard = bash_guard_depth > 0

        for rule in RULES:
            if rule.guarded and in_guard:
                continue
            if rule.pattern.search(line):
                rel = filepath.as_posix()
                problems.append(f"{rel}:{lineno}: {rule.description}")
    return problems


def _zsh_syntax_check(filepath: Path) -> list[str]:
    """Run zsh -n syntax check on a file. Returns problems or empty list."""
    try:
        result = subprocess.run(
            ["zsh", "-n", str(filepath)],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode != 0:
            rel = filepath.as_posix()
            return [f"{rel}: zsh -n: {result.stderr.strip()}"]
    except (FileNotFoundError, subprocess.TimeoutExpired):  # fmt: skip
        pass
    return []


def main(argv: list[str]) -> int:
    if not argv:
        return 0

    repo_root = Path(__file__).resolve().parents[2]
    targets = [Path(f).resolve() for f in argv if Path(f).is_file()]
    if not targets:
        return 0

    problems: list[str] = []
    has_zsh = shutil.which("zsh") is not None

    for filepath in targets:
        # make paths relative for readable output
        try:
            rel = filepath.relative_to(repo_root)
        except ValueError:
            rel = filepath
        check_path = rel if rel.exists() else filepath
        problems.extend(check_file(check_path))
        if has_zsh:
            problems.extend(_zsh_syntax_check(check_path))

    if problems:
        print("Zsh compatibility violations:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        print(
            f"\n{len(problems)} violation(s) found.",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
