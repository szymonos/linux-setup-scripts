#!/usr/bin/env bats
# Unit tests for nx CLI commands (pin, rollback, scope remove, scope edit, help)
bats_require_minimum_version 1.5.0

ALIASES_SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.assets/config/bash_cfg/aliases_nix.sh"

setup() {
  TEST_DIR="$(mktemp -d)"
  export HOME="$TEST_DIR"

  mkdir -p "$TEST_DIR/bin"
  printf '#!/bin/sh\nexit 0\n' >"$TEST_DIR/bin/nix"
  chmod +x "$TEST_DIR/bin/nix"
  export PATH="$TEST_DIR/bin:$PATH"

  ENV_DIR="$HOME/.config/nix-env"
  mkdir -p "$ENV_DIR/scopes"

  # shellcheck source=../../.assets/config/bash_cfg/aliases_nix.sh
  source "$ALIASES_SCRIPT"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# -- help ---------------------------------------------------------------------

@test "nx help shows usage" {
  run nx help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: nx"* ]]
  [[ "$output" == *"install"* ]]
  [[ "$output" == *"upgrade"* ]]
  [[ "$output" == *"pin"* ]]
  [[ "$output" == *"rollback"* ]]
}

@test "nx without args shows help" {
  run nx
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: nx"* ]]
}

@test "nx unknown command shows error" {
  run nx fakecmd
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command"* ]]
}

# -- scope help (no default to list) ------------------------------------------

@test "nx scope without subcommand shows help" {
  run nx scope
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: nx scope"* ]]
  [[ "$output" == *"list"* ]]
  [[ "$output" == *"add"* ]]
  [[ "$output" == *"edit"* ]]
  [[ "$output" == *"remove"* ]]
}

# -- pin set (no args = read from flake.lock) ---------------------------------

@test "pin set without rev reads from flake.lock" {
  cat >"$ENV_DIR/flake.lock" <<'EOF'
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "rev": "abc123def456"
      }
    }
  }
}
EOF
  run nx pin set
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pinned nixpkgs to abc123def456"* ]]
  [ -f "$ENV_DIR/pinned_rev" ]
  [ "$(tr -d '[:space:]' <"$ENV_DIR/pinned_rev")" = "abc123def456" ]
}

@test "pin set with explicit rev uses that rev" {
  run nx pin set deadbeef123
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pinned nixpkgs to deadbeef123"* ]]
  [ "$(tr -d '[:space:]' <"$ENV_DIR/pinned_rev")" = "deadbeef123" ]
}

@test "pin set without rev fails when no flake.lock" {
  run nx pin set
  [ "$status" -eq 1 ]
  [[ "$output" == *"No flake.lock found"* ]]
}

@test "pin set overwrites existing pin" {
  printf 'oldrev\n' >"$ENV_DIR/pinned_rev"
  run nx pin set newrev
  [ "$status" -eq 0 ]
  [ "$(tr -d '[:space:]' <"$ENV_DIR/pinned_rev")" = "newrev" ]
}

# -- pin show -----------------------------------------------------------------

@test "pin show displays current pin" {
  printf 'abc123\n' >"$ENV_DIR/pinned_rev"
  run nx pin show
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pinned to:"* ]]
  [[ "$output" == *"abc123"* ]]
}

@test "pin show reports no pin when file missing" {
  run nx pin show
  [ "$status" -eq 0 ]
  [[ "$output" == *"No pin set"* ]]
}

# -- pin remove ---------------------------------------------------------------

@test "pin remove deletes pin file" {
  printf 'abc123\n' >"$ENV_DIR/pinned_rev"
  run nx pin remove
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pin removed"* ]]
  [ ! -f "$ENV_DIR/pinned_rev" ]
}

@test "pin remove reports no pin when file missing" {
  run nx pin remove
  [ "$status" -eq 0 ]
  [[ "$output" == *"No pin set"* ]]
}

# -- pin help -----------------------------------------------------------------

@test "pin help shows usage" {
  run nx pin help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: nx pin"* ]]
  [[ "$output" == *"set"* ]]
  [[ "$output" == *"remove"* ]]
  [[ "$output" == *"show"* ]]
}

@test "pin without subcommand shows current pin status" {
  run nx pin
  [ "$status" -eq 0 ]
  [[ "$output" == *"No pin set"* ]]
}

# -- upgrade with pinned_rev --------------------------------------------------

