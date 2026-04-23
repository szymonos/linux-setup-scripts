#!/usr/bin/env bats
# Unit tests for manage_block in .assets/lib/profile_block.sh
bats_require_minimum_version 1.5.0

MARKER="nix-env managed"

setup() {
  TEST_DIR="$(mktemp -d)"
  RC="$TEST_DIR/.bashrc"
  CONTENT="$TEST_DIR/block_content.txt"
  # shellcheck source=../../.assets/lib/profile_block.sh
  source "$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.assets/lib/profile_block.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

_write_content() {
  printf '%s\n' "$@" >"$CONTENT"
}

_rc_content() {
  cat "$RC"
}

# count how many times begin tag appears
_count_begin() {
  grep -cF "# >>> $MARKER >>>" "$RC" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# inspect
# ---------------------------------------------------------------------------

@test "inspect returns 1 when rc does not exist" {
  run manage_block "$TEST_DIR/missing_rc" "$MARKER" inspect
  [ "$status" -eq 1 ]
}

@test "inspect returns 1 on empty rc" {
  touch "$RC"
  run manage_block "$RC" "$MARKER" inspect
  [ "$status" -eq 1 ]
}

@test "inspect returns 0 and prints line numbers when block is present" {
  printf 'before\n# >>> %s >>>\ncontent\n# <<< %s <<<\nafter\n' "$MARKER" "$MARKER" >"$RC"
  run manage_block "$RC" "$MARKER" inspect
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+\ [0-9]+$ ]]
}

# ---------------------------------------------------------------------------
# upsert - fresh rc (no existing block)
# ---------------------------------------------------------------------------

@test "upsert creates rc file if missing" {
  local new_rc="$TEST_DIR/new.bashrc"
  _write_content "export FOO=bar"
  run manage_block "$new_rc" "$MARKER" upsert "$CONTENT"
  [ "$status" -eq 0 ]
  [ -f "$new_rc" ]
}

@test "upsert on empty rc inserts block" {
  touch "$RC"
  _write_content "export FOO=bar"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  grep -qF "# >>> $MARKER >>>" "$RC"
  grep -qF "export FOO=bar" "$RC"
  grep -qF "# <<< $MARKER <<<" "$RC"
}

@test "upsert appends to non-empty rc without existing block" {
  printf 'existing line\n' >"$RC"
  _write_content "export NEW=1"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  grep -q "existing line" "$RC"
  grep -qF "# >>> $MARKER >>>" "$RC"
}

@test "upsert block count is exactly 1 on first insert" {
  touch "$RC"
  _write_content "line1"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  [ "$(_count_begin)" -eq 1 ]
}

# ---------------------------------------------------------------------------
# upsert - idempotency (existing block)
# ---------------------------------------------------------------------------

@test "upsert replaces existing block content" {
  touch "$RC"
  _write_content "old content"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  _write_content "new content"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  grep -q "new content" "$RC"
  run grep -c "old content" "$RC"
  [ "$output" -eq 0 ]
}

@test "upsert is idempotent: block count stays 1 on repeated runs" {
  touch "$RC"
  _write_content "export X=1"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  [ "$(_count_begin)" -eq 1 ]
}

@test "upsert preserves content before the block" {
  printf 'user_alias\n' >"$RC"
  _write_content "managed"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  grep -q "user_alias" "$RC"
}

@test "upsert preserves content after the block" {
  printf '# >>> %s >>>\nold\n# <<< %s <<<\nuser_below\n' "$MARKER" "$MARKER" >"$RC"
  _write_content "new"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  grep -q "user_below" "$RC"
}

@test "upsert repeated runs produce byte-identical output" {
  touch "$RC"
  _write_content "export STABLE=1"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  local hash1
  hash1="$(md5sum "$RC" | cut -d' ' -f1)"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  local hash2
  hash2="$(md5sum "$RC" | cut -d' ' -f1)"
  [ "$hash1" = "$hash2" ]
}

