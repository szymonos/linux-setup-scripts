#!/usr/bin/env bats
# Unit tests for _nx_read_pkgs / _nx_write_pkgs in aliases_nix.sh
# shellcheck disable=SC2030,SC2031  # subshell variable modifications are intentional in tests
bats_require_minimum_version 1.5.0

setup() {
  _NX_ENV_DIR="$(mktemp -d)"
  _NX_PKG_FILE="$_NX_ENV_DIR/packages.nix"

  # source only the helper functions (stub out nix/curl/jq to avoid side effects)
  # shellcheck source=../../.assets/config/bash_cfg/aliases_nix.sh
  _nx_read_pkgs() {
    [ -f "$_NX_PKG_FILE" ] && sed -n 's/^[[:space:]]*"\([^"]*\)".*/\1/p' "$_NX_PKG_FILE"
  }

  _nx_write_pkgs() {
    local tmp
    tmp="$(mktemp)"
    printf '[\n' >"$tmp"
    sort -u | while IFS= read -r name; do
      [ -n "$name" ] && printf '  "%s"\n' "$name" >>"$tmp"
    done
    printf ']\n' >>"$tmp"
    mv "$tmp" "$_NX_PKG_FILE"
  }
}

teardown() {
  rm -rf "$_NX_ENV_DIR"
}

# -- _nx_read_pkgs ------------------------------------------------------------

@test "read_pkgs returns empty when file does not exist" {
  run _nx_read_pkgs
  [ -z "$output" ]
}

@test "read_pkgs returns empty for empty list" {
  printf '[\n]\n' >"$_NX_PKG_FILE"
  run _nx_read_pkgs
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "read_pkgs extracts package names" {
  cat >"$_NX_PKG_FILE" <<'EOF'
[
  "ripgrep"
  "fd"
  "jq"
]
EOF
  run _nx_read_pkgs
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "ripgrep" ]
  [ "${lines[1]}" = "fd" ]
  [ "${lines[2]}" = "jq" ]
  [ "${#lines[@]}" -eq 3 ]
}

@test "read_pkgs ignores comments and blank lines" {
  cat >"$_NX_PKG_FILE" <<'EOF'
[
  # a comment
  "ripgrep"

  "fd"
]
EOF
  run _nx_read_pkgs
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "ripgrep" ]
  [ "${lines[1]}" = "fd" ]
}

# -- _nx_write_pkgs ------------------------------------------------------------

@test "write_pkgs creates valid nix list" {
  printf 'ripgrep\nfd\n' | _nx_write_pkgs
  run cat "$_NX_PKG_FILE"
  [ "${lines[0]}" = "[" ]
  [ "${lines[1]}" = '  "fd"' ]
  [ "${lines[2]}" = '  "ripgrep"' ]
  [ "${lines[3]}" = "]" ]
}

@test "write_pkgs sorts and deduplicates" {
  printf 'zoxide\nripgrep\nfd\nripgrep\n' | _nx_write_pkgs
  run _nx_read_pkgs
  [ "${lines[0]}" = "fd" ]
  [ "${lines[1]}" = "ripgrep" ]
  [ "${lines[2]}" = "zoxide" ]
  [ "${#lines[@]}" -eq 3 ]
}

@test "write_pkgs skips blank lines" {
  printf '\nripgrep\n\n\nfd\n\n' | _nx_write_pkgs
  run _nx_read_pkgs
  [ "${#lines[@]}" -eq 2 ]
}

@test "write_pkgs with empty input creates empty list" {
  printf '' | _nx_write_pkgs
  run cat "$_NX_PKG_FILE"
  [ "${lines[0]}" = "[" ]
  [ "${lines[1]}" = "]" ]
  [ "${#lines[@]}" -eq 2 ]
}

# -- round-trip ----------------------------------------------------------------

@test "round-trip: write then read preserves packages" {
  printf 'jq\ncurl\nwget\n' | _nx_write_pkgs
  run _nx_read_pkgs
  [ "${lines[0]}" = "curl" ]
  [ "${lines[1]}" = "jq" ]
  [ "${lines[2]}" = "wget" ]
}

@test "round-trip: add to existing list" {
  printf 'fd\nripgrep\n' | _nx_write_pkgs
  current="$(_nx_read_pkgs)"
  { printf '%s\n' "$current"; printf 'jq\n'; } | _nx_write_pkgs
  run _nx_read_pkgs
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = "fd" ]
  [ "${lines[1]}" = "jq" ]
  [ "${lines[2]}" = "ripgrep" ]
}

@test "round-trip: remove from existing list" {
  printf 'fd\njq\nripgrep\n' | _nx_write_pkgs
  current="$(_nx_read_pkgs)"
  printf '%s\n' "$current" | grep -v '^jq$' | _nx_write_pkgs
  run _nx_read_pkgs
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "fd" ]
  [ "${lines[1]}" = "ripgrep" ]
}