@test "upgrade reads pinned_rev file when present" {
  printf 'pinnedabc123\n' >"$ENV_DIR/pinned_rev"
  run nx upgrade
  [ "$status" -eq 0 ]
  [[ "$output" == *"pinning nixpkgs to pinnedabc123"* ]]
}

@test "upgrade without pin does normal update" {
  run nx upgrade
  [ "$status" -eq 0 ]
  [[ "$output" != *"pinning nixpkgs"* ]]
}

# -- scope remove with local_ prefix -----------------------------------------

@test "scope remove handles local_ prefix transparently" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
    "local_devtools"
  ];
}
EOF
  mkdir -p "$ENV_DIR/local/scopes"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/local/scopes/devtools.nix"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/scopes/local_devtools.nix"

  run nx scope remove devtools
  [ "$status" -eq 0 ]
  [[ "$output" == *"removed scope: devtools"* ]]
  # config.nix should no longer have local_devtools
  run ! grep -q 'local_devtools' "$ENV_DIR/config.nix"
  # scope files should be cleaned up
  [ ! -f "$ENV_DIR/local/scopes/devtools.nix" ]
  [ ! -f "$ENV_DIR/scopes/local_devtools.nix" ]
}

@test "scope remove handles repo scope by name" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
    "python"
  ];
}
EOF
  run nx scope remove python
  [ "$status" -eq 0 ]
  [[ "$output" == *"removed scope: python"* ]]
  run ! grep -q '"python"' "$ENV_DIR/config.nix"
  grep -q '"shell"' "$ENV_DIR/config.nix"
}

@test "scope remove cleans orphaned overlay files" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
  ];
}
EOF
  mkdir -p "$ENV_DIR/local/scopes"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/local/scopes/orphan.nix"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/scopes/local_orphan.nix"

  run nx scope remove orphan
  [ "$status" -eq 0 ]
  [ ! -f "$ENV_DIR/local/scopes/orphan.nix" ]
  [ ! -f "$ENV_DIR/scopes/local_orphan.nix" ]
}

@test "scope remove multiple scopes at once" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
    "python"
    "local_devtools"
  ];
}
EOF
  mkdir -p "$ENV_DIR/local/scopes"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/local/scopes/devtools.nix"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/scopes/local_devtools.nix"

  run nx scope remove python devtools
  [ "$status" -eq 0 ]
  [[ "$output" == *"removed scope: python"* ]]
  [[ "$output" == *"removed scope: devtools"* ]]
  grep -q '"shell"' "$ENV_DIR/config.nix"
  run ! grep -q '"python"' "$ENV_DIR/config.nix"
  run ! grep -q 'local_devtools' "$ENV_DIR/config.nix"
}

@test "scope remove reports unknown scope" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
  ];
}
EOF
  run nx scope remove nonexistent
  [[ "$output" == *"is not configured"* ]]
}

# -- scope edit ---------------------------------------------------------------

@test "scope edit fails for nonexistent scope" {
  run nx scope edit nonexistent
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}

@test "scope edit opens file and syncs copy" {
  mkdir -p "$ENV_DIR/local/scopes"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/local/scopes/mytools.nix"
  # use 'true' as EDITOR to simulate a no-op edit
  EDITOR=true run nx scope edit mytools
  [ "$status" -eq 0 ]
  [[ "$output" == *"Synced scope"* ]]
  [ -f "$ENV_DIR/scopes/local_mytools.nix" ]
}

@test "scope edit falls back to vi when EDITOR unset" {
  mkdir -p "$ENV_DIR/local/scopes"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/local/scopes/mytools.nix"
  # create a fake vi that exits immediately
  printf '#!/bin/sh\nexit 0\n' >"$TEST_DIR/bin/vi"
  chmod +x "$TEST_DIR/bin/vi"
  unset EDITOR
  run nx scope edit mytools
  [ "$status" -eq 0 ]
}

# -- scope add with packages (validation stubbed) ----------------------------

@test "scope add creates scope and reports guidance" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [];
}
EOF
  run nx scope add newscope
  [ "$status" -eq 0 ]
  [[ "$output" == *"Created scope"* ]]
  [[ "$output" == *"nx scope add newscope"* ]]
  [ -f "$ENV_DIR/local/scopes/newscope.nix" ]
}

@test "scope add to existing scope without packages shows hint" {
  mkdir -p "$ENV_DIR/local/scopes"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/local/scopes/existing.nix"
  run nx scope add existing
  [ "$status" -eq 0 ]
  [[ "$output" == *"already exists"* ]]
}

