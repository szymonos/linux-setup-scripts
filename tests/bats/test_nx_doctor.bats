#!/usr/bin/env bats
# Unit tests for .assets/lib/nx_doctor.sh
bats_require_minimum_version 1.5.0

DOCTOR_SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.assets/lib/nx_doctor.sh"

setup() {
  TEST_DIR="$(mktemp -d)"
  export ENV_DIR="$TEST_DIR/nix-env"
  export DEV_ENV_DIR="$TEST_DIR/dev-env"
  export HOME="$TEST_DIR"
  mkdir -p "$ENV_DIR/scopes" "$DEV_ENV_DIR"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# -- helpers -----------------------------------------------------------------

_write_install_json() {
  cat >"$DEV_ENV_DIR/install.json" <<'EOF'
{
  "status": "success",
  "phase": "complete",
  "scopes": ["shell", "python"]
}
EOF
}

_write_flake_lock() {
  cat >"$ENV_DIR/flake.lock" <<'EOF'
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "rev": "abc123"
      }
    }
  }
}
EOF
}

_write_scope_files() {
  cat >"$ENV_DIR/scopes/shell.nix" <<'EOF'
# Shell tools
# bins: fzf bat
{ pkgs }: with pkgs; [ fzf bat ]
EOF
  cat >"$ENV_DIR/scopes/python.nix" <<'EOF'
# Python
# bins: uv
{ pkgs }: with pkgs; [ uv ]
EOF
}

# -- flake_lock check --------------------------------------------------------

@test "flake_lock passes when flake.lock exists with nixpkgs node" {
  _write_flake_lock
  _write_install_json
  run bash "$DOCTOR_SCRIPT"
  [[ "$output" == *"PASS  flake_lock"* ]]
}

@test "flake_lock fails when flake.lock is missing" {
  _write_install_json
  run bash "$DOCTOR_SCRIPT"
  [[ "$output" == *"FAIL  flake_lock"* ]]
}

# -- install_record check ---------------------------------------------------

@test "install_record passes with valid install.json" {
  _write_flake_lock
  _write_install_json
  run bash "$DOCTOR_SCRIPT"
  [[ "$output" == *"PASS  install_record"* ]]
}

@test "install_record warns when install.json is missing" {
  _write_flake_lock
  run bash "$DOCTOR_SCRIPT"
  [[ "$output" == *"WARN  install_record"* ]]
}

@test "install_record warns on failed status" {
  _write_flake_lock
  cat >"$DEV_ENV_DIR/install.json" <<'EOF'
{
  "status": "failed",
  "phase": "nix-profile",
  "scopes": []
}
EOF
  run bash "$DOCTOR_SCRIPT"
  [[ "$output" == *"WARN  install_record"* ]]
  [[ "$output" == *"failed"* ]]
}

# -- scope_binaries check ---------------------------------------------------

@test "scope_binaries warns on missing binary" {
  _write_flake_lock
  _write_install_json
  # use a fake binary name that definitely won't be in PATH
  cat >"$ENV_DIR/scopes/shell.nix" <<'EOF'
# bins: _nx_doctor_test_nonexistent_bin_
{ pkgs }: with pkgs; [ fzf ]
EOF
  run bash "$DOCTOR_SCRIPT"
  [[ "$output" == *"WARN  scope_binaries"* ]]
  [[ "$output" == *"_nx_doctor_test_nonexistent_bin_"* ]]
}

# -- shell_profile check ----------------------------------------------------

@test "shell_profile passes with exactly one managed block" {
  _write_flake_lock
  _write_install_json
  cat >"$HOME/.bashrc" <<'EOF'
# >>> nix-env managed >>>
some content
# <<< nix-env managed <<<
EOF
  run bash "$DOCTOR_SCRIPT"
  [[ "$output" == *"PASS  shell_profile"* ]]
}

@test "shell_profile fails with duplicate managed blocks" {
  _write_flake_lock
  _write_install_json
  cat >"$HOME/.bashrc" <<'EOF'
# >>> nix-env managed >>>
block 1
# <<< nix-env managed <<<
# >>> nix-env managed >>>
block 2
# <<< nix-env managed <<<
EOF
  run bash "$DOCTOR_SCRIPT"
  [[ "$output" == *"FAIL  shell_profile"* ]]
  [[ "$output" == *"duplicate"* ]]
}

# -- cert_bundle check ------------------------------------------------------

@test "cert_bundle passes when no custom certs exist" {
  _write_flake_lock
  _write_install_json
  run bash "$DOCTOR_SCRIPT"
  [[ "$output" == *"PASS  cert_bundle"* ]]
}

@test "cert_bundle fails when custom certs exist but bundle is missing" {
  _write_flake_lock
  _write_install_json
  mkdir -p "$HOME/.config/certs"
  touch "$HOME/.config/certs/ca-custom.crt"
  run bash "$DOCTOR_SCRIPT"
  [[ "$output" == *"FAIL  cert_bundle"* ]]
  [[ "$output" == *"ca-bundle.crt missing"* ]]
}

# -- JSON output -------------------------------------------------------------

@test "--json produces valid JSON with status field" {
  _write_flake_lock
  _write_install_json
  run bash "$DOCTOR_SCRIPT" --json
  # verify it's parseable JSON with the expected fields
  echo "$output" | jq -e '.status' >/dev/null
  echo "$output" | jq -e '.pass' >/dev/null
  echo "$output" | jq -e '.checks' >/dev/null
}

# -- exit code ---------------------------------------------------------------

@test "exits 1 when any check fails" {
  # no flake.lock -> flake_lock FAIL
  _write_install_json
  run bash "$DOCTOR_SCRIPT"
  [ "$status" -eq 1 ]
}

@test "json output reports failure count" {
  _write_install_json
  run bash "$DOCTOR_SCRIPT" --json
  local fail_count
  fail_count="$(echo "$output" | jq -r '.fail')"
  [ "$fail_count" -gt 0 ]
  [[ "$(echo "$output" | jq -r '.status')" == "broken" ]]
}
