#!/usr/bin/env bats
# Unit tests for nx overlay and nx scope add commands
bats_require_minimum_version 1.5.0

ALIASES_SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.assets/config/bash_cfg/aliases_nix.sh"

setup() {
  TEST_DIR="$(mktemp -d)"
  export HOME="$TEST_DIR"

  # create fake nix binary so nx() function gets defined when sourcing aliases
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

# -- overlay list ------------------------------------------------------------

@test "overlay list reports no overlay when dir doesn't exist" {
  run nx overlay list
  [ "$status" -eq 0 ]
  [[ "$output" == *"No overlay directory active"* ]]
}

@test "overlay list discovers local dir" {
  mkdir -p "$ENV_DIR/local"
  run nx overlay list
  [ "$status" -eq 0 ]
  [[ "$output" == *"$ENV_DIR/local"* ]]
}

@test "overlay list prefers NIX_ENV_OVERLAY_DIR over local dir" {
  mkdir -p "$ENV_DIR/local"
  local custom_dir="$TEST_DIR/custom-overlay"
  mkdir -p "$custom_dir"
  export NIX_ENV_OVERLAY_DIR="$custom_dir"
  run nx overlay list
  [[ "$output" == *"$custom_dir"* ]]
}

@test "overlay list shows scope files" {
  mkdir -p "$ENV_DIR/local/scopes"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/local/scopes/my_tools.nix"
  run nx overlay list
  [[ "$output" == *"Scopes:"* ]]
  [[ "$output" == *"my_tools"* ]]
}

@test "overlay list shows shell config files" {
  mkdir -p "$ENV_DIR/local/bash_cfg"
  touch "$ENV_DIR/local/bash_cfg/custom.sh"
  run nx overlay list
  [[ "$output" == *"Shell config:"* ]]
  [[ "$output" == *"custom.sh"* ]]
}

@test "overlay list shows hook files" {
  mkdir -p "$ENV_DIR/local/hooks/post-setup.d"
  touch "$ENV_DIR/local/hooks/post-setup.d/10-custom.sh"
  run nx overlay list
  [[ "$output" == *"Hooks (post-setup.d):"* ]]
  [[ "$output" == *"10-custom.sh"* ]]
}

@test "overlay list handles empty overlay directory" {
  mkdir -p "$ENV_DIR/local"
  run nx overlay list
  [ "$status" -eq 0 ]
}

# -- overlay status ----------------------------------------------------------

@test "overlay status shows none when no overlay dir" {
  run nx overlay status
  [ "$status" -eq 0 ]
  [[ "$output" == *"none"* ]]
  [[ "$output" == *"No overlay scopes synced"* ]]
}

@test "overlay status shows synced overlay scopes" {
  mkdir -p "$ENV_DIR/local/scopes"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/local/scopes/my_tools.nix"
  cp "$ENV_DIR/local/scopes/my_tools.nix" "$ENV_DIR/scopes/local_my_tools.nix"
  run nx overlay status
  [[ "$output" == *"Overlay scopes (synced):"* ]]
  [[ "$output" == *"my_tools"* ]]
}

@test "overlay status shows modified indicator when source differs" {
  mkdir -p "$ENV_DIR/local/scopes"
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/scopes/local_my_tools.nix"
  printf '{ pkgs }: with pkgs; [ hello ]\n' >"$ENV_DIR/local/scopes/my_tools.nix"
  run nx overlay status
  [[ "$output" == *"modified"* ]]
}

@test "overlay status shows source missing when overlay dir has no source" {
  printf '{ pkgs }: with pkgs; []\n' >"$ENV_DIR/scopes/local_orphan.nix"
  run nx overlay status
  [[ "$output" == *"source missing"* ]]
}

@test "overlay status shows shell config sync status" {
  mkdir -p "$ENV_DIR/local/bash_cfg" "$HOME/.config/bash"
  printf 'echo hello\n' >"$ENV_DIR/local/bash_cfg/custom.sh"
  cp "$ENV_DIR/local/bash_cfg/custom.sh" "$HOME/.config/bash/custom.sh"
  run nx overlay status
  [[ "$output" == *"synced"* ]]
}

@test "overlay status shows differs indicator for changed shell config" {
  mkdir -p "$ENV_DIR/local/bash_cfg" "$HOME/.config/bash"
  printf 'echo hello\n' >"$ENV_DIR/local/bash_cfg/custom.sh"
  printf 'echo world\n' >"$HOME/.config/bash/custom.sh"
  run nx overlay status
  [[ "$output" == *"differs"* ]]
}

# -- scope add ---------------------------------------------------------------

@test "scope add creates stub nix file in overlay directory" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
  ];
}
EOF
  run nx scope add my_tools
  [ "$status" -eq 0 ]
  [[ "$output" == *"Created scope"* ]]
  [ -f "$ENV_DIR/local/scopes/my_tools.nix" ]
  [ -f "$ENV_DIR/scopes/local_my_tools.nix" ]
}

@test "scope add registers scope in config.nix" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [
    "shell"
  ];
}
EOF
  nx scope add my_tools
  grep -q 'local_my_tools' "$ENV_DIR/config.nix"
  grep -q 'shell' "$ENV_DIR/config.nix"
}

@test "scope add is idempotent for existing scope" {
  mkdir -p "$ENV_DIR/local/scopes"
  printf '{ pkgs }: with pkgs; [ hello ]\n' >"$ENV_DIR/local/scopes/my_tools.nix"
  run nx scope add my_tools
  [ "$status" -eq 0 ]
  [[ "$output" == *"already exists"* ]]
}

@test "scope add normalizes hyphens to underscores" {
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [];
}
EOF
  run nx scope add my-tools
  [ "$status" -eq 0 ]
  [ -f "$ENV_DIR/local/scopes/my_tools.nix" ]
}

@test "scope add uses NIX_ENV_OVERLAY_DIR when set" {
  local custom_dir="$TEST_DIR/custom-overlay"
  mkdir -p "$custom_dir"
  export NIX_ENV_OVERLAY_DIR="$custom_dir"
  cat >"$ENV_DIR/config.nix" <<'EOF'
{
  isInit = false;
  scopes = [];
}
EOF
  run nx scope add my_tools
  [ "$status" -eq 0 ]
  [ -f "$custom_dir/scopes/my_tools.nix" ]
}
