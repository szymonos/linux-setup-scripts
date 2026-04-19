"""
Run bats tests for changed files.

Scans tests/bats/*.bats for `source` directives to build a mapping of which
source files are covered by which test files. When any covered source file
(or a .bats file itself) is staged, runs the relevant tests.

# :example
python3 -m tests.hooks.run_bats
# :run with explicit file list (as pre-commit passes them)
python3 -m tests.hooks.run_bats .assets/lib/scopes.sh tests/bats/test_scopes.bats
"""

import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
BATS_DIR = REPO_ROOT / "tests" / "bats"


def build_source_map() -> dict[str, list[Path]]:
    """Parse .bats files and return {relative_source_path: [bats_files]}."""
    source_to_tests: dict[str, list[Path]] = {}

    if not BATS_DIR.is_dir():
        return source_to_tests

    # match: source "path" or source 'path' with optional $BATS_TEST_DIRNAME/ prefix
    source_re = re.compile(
        r'^\s*source\s+["\']'
        r"(?:\$BATS_TEST_DIRNAME/)?"
        r'(.+?)["\']',
    )

    for bats_file in sorted(BATS_DIR.glob("*.bats")):
        bats_rel = bats_file.relative_to(REPO_ROOT).as_posix()

        # the .bats file itself is always in scope
        source_to_tests.setdefault(bats_rel, []).append(bats_file)

        for line in bats_file.read_text().splitlines():
            m = source_re.match(line)
            if not m:
                continue

            raw_path = m.group(1)
            # resolve relative to the bats file directory
            resolved = (BATS_DIR / raw_path).resolve()
            try:
                rel = resolved.relative_to(REPO_ROOT).as_posix()
            except ValueError:
                continue

            source_to_tests.setdefault(rel, []).append(bats_file)

            # also watch the sibling .json if the source is scopes.sh
            if rel.endswith("scopes.sh"):
                json_rel = rel.replace("scopes.sh", "scopes.json")
                source_to_tests.setdefault(json_rel, []).append(bats_file)

    return source_to_tests


def main(argv: list[str] | None = None) -> int:
    if not shutil.which("bats"):
        print("bats not found, skipping tests", file=sys.stderr)
        return 0

    # files passed by pre-commit (or CLI)
    changed_files = set(argv or [])

    source_map = build_source_map()
    if not source_map:
        return 0

    # collect bats files to run
    to_run: set[Path] = set()
    for changed in changed_files:
        # normalize to posix-style relative path
        normalized = Path(changed).as_posix()
        if normalized in source_map:
            to_run.update(source_map[normalized])

    if not to_run:
        return 0

    cmd = ["bats"] + sorted(str(f) for f in to_run)
    result = subprocess.run(cmd)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
