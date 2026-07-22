"""
Scan staged text files for unwanted Unicode characters.

Auto-fixes characters with obvious ASCII replacements (dashes, smart quotes,
fancy spaces, etc.).

Markup files (.md, .html, .htm) get a relaxed pass: EM DASH, NO-BREAK SPACE,
HORIZONTAL ELLIPSIS, and MIDDLE DOT are allowed there because they serve
legitimate typographic purposes. Everything else with a safe ASCII
replacement (smart quotes, EN DASH, most zero-width/invisible chars, etc.) is
still auto-fixed. Bidirectional control characters (LRM/RLM, embeddings,
overrides, isolates) have no safe replacement and are reported as unfixable -
the hook exits non-zero so they get manual attention. The gremlins VSCode
extension handles visual reporting for the allowed chars.

When auto-fixes are applied the hook prints what changed and exits 0;
pre-commit detects the modified file and blocks the commit so the user
can review, re-stage, and commit again.

# :example
uv run --frozen python -m tests.hooks.gremlins docs/*.md
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
    # Miscellaneous
    "\u00b7": "-",  # MIDDLE DOT
    # BOM
    "\ufeff": "",  # BYTE ORDER MARK (UTF-8 BOM)
}

# Characters that should be flagged but have no safe auto-replacement.
UNFIXABLE: frozenset[str] = frozenset(
    {
        "\u200e",  # LEFT-TO-RIGHT MARK
        "\u200f",  # RIGHT-TO-LEFT MARK
        "\u202a",  # LEFT-TO-RIGHT EMBEDDING
        "\u202b",  # RIGHT-TO-LEFT EMBEDDING
        "\u202c",  # POP DIRECTIONAL FORMATTING
        "\u202d",  # LEFT-TO-RIGHT OVERRIDE
        "\u202e",  # RIGHT-TO-LEFT OVERRIDE
        "\u2066",  # LEFT-TO-RIGHT ISOLATE
        "\u2067",  # RIGHT-TO-LEFT ISOLATE
        "\u2068",  # FIRST STRONG ISOLATE
        "\u2069",  # POP DIRECTIONAL ISOLATE
    }
)

ALL_FORBIDDEN: frozenset[str] = frozenset(AUTO_FIX) | UNFIXABLE

# Markup files allow a small set of typographic chars that are intentional.
# Everything NOT in this set is still auto-fixed.
MARKUP_EXTENSIONS = frozenset((".md", ".html", ".htm"))
MARKUP_ALLOW = frozenset(
    {
        "\u2014",  # EM DASH
        "\u00a0",  # NO-BREAK SPACE
        "\u2026",  # HORIZONTAL ELLIPSIS
        "\u00b7",  # MIDDLE DOT
    }
)


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


def _is_markup(path: str) -> bool:
    _, ext = os.path.splitext(path)
    return ext.lower() in MARKUP_EXTENSIONS


def fix_and_report(path: str) -> tuple[list[str], list[str]]:
    """Auto-fix gremlins in a file. Returns (fixes, errors)."""
    try:
        # surrogateescape (not replace) so invalid UTF-8 bytes round-trip on the
        # in-place write below instead of being flattened to U+FFFD and lost.
        with open(path, encoding="utf-8", errors="surrogateescape") as fh:
            content = fh.read()
    except OSError:
        return [], []

    if not (ALL_FORBIDDEN & set(content)):
        return [], []

    markup = _is_markup(path)

    fixed_chars: set[str] = set()
    new_content = content
    for ch, replacement in AUTO_FIX.items():
        if markup and ch in MARKUP_ALLOW:
            continue
        if ch in new_content:
            fixed_chars.add(ch)
            new_content = new_content.replace(ch, replacement)

    fixes: list[str] = []
    if fixed_chars:
        try:
            with open(
                path, "w", encoding="utf-8", errors="surrogateescape", newline="\n"
            ) as fh:
                fh.write(new_content)
        except OSError as e:
            print(f"gremlins: cannot write {path}: {e}", file=sys.stderr)
            raise SystemExit(1) from e
        labels = ", ".join(sorted(_char_label(ch) for ch in fixed_chars))
        fixes.append(f"{path}: fixed {labels}")

    errors: list[str] = []
    found_unfixable = UNFIXABLE & set(new_content)
    if found_unfixable:
        # Report each occurrence with its 1-based line/column so the offending
        # character can be located for manual cleanup, grouped under the file.
        for line_no, line in enumerate(new_content.splitlines(), start=1):
            for col, ch in enumerate(line, start=1):
                if ch in found_unfixable:
                    errors.append(
                        f"{path}:{line_no}:{col}: unfixable {_char_label(ch)}"
                    )

    return fixes, errors


def check_gremlins(argv: Iterable[str]) -> int:
    """Scan files for invisible/gremlin characters and auto-fix them."""
    all_fixed: list[str] = []
    all_errors: list[str] = []

    for path in argv:
        if not os.path.exists(path) or not is_text_file(path):
            continue
        fixes, errors = fix_and_report(path)
        all_fixed.extend(fixes)
        all_errors.extend(errors)

    if all_fixed:
        print("Gremlin characters auto-fixed:", file=sys.stderr)
        for r in all_fixed:
            print(f"  {r}", file=sys.stderr)

    if all_errors:
        print("Unfixable gremlin characters found:", file=sys.stderr)
        for r in all_errors:
            print(f"  {r}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(check_gremlins(sys.argv[1:]))
