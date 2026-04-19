"""
Scan staged text files for unwanted Unicode characters.

Auto-fixes characters with obvious ASCII replacements (dashes, smart quotes,
fancy spaces, etc.) and reports any remaining unfixable gremlins.

When auto-fixes are applied the hook prints what changed and exits 0;
pre-commit detects the modified file and blocks the commit so the user
can review, re-stage, and commit again.

# :example
python3 -m tests.hooks.gremlins wsl/wsl_setup.ps1
"""

import os
import sys
import unicodedata
from collections.abc import Iterable

# Characters with a clear ASCII replacement -- auto-fixed in place.
AUTO_FIX: dict[str, str] = {
    # Dashes / hyphens -> ASCII hyphen-minus
    "\u2010": "-",  # HYPHEN
    "\u2013": "-",  # EN DASH
    "\u2014": "-",  # EM DASH
    # Fancy spaces -> regular space
    "\u00a0": " ",  # NO-BREAK SPACE
    "\u202f": " ",  # NARROW NO-BREAK SPACE
    "\u2009": " ",  # THIN SPACE
    "\u200a": " ",  # HAIR SPACE
    # Smart quotes -> ASCII quotes
    "\u2018": "'",  # LEFT SINGLE QUOTATION MARK
    "\u2019": "'",  # RIGHT SINGLE QUOTATION MARK
    "\u201c": '"',  # LEFT DOUBLE QUOTATION MARK
    "\u201d": '"',  # RIGHT DOUBLE QUOTATION MARK
    # Ellipsis -> three dots
    "\u2026": "...",  # HORIZONTAL ELLIPSIS
    # Invisible / zero-width -> remove
    "\u200b": "",  # ZERO WIDTH SPACE
    "\u200c": "",  # ZERO WIDTH NON-JOINER
    "\u200d": "",  # ZERO WIDTH JOINER
    "\u00ad": "",  # SOFT HYPHEN
    "\u000c": "",  # FORM FEED
}

# Characters that cannot be auto-fixed -- always reported for manual review.
REPORT_ONLY: tuple[str, ...] = (
    "\u00b7",  # MIDDLE DOT
)

ALL_FORBIDDEN = set(AUTO_FIX) | set(REPORT_ONLY)


def _char_label(ch: str) -> str:
    code = f"U+{ord(ch):04X}"
    try:
        name = unicodedata.name(ch)
    except ValueError:
        name = "<unknown>"
    return f"{name} ({code})"


def is_text_file(path: str) -> bool:
    """Quick heuristic to skip binary files."""
    try:
        with open(path, "rb") as fh:
            chunk = fh.read(4096)
            return b"\x00" not in chunk
    except OSError:
        return False


def fix_and_report(path: str) -> tuple[list[str], list[str]]:
    """Auto-fix what we can, report what we cannot.

    Returns (fixed_reports, unfixable_reports).
    """
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except OSError:
        return [], []

    fixed_chars: set[str] = set()
    new_content = content
    for ch, replacement in AUTO_FIX.items():
        if ch in new_content:
            fixed_chars.add(ch)
            new_content = new_content.replace(ch, replacement)

    if fixed_chars:
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(new_content)

    fixed_reports = []
    if fixed_chars:
        labels = ", ".join(sorted(_char_label(ch) for ch in fixed_chars))
        fixed_reports.append(f"{path}: fixed {labels}")

    unfixable_reports = []
    for lineno, line in enumerate(new_content.splitlines(), start=1):
        for ch in REPORT_ONLY:
            if ch in line:
                unfixable_reports.append(f"{path}:{lineno}: contains {_char_label(ch)}")

    return fixed_reports, unfixable_reports


def check_gremlins(argv: Iterable[str]) -> int:
    files = list(argv)
    all_fixed: list[str] = []
    all_unfixable: list[str] = []

    for path in files:
        if not os.path.exists(path) or not is_text_file(path):
            continue
        fixed, unfixable = fix_and_report(path)
        all_fixed.extend(fixed)
        all_unfixable.extend(unfixable)

    if all_fixed:
        print("Gremlin characters auto-fixed:", file=sys.stderr)
        for r in all_fixed:
            print(f"  {r}", file=sys.stderr)

    if all_unfixable:
        print("Gremlin characters found (manual fix required):", file=sys.stderr)
        for r in all_unfixable:
            print(f"  {r}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(check_gremlins(sys.argv[1:]))
