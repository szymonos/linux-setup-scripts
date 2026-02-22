"""
Scan staged text files for unwanted Unicode characters and fail if found.

# :example
python3 -m tests.hooks.gremlins wsl/wsl_setup.ps1
"""

import os
import sys
import unicodedata
from collections.abc import Iterable
from typing import Tuple

FORBIDDEN_CHARS: Tuple[str, ...] = (
    # Zero-width / joiner
    "\u200b",  # U+200B ZERO WIDTH SPACE
    "\u200c",  # U+200C ZERO WIDTH NON-JOINER
    "\u200d",  # U+200D ZERO WIDTH JOINER
    # Spaces / breaks
    "\u00a0",  # U+00A0 NO-BREAK SPACE
    "\u202f",  # U+202F NARROW NO-BREAK SPACE
    "\u2009",  # U+2009 THIN SPACE
    "\u200a",  # U+200A HAIR SPACE
    # Control / formatting
    "\u000c",  # U+000C FORM FEED
    "\u00ad",  # U+00AD SOFT HYPHEN
    # Dashes / hyphens
    "\u2013",  # U+2013 EN DASH
    "\u2014",  # U+2014 EM DASH
    "\u2010",  # U+2010 HYPHEN
    # Quotes / punctuation that look like ASCII
    "\u2018",  # U+2018 LEFT SINGLE QUOTATION MARK
    "\u2019",  # U+2019 RIGHT SINGLE QUOTATION MARK
    "\u201c",  # U+201C LEFT DOUBLE QUOTATION MARK
    "\u201d",  # U+201D RIGHT DOUBLE QUOTATION MARK
    "\u2026",  # U+2026 HORIZONTAL ELLIPSIS
    # Misc common problematic characters
    "\u00b7",  # U+00B7 MIDDLE DOT
)


def find_forbidden_in_text(content: str, filename: str) -> list[str]:
    """
    Scan the given text for forbidden Unicode characters and report their locations.

    Parameters
    ----------
    content : str
        The text content to scan for forbidden characters.
    filename : str
        The name of the file being scanned, used in the report output.

    Returns
    -------
    list[str]
        A list of human-readable report strings. Each string is formatted as:
        "filename:lineno: contains <Unicode name> (<Unicode codepoint>)"
        For example: "example.py:10: contains ZERO WIDTH SPACE (U+200B)"
    """
    reports: list[str] = []
    for lineno, line in enumerate(content.splitlines(), start=1):
        for ch in FORBIDDEN_CHARS:
            if ch in line:
                code = f"U+{ord(ch):04X}"
                try:
                    name = unicodedata.name(ch)
                except ValueError:
                    name = "<unknown>"
                reports.append(f"{filename}:{lineno}: contains {name} ({code})")
    return reports


def is_text_file(path: str) -> bool:
    """Quick heuristic to skip binary files."""
    try:
        with open(path, "rb") as fh:
            chunk = fh.read(4096)
            # if NUL bytes present it's likely binary
            return b"\x00" not in chunk
    except OSError:
        return False


def check_gremlins(argv: Iterable[str]) -> int:
    """
    Check a list of text files for forbidden Unicode characters.

    Args:
        argv (Iterable[str]): An iterable of file path strings to check.

    Returns:
        int: Returns 0 if no forbidden characters are found in any file,
        or 1 if at least one forbidden character is found.
    """
    files = list(argv)
    problems: list[str] = []
    for path in files:
        if not os.path.exists(path) or not is_text_file(path):
            continue
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as fh:
                content = fh.read()
        except OSError:
            continue
        problems.extend(find_forbidden_in_text(content, path))

    if problems:
        print("Gremlin characters found:", file=sys.stderr)
        for p in problems:
            print(p, file=sys.stderr)
        print("Remove or replace gremlin characters", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(check_gremlins(sys.argv[1:]))
