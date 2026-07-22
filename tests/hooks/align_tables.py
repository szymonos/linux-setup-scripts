"""
Auto-align markdown table columns.

Ensures all pipe characters in each table are at the same
column position across all rows (MD060 compliance).

# :example
uv run --frozen python -m tests.hooks.align_tables docs/*.md
"""

import re
import sys
import unicodedata


def _display_width(text: str) -> int:
    """
    Return the monospace display width of *text*.

    Wide characters (most emoji, CJK) count as 2 columns.
    Zero-width characters (combining marks, variation selectors, ZWJ) count as 0.
    A base character followed by VS16 (U+FE0F) is forced to width 2
    (emoji presentation).
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


_ESCAPED_PIPE_SENTINEL = "\x00"
_WIKILINK_PIPE_SENTINEL = "\x01"
_WIKILINK_RE = re.compile(r"\[\[([^\[\]]+?)\]\]")


def _mask_wikilink_pipes(text: str) -> str:
    """Replace '|' inside [[...]] with a sentinel so it survives the table-row split."""
    return _WIKILINK_RE.sub(
        lambda m: "[[" + m.group(1).replace("|", _WIKILINK_PIPE_SENTINEL) + "]]",
        text,
    )


def _split_cells(line: str) -> list[str]:
    r"""
    Split a markdown table row on '|', preserving wikilink and escape pipes.

    Two forms are treated as literal pipes (not column separators):
      - '\|'      - the standard markdown escape for a literal pipe
      - '|' inside an Obsidian wikilink '[[target|display]]'

    Both forms appear in this repo: display-text wikilinks in table cells (e.g.
    '[[01 Primer|Primer]]') would otherwise be chopped in half. The '\|' escape
    still works for symmetry and for non-wikilink literal pipes.
    """
    body = line.strip().strip("|").replace(r"\|", _ESCAPED_PIPE_SENTINEL)
    body = _mask_wikilink_pipes(body)
    return [
        c.strip()
        .replace(_WIKILINK_PIPE_SENTINEL, "|")
        .replace(_ESCAPED_PIPE_SENTINEL, r"\|")
        for c in body.split("|")
    ]


_SEPARATOR_CELL_RE = re.compile(r"^:?-+:?$")


def _is_separator_row(cells: list[str]) -> bool:
    """Return True if every cell is a markdown separator cell (`:?-+:?`)."""
    return bool(cells) and all(
        _SEPARATOR_CELL_RE.fullmatch(cell.strip()) for cell in cells
    )


def _alignment_marker(cell: str) -> tuple[bool, bool]:
    """Return (left, right) colon alignment flags from a separator cell."""
    cell = cell.strip()
    return cell.startswith(":"), cell.endswith(":")


def _separator_cell(width: int, left: bool, right: bool) -> str:
    """Build a separator cell preserving alignment colons, min 1 dash."""
    # GFM requires at least one hyphen in a delimiter cell (colons don't count).
    # Reserve room for any alignment colons, then fill the rest with dashes.
    dashes = max(1, width - int(left) - int(right))
    return (":" if left else "") + "-" * dashes + (":" if right else "")


def align_table(lines: list[str]) -> list[str]:
    """Align all pipes in a markdown table."""
    rows = []
    for line in lines:
        rows.append(_split_cells(line))

    if len(rows) < 2:
        return lines

    # Preserve the leading indentation of the first row (tables nested in list
    # items are indented); emitting bare "| ..." rows would de-indent them and
    # change how the table renders.
    first = lines[0]
    indent = first[: len(first) - len(first.lstrip())]

    # Only treat this block as a table if row 2 is a real separator row. Two
    # consecutive pipe-prefixed lines that aren't a table (or a table missing
    # its separator) would otherwise get a data row rewritten into dashes.
    if not _is_separator_row(rows[1]):
        return lines

    num_cols = max(len(row) for row in rows)

    # capture per-column alignment markers from the separator row before padding
    sep_row = rows[1]
    markers = [
        _alignment_marker(sep_row[j]) if j < len(sep_row) else (False, False)
        for j in range(num_cols)
    ]

    # Find max display width per column (skip separator row)
    widths = [0] * num_cols
    for i, row in enumerate(rows):
        if i == 1:
            continue
        for j, cell in enumerate(row):
            widths[j] = max(widths[j], _display_width(cell))

    # The separator cell needs at least one dash plus room for any alignment
    # colons. If a column's widest data cell is narrower than that, the
    # separator row would render wider than the data cells and knock the pipes
    # out of alignment (MD060). Raise each column to its separator minimum.
    for j in range(num_cols):
        left, right = markers[j]
        widths[j] = max(widths[j], 1 + int(left) + int(right))

    # Rebuild rows with aligned pipes
    result = []
    for i, row in enumerate(rows):
        if i == 1:
            parts = [
                "| " + _separator_cell(widths[j], *markers[j]) + " "
                for j in range(num_cols)
            ]
        else:
            parts = [
                "| " + _pad(row[j] if j < len(row) else "", widths[j]) + " "
                for j in range(num_cols)
            ]
        result.append(indent + "".join(parts) + "|")
    return result


def process_file(path: str) -> bool:
    """Process a single markdown file. Return True if changes were made."""
    try:
        with open(path, encoding="utf-8") as f:
            original = f.read()
    except (OSError, UnicodeDecodeError) as e:
        print(f"align-tables: cannot read {path}: {e}", file=sys.stderr)
        raise SystemExit(1) from e

    lines = original.splitlines()
    result = []
    table_buf = []
    in_table = False
    in_code_block = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith(("```", "~~~")):
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
        try:
            with open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write(new_content)
        except OSError as e:
            print(f"align-tables: cannot write {path}: {e}", file=sys.stderr)
            raise SystemExit(1) from e
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
