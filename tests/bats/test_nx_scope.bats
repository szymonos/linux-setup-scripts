#!/usr/bin/env bats
# Unit tests for nx scope helpers and scope-aware install/remove validation
# Tests: _nx_scope_pkgs, _nx_scopes, _nx_is_init, _nx_all_scope_pkgs,
#        install scope-check, remove scope-check
# shellcheck disable=SC2030,SC2031
bats_require_minimum_version 1.5.0

setup() {
  _NX_ENV_DIR="$(mktemp -d)"
  _NX_PKG_FILE="$_NX_ENV_DIR/packages.nix"
  mkdir -p "$_NX_ENV_DIR/scopes"

  # source helpers inline (same as aliases_nix.sh) to avoid side effects
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

  _nx_scope_pkgs() {
    local file="$1"
    [ -f "$file" ] || return 0
    sed -n '/\[/,/\]/{
      s/^[[:space:]]*\([a-zA-Z][a-zA-Z0-9_-]*\).*/\1/p
    }' "$file"
  }

  _nx_scopes() {
    local config_nix="$_NX_ENV_DIR/config.nix"
    [ -f "$config_nix" ] || return 0
    sed -n '/scopes[[:space:]]*=[[:space:]]*\[/,/\]/{
      s/^[[:space:]]*"\([^"]*\)".*/\1/p
    }' "$config_nix"
  }

  _nx_is_init() {
    local config_nix="$_NX_ENV_DIR/config.nix"
    [ -f "$config_nix" ] || { echo "false"; return; }
    sed -n -E 's/^[[:space:]]*isInit[[:space:]]*=[[:space:]]*(true|false).*/\1/p' "$config_nix"
  }

  _nx_all_scope_pkgs() {
    local scopes_dir="$_NX_ENV_DIR/scopes"
    [ -d "$scopes_dir" ] || return 0
    local pkg
    while IFS= read -r pkg; do
      [ -n "$pkg" ] && printf '%s\t%s\n' "$pkg" "base"
    done < <(_nx_scope_pkgs "$scopes_dir/base.nix")
    if [ "$(_nx_is_init)" = "true" ]; then
      while IFS= read -r pkg; do
        [ -n "$pkg" ] && printf '%s\t%s\n' "$pkg" "base_init"
      done < <(_nx_scope_pkgs "$scopes_dir/base_init.nix")
    fi
    local scopes s
    scopes="$(_nx_scopes)"
    if [ -n "$scopes" ]; then
      while IFS= read -r s; do
        while IFS= read -r pkg; do
          [ -n "$pkg" ] && printf '%s\t%s\n' "$pkg" "$s"
        done < <(_nx_scope_pkgs "$scopes_dir/$s.nix")
      done <<<"$scopes"
    fi
  }
}

teardown() {
  rm -rf "$_NX_ENV_DIR"
}

# =============================================================================
# _nx_scope_pkgs
# =============================================================================

@test "scope_pkgs: parses standard scope file" {
  cat >"$_NX_ENV_DIR/scopes/shell.nix" <<'EOF'
# Shell tools
{ pkgs }: with pkgs; [
  fzf
  eza
  bat
  ripgrep
]
EOF
  run _nx_scope_pkgs "$_NX_ENV_DIR/scopes/shell.nix"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "fzf" ]
  [ "${lines[1]}" = "eza" ]
  [ "${lines[2]}" = "bat" ]
  [ "${lines[3]}" = "ripgrep" ]
  [ "${#lines[@]}" -eq 4 ]
}

@test "scope_pkgs: handles inline comments" {
  cat >"$_NX_ENV_DIR/scopes/test.nix" <<'EOF'
{ pkgs }: with pkgs; [
  bind          # provides dig, nslookup, host
  git
  openssl
]
EOF
  run _nx_scope_pkgs "$_NX_ENV_DIR/scopes/test.nix"
  [ "${lines[0]}" = "bind" ]
  [ "${lines[1]}" = "git" ]
  [ "${lines[2]}" = "openssl" ]
  [ "${#lines[@]}" -eq 3 ]
}

@test "scope_pkgs: handles packages with hyphens and underscores" {
  cat >"$_NX_ENV_DIR/scopes/test.nix" <<'EOF'
{ pkgs }: with pkgs; [
  bash-completion
  yq-go
  k9s
]
EOF
  run _nx_scope_pkgs "$_NX_ENV_DIR/scopes/test.nix"
  [ "${lines[0]}" = "bash-completion" ]
  [ "${lines[1]}" = "yq-go" ]
  [ "${lines[2]}" = "k9s" ]
}