# -- scope list ---------------------------------------------------------------

@test "scope list shows installed scopes" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
    "python"
  ];
}
EOF
  run nx scope list
  [ "$status" -eq 0 ]
  [[ "$output" == *"shell"* ]]
  [[ "$output" == *"python"* ]]
}

@test "scope list shows no scopes when empty" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [];
}
EOF
  run nx scope list
  [ "$status" -eq 0 ]
  [[ "$output" == *"No scopes"* ]]
}

# -- scope show ---------------------------------------------------------------

@test "scope show displays packages in a scope" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
  ];
}
EOF
  cat >"$ENV_DIR/scopes/shell.nix" <<'EOF'
{ pkgs }: with pkgs; [
  fzf
  bat
  ripgrep
]
EOF
  run nx scope show shell
  [ "$status" -eq 0 ]
  [[ "$output" == *"fzf"* ]]
  [[ "$output" == *"bat"* ]]
  [[ "$output" == *"ripgrep"* ]]
}

@test "scope show reports unknown scope" {
  run nx scope show nonexistent
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"No scope file"* ]]
}

# -- scope tree ---------------------------------------------------------------

@test "scope tree shows scopes with packages" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
  ];
}
EOF
  cat >"$ENV_DIR/scopes/shell.nix" <<'EOF'
{ pkgs }: with pkgs; [
  fzf
  bat
]
EOF
  cat >"$ENV_DIR/scopes/base.nix" <<'EOF'
{ pkgs }: with pkgs; [
  git
]
EOF
  run nx scope tree
  [ "$status" -eq 0 ]
  [[ "$output" == *"shell"* ]]
  [[ "$output" == *"fzf"* ]]
}

# -- _nx_scope_file_add helper ------------------------------------------------

@test "scope_file_add adds packages to scope file" {
  local file="$TEST_DIR/test.nix"
  printf '{ pkgs }: with pkgs; []\n' >"$file"
  _nx_scope_file_add "$file" httpie jq
  # verify the file contains the packages
  grep -q 'httpie' "$file"
  grep -q 'jq' "$file"
}

@test "scope_file_add deduplicates existing packages" {
  local file="$TEST_DIR/test.nix"
  cat >"$file" <<'EOF'
{ pkgs }: with pkgs; [
  httpie
]
EOF
  run _nx_scope_file_add "$file" httpie
  [[ "$output" == *"already in scope"* ]]
}

@test "scope_file_add sorts packages" {
  local file="$TEST_DIR/test.nix"
  printf '{ pkgs }: with pkgs; []\n' >"$file"
  _nx_scope_file_add "$file" zoxide bat httpie
  # read in order
  local pkgs
  pkgs="$(_nx_scope_pkgs "$file")"
  local first second third
  first="$(echo "$pkgs" | sed -n '1p')"
  second="$(echo "$pkgs" | sed -n '2p')"
  third="$(echo "$pkgs" | sed -n '3p')"
  [ "$first" = "bat" ]
  [ "$second" = "httpie" ]
  [ "$third" = "zoxide" ]
}

# -- _nx_validate_pkg helper --------------------------------------------------

@test "validate_pkg returns success for valid package" {
  # override nix to echo a name
  printf '#!/bin/sh\necho "test-1.0"\n' >"$TEST_DIR/bin/nix"
  chmod +x "$TEST_DIR/bin/nix"
  run _nx_validate_pkg testpkg
  [ "$status" -eq 0 ]
}

@test "validate_pkg returns failure for invalid package" {
  printf '#!/bin/sh\nexit 1\n' >"$TEST_DIR/bin/nix"
  chmod +x "$TEST_DIR/bin/nix"
  run _nx_validate_pkg fakepkg
  [ "$status" -ne 0 ]
}

# -- rollback -----------------------------------------------------------------

@test "rollback succeeds when nix profile rollback succeeds" {
  run nx rollback
  [ "$status" -eq 0 ]
  [[ "$output" == *"Rolled back"* ]]
  [[ "$output" == *"Restart your shell"* ]]
}

@test "rollback fails when nix profile rollback fails" {
  printf '#!/bin/sh\nexit 1\n' >"$TEST_DIR/bin/nix"
  chmod +x "$TEST_DIR/bin/nix"
  run nx rollback
  [ "$status" -eq 1 ]
  [[ "$output" == *"rollback failed"* ]]
}

# -- overlay help -------------------------------------------------------------

@test "overlay help shows usage" {
  run nx overlay help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: nx overlay"* ]]
}
