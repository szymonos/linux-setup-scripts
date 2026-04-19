#!/usr/bin/env python3
"""
Auto-align markdown table columns.

Ensures all pipe characters in each table are at the same
column position across all rows (MD060 compliance).

Usage:
    python3 -m tests.hooks.align_tables docs/*.md
"""

import sys
import unicodedata


def _display_width(text: str) -> int:
    """Return the monospace display width of *text*.

    Wide characters (most emoji, CJK) count as 2 columns.
    Zero-width characters (combining marks, variation selectors, ZWJ) count as 0.
    A base character followed by VS16 (U+FE0F) is forced to width 2 (emoji presentation).
    """
    width = 0
    chars = list(text)
    for i, ch in enumerate(chars):
        cat = unicodedata.category(ch)
        # zero-width: combining marks (Mn/Mc/Me), format chars (Cf) like ZWJ/VS16
        if cat.startswith("M") or cat == "Cf":
            continue
        # check if next char is VS16 (emoji presentation selector)
        has_vs16 = i + 1 < len(chars) and chars[i + 1] == "\ufe0f"
        eaw = unicodedata.east_asian_width(ch)
        if eaw in ("W", "F") or has_vs16:
            width += 2
        else:
            width += 1
    return width


def _pad(text: str, target_width: int) -> str:
    """Pad *text* with spaces so its display width equals *target_width*."""
    return text + " " * (target_width - _display_width(text))


def align_table(lines):
    """Align all pipes in a markdown table."""
    rows = []
    for line in lines:
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)

    if len(rows) < 2:
        return lines

    num_cols = len(rows[0])

    # Find max display width per column (skip separator row)
    widths = [0] * num_cols
    for i, row in enumerate(rows):
        if i == 1:
            continue
        for j, cell in enumerate(row):
            if j < num_cols:
                widths[j] = max(widths[j], _display_width(cell))

    # Rebuild rows with aligned pipes
    result = []
    for i, row in enumerate(rows):
        if i == 1:
            parts = ["| " + "-" * widths[j] + " " for j in range(num_cols)]
        else:
            parts = [
                "| " + _pad(row[j] if j < len(row) else "", widths[j]) + " "
                for j in range(num_cols)
            ]
        result.append("".join(parts) + "|")
    return result


def process_file(path):
    """Process a single markdown file. Return True if changes were made."""
    with open(path) as f:
        original = f.read()

    lines = original.splitlines()
    result = []
    table_buf = []
    in_table = False
    in_code_block = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_code_block = not in_code_block
        is_table = (
            not in_code_block and stripped.startswith("|") and "|" in stripped[1:]
        )
        if is_table:
            table_buf.append(line)
            in_table = True
        else:
            if in_table:
                result.extend(align_table(table_buf))
                table_buf = []
                in_table = False
            result.append(line)

    if table_buf:
        result.extend(align_table(table_buf))

    new_content = "\n".join(result) + "\n"
    if new_content != original:
        with open(path, "w") as f:
            f.write(new_content)
        return True
    return False


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file.md> [file2.md ...]")
        sys.exit(1)

    for path in sys.argv[1:]:
        if process_file(path):
            print(f"Aligned: {path}")
        else:
            print(f"OK: {path}")