@test "scope_pkgs: returns empty for nonexistent file" {
  run _nx_scope_pkgs "$_NX_ENV_DIR/scopes/nonexistent.nix"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "scope_pkgs: returns empty for empty list" {
  cat >"$_NX_ENV_DIR/scopes/empty.nix" <<'EOF'
{ pkgs }: with pkgs; [
]
EOF
  run _nx_scope_pkgs "$_NX_ENV_DIR/scopes/empty.nix"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "scope_pkgs: ignores comment-only lines inside list" {
  cat >"$_NX_ENV_DIR/scopes/test.nix" <<'EOF'
{ pkgs }: with pkgs; [
  # this is a comment
  git
  # another comment
  jq
]
EOF
  run _nx_scope_pkgs "$_NX_ENV_DIR/scopes/test.nix"
  [ "${lines[0]}" = "git" ]
  [ "${lines[1]}" = "jq" ]
  [ "${#lines[@]}" -eq 2 ]
}

# =============================================================================
# _nx_scopes
# =============================================================================

@test "scopes: returns empty when config.nix missing" {
  run _nx_scopes
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "scopes: parses config.nix with multiple scopes" {
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = true;

  scopes = [
    "shell"
    "python"
    "docker"
  ];
}
EOF
  run _nx_scopes
  [ "${lines[0]}" = "shell" ]
  [ "${lines[1]}" = "python" ]
  [ "${lines[2]}" = "docker" ]
  [ "${#lines[@]}" -eq 3 ]
}

@test "scopes: parses config.nix with empty scopes" {
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;

  scopes = [
  ];
}
EOF
  run _nx_scopes
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "scopes: parses single scope" {
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;

  scopes = [
    "shell"
  ];
}
EOF
  run _nx_scopes
  [ "${lines[0]}" = "shell" ]
  [ "${#lines[@]}" -eq 1 ]
}

# =============================================================================
# _nx_is_init
# =============================================================================

@test "is_init: returns false when config.nix missing" {
  run _nx_is_init
  [ "$output" = "false" ]
}

@test "is_init: returns true when isInit is true" {
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = true;
  scopes = [];
}
EOF
  run _nx_is_init
  [ "$output" = "true" ]
}

@test "is_init: returns false when isInit is false" {
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [];
}
EOF
  run _nx_is_init
  [ "$output" = "false" ]
}

# =============================================================================
# _nx_all_scope_pkgs
# =============================================================================

@test "all_scope_pkgs: includes base packages" {
  cat >"$_NX_ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
  jq
]
EOF
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [];
}
EOF
  run _nx_all_scope_pkgs
  [ "${lines[0]}" = "git	base" ]
  [ "${lines[1]}" = "jq	base" ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "all_scope_pkgs: includes base_init when isInit is true" {
  cat >"$_NX_ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
]
EOF
  cat >"$_NX_ENV_DIR/scopes/base_init.nix" <<'EOF'
{ pkgs }: with pkgs; [
  nano
]
EOF
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = true;
  scopes = [];
}
EOF
  run _nx_all_scope_pkgs
  [ "${lines[0]}" = "git	base" ]
  [ "${lines[1]}" = "nano	base_init" ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "all_scope_pkgs: excludes base_init when isInit is false" {
  cat >"$_NX_ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
]
EOF
  cat >"$_NX_ENV_DIR/scopes/base_init.nix" <<'EOF'
{ pkgs }: with pkgs; [
  nano
]
EOF
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [];
}
EOF
  run _nx_all_scope_pkgs
  [ "${lines[0]}" = "git	base" ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "all_scope_pkgs: includes configured scope packages" {
  cat >"$_NX_ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
]
EOF
  cat >"$_NX_ENV_DIR/scopes/shell.nix" <<'EOF'
{ pkgs }: with pkgs; [
  fzf
  bat
]
EOF
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
  ];
}
EOF
  run _nx_all_scope_pkgs
  [ "${lines[0]}" = "git	base" ]
  [ "${lines[1]}" = "fzf	shell" ]
  [ "${lines[2]}" = "bat	shell" ]
  [ "${#lines[@]}" -eq 3 ]
}