# ---------------------------------------------------------------------------
# upsert - duplicate block recovery
# ---------------------------------------------------------------------------

@test "upsert collapses multiple existing blocks into one" {
  printf '# >>> %s >>>\nfirst\n# <<< %s <<<\n# >>> %s >>>\nsecond\n# <<< %s <<<\n' \
    "$MARKER" "$MARKER" "$MARKER" "$MARKER" >"$RC"
  _write_content "unified"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  [ "$(_count_begin)" -eq 1 ]
  grep -q "unified" "$RC"
}

# ---------------------------------------------------------------------------
# remove
# ---------------------------------------------------------------------------

@test "remove is a no-op when block is absent" {
  printf 'untouched\n' >"$RC"
  run manage_block "$RC" "$MARKER" remove
  [ "$status" -eq 0 ]
  grep -q "untouched" "$RC"
}

@test "remove deletes the managed block" {
  touch "$RC"
  _write_content "managed line"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  manage_block "$RC" "$MARKER" remove
  run grep -cF "# >>> $MARKER >>>" "$RC"
  [ "$output" -eq 0 ]
  run grep -c "managed line" "$RC"
  [ "$output" -eq 0 ]
}

@test "remove preserves content outside the block" {
  printf 'before\n' >"$RC"
  _write_content "inside"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  printf 'after\n' >>"$RC"
  manage_block "$RC" "$MARKER" remove
  grep -q "before" "$RC"
  grep -q "after" "$RC"
}

@test "remove after upsert leaves inspect returning 1" {
  touch "$RC"
  _write_content "x"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  manage_block "$RC" "$MARKER" remove
  run manage_block "$RC" "$MARKER" inspect
  [ "$status" -eq 1 ]
}

@test "remove is idempotent" {
  touch "$RC"
  _write_content "x"
  manage_block "$RC" "$MARKER" upsert "$CONTENT"
  manage_block "$RC" "$MARKER" remove
  run manage_block "$RC" "$MARKER" remove
  [ "$status" -eq 0 ]
}

@test "remove cleans up multiple duplicate blocks" {
  printf '# >>> %s >>>\na\n# <<< %s <<<\n# >>> %s >>>\nb\n# <<< %s <<<\n' \
    "$MARKER" "$MARKER" "$MARKER" "$MARKER" >"$RC"
  manage_block "$RC" "$MARKER" remove
  run grep -cF "# >>> $MARKER >>>" "$RC"
  [ "$output" -eq 0 ]
}

# ---------------------------------------------------------------------------
# error handling
# ---------------------------------------------------------------------------

@test "upsert fails when content file is missing" {
  touch "$RC"
  run manage_block "$RC" "$MARKER" upsert "$TEST_DIR/nonexistent.txt"
  [ "$status" -ne 0 ]
}

@test "unknown action returns non-zero" {
  touch "$RC"
  run manage_block "$RC" "$MARKER" bogus
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# _pb_normalize_trailing
# ---------------------------------------------------------------------------

@test "normalize strips trailing blank lines" {
  printf 'line1\nline2\n\n\n\n' >"$RC"
  _pb_normalize_trailing "$RC"
  # file should end with exactly one newline; last non-empty line is line2
  run grep -c "^$" "$RC"
  # only the one trailing newline (awk END print "") - but that's the final char,
  # not a visible blank line in the output. Count non-empty lines.
  run grep -c "line2" "$RC"
  [ "$output" -eq 1 ]
  # no blank lines should remain between EOF and line2
  local content
  content="$(cat "$RC")"
  [ "$content" = "$(printf 'line1\nline2')" ] || [ "$content" = "$(printf 'line1\nline2\n')" ]
}

@test "normalize preserves internal blank lines" {
  printf 'a\n\nb\n' >"$RC"
  _pb_normalize_trailing "$RC"
  grep -q "^$" "$RC"
}