@test "all_scope_pkgs: handles multiple scopes" {
  cat >"$_NX_ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
]
EOF
  cat >"$_NX_ENV_DIR/scopes/shell.nix" <<'EOF'
{ pkgs }: with pkgs; [
  fzf
]
EOF
  cat >"$_NX_ENV_DIR/scopes/python.nix" <<'EOF'
{ pkgs }: with pkgs; [
  uv
]
EOF
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
    "python"
  ];
}
EOF
  run _nx_all_scope_pkgs
  [ "${lines[0]}" = "git	base" ]
  [ "${lines[1]}" = "fzf	shell" ]
  [ "${lines[2]}" = "uv	python" ]
  [ "${#lines[@]}" -eq 3 ]
}

@test "all_scope_pkgs: returns empty when no scopes dir" {
  rmdir "$_NX_ENV_DIR/scopes"
  run _nx_all_scope_pkgs
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# =============================================================================
# Install: scope-aware validation
# =============================================================================

@test "install: detects package already in scope" {
  cat >"$_NX_ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
  jq
]
EOF
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [];
}
EOF

  # simulate install logic
  local scope_pkgs
  scope_pkgs="$(_nx_all_scope_pkgs)"
  local in_scope
  in_scope="$(printf '%s\n' "$scope_pkgs" | grep -m1 "^git	" 2>/dev/null | cut -f2)"
  [ "$in_scope" = "base" ]
}

@test "install: allows package not in any scope" {
  cat >"$_NX_ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
]
EOF
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [];
}
EOF

  local scope_pkgs
  scope_pkgs="$(_nx_all_scope_pkgs)"
  local in_scope
  in_scope="$(printf '%s\n' "$scope_pkgs" | grep -m1 "^ripgrep	" 2>/dev/null | cut -f2)"
  [ -z "$in_scope" ]
}

@test "install: detects package in configured scope" {
  cat >"$_NX_ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
]
EOF
  cat >"$_NX_ENV_DIR/scopes/shell.nix" <<'EOF'
{ pkgs }: with pkgs; [
  fzf
  bat
]
EOF
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
  ];
}
EOF

  local scope_pkgs
  scope_pkgs="$(_nx_all_scope_pkgs)"
  local in_scope
  in_scope="$(printf '%s\n' "$scope_pkgs" | grep -m1 "^bat	" 2>/dev/null | cut -f2)"
  [ "$in_scope" = "shell" ]
}

@test "install: detects already-installed extra package" {
  printf 'ripgrep\nfd\n' | _nx_write_pkgs
  local current
  current="$(_nx_read_pkgs)"
  run printf '%s\n' "$current"
  # check the grep-based detection
  printf '%s\n' "$current" | grep -qx "ripgrep"
}

# =============================================================================
# Remove: scope-aware validation
# =============================================================================

@test "remove: detects scope-managed package" {
  cat >"$_NX_ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
]
EOF
  cat >"$_NX_ENV_DIR/scopes/shell.nix" <<'EOF'
{ pkgs }: with pkgs; [
  bat
]
EOF
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
  ];
}
EOF

  local scope_pkgs
  scope_pkgs="$(_nx_all_scope_pkgs)"
  local in_scope
  in_scope="$(printf '%s\n' "$scope_pkgs" | grep -m1 "^bat	" 2>/dev/null | cut -f2)"
  [ "$in_scope" = "shell" ]
}

@test "remove: allows removing extra package" {
  printf 'ripgrep\nfd\n' | _nx_write_pkgs
  cat >"$_NX_ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
]
EOF
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [];
}
EOF

  local scope_pkgs
  scope_pkgs="$(_nx_all_scope_pkgs)"
  local in_scope
  in_scope="$(printf '%s\n' "$scope_pkgs" | grep -m1 "^ripgrep	" 2>/dev/null | cut -f2)"
  [ -z "$in_scope" ]
}

@test "remove: filters out scope packages from args" {
  cat >"$_NX_ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
]
EOF
  cat >"$_NX_ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [];
}
EOF

  # simulate the filtering logic from nx remove
  local scope_pkgs
  scope_pkgs="$(_nx_all_scope_pkgs)"
  local args=("git" "ripgrep" "fd")
  local filtered_args=()
  local p
  for p in "${args[@]}"; do
    local in_scope
    in_scope="$(printf '%s\n' "$scope_pkgs" | grep -m1 "^${p}	" 2>/dev/null | cut -f2)"
    if [ -z "$in_scope" ]; then
      filtered_args+=("$p")
    fi
  done
  [ "${#filtered_args[@]}" -eq 2 ]
  [ "${filtered_args[0]}" = "ripgrep" ]
  [ "${filtered_args[1]}" = "fd" ]
}
