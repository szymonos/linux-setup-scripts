#!/usr/bin/env bats
# Unit tests for .assets/config/bash_cfg/functions.sh
# Tests PEM parsing, fixcertpy (explicit paths), cert_intercept deduplication.
# Requires: openssl
# shellcheck disable=SC2034,SC2154
bats_require_minimum_version 1.5.0

setup_file() {
  # skip entire file if openssl is not available
  command -v openssl &>/dev/null || skip "openssl not available"

  export TEST_DIR="$(mktemp -d)"

  # generate two self-signed test certificates
  openssl req -x509 -newkey rsa:2048 -keyout "$TEST_DIR/key1.pem" -out "$TEST_DIR/cert1.pem" \
    -days 1 -nodes -subj "/CN=Test Cert One" 2>/dev/null
  openssl req -x509 -newkey rsa:2048 -keyout "$TEST_DIR/key2.pem" -out "$TEST_DIR/cert2.pem" \
    -days 1 -nodes -subj "/CN=Test Cert Two" 2>/dev/null

  # create a multi-cert bundle
  cat "$TEST_DIR/cert1.pem" "$TEST_DIR/cert2.pem" > "$TEST_DIR/ca-custom.crt"

  # extract serials for verification
  export SERIAL1="$(openssl x509 -noout -serial < "$TEST_DIR/cert1.pem" | cut -d= -f2)"
  export SERIAL2="$(openssl x509 -noout -serial < "$TEST_DIR/cert2.pem" | cut -d= -f2)"
}

teardown_file() {
  rm -rf "$TEST_DIR"
}

setup() {
  command -v openssl &>/dev/null || skip "openssl not available"
  # shellcheck source=../../.assets/config/bash_cfg/functions.sh
  source "$BATS_TEST_DIRNAME/../../.assets/config/bash_cfg/functions.sh"
  # override HOME so cert functions use our test directory
  export REAL_HOME="$HOME"
  export HOME="$TEST_DIR"
}

teardown() {
  export HOME="$REAL_HOME"
}

# =============================================================================
# PEM bundle parsing (the shared pattern used by fixcertpy and cert_intercept)
# =============================================================================

@test "PEM parsing splits bundle into individual certs" {
  local cert_pems=()
  local current_pem=""
  while IFS= read -r line; do
    if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
      current_pem="$line"
    elif [[ "$line" == "-----END CERTIFICATE-----" ]]; then
      current_pem+=$'\n'"$line"
      cert_pems+=("$current_pem")
      current_pem=""
    elif [[ -n "$current_pem" ]]; then
      current_pem+=$'\n'"$line"
    fi
  done < "$TEST_DIR/ca-custom.crt"

  [[ ${#cert_pems[@]} -eq 2 ]]
}

@test "PEM parsing produces valid certificates" {
  local cert_pems=()
  local current_pem=""
  while IFS= read -r line; do
    if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
      current_pem="$line"
    elif [[ "$line" == "-----END CERTIFICATE-----" ]]; then
      current_pem+=$'\n'"$line"
      cert_pems+=("$current_pem")
      current_pem=""
    elif [[ -n "$current_pem" ]]; then
      current_pem+=$'\n'"$line"
    fi
  done < "$TEST_DIR/ca-custom.crt"

  # each parsed cert should be readable by openssl
  for pem in "${cert_pems[@]}"; do
    run openssl x509 -noout -subject <<< "$pem"
    [[ "$status" -eq 0 ]]
  done
}

@test "PEM parsing handles single cert" {
  local cert_pems=()
  local current_pem=""
  while IFS= read -r line; do
    if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
      current_pem="$line"
    elif [[ "$line" == "-----END CERTIFICATE-----" ]]; then
      current_pem+=$'\n'"$line"
      cert_pems+=("$current_pem")
      current_pem=""
    elif [[ -n "$current_pem" ]]; then
      current_pem+=$'\n'"$line"
    fi
  done < "$TEST_DIR/cert1.pem"

  [[ ${#cert_pems[@]} -eq 1 ]]
}

@test "PEM parsing handles empty file" {
  touch "$TEST_DIR/empty.crt"
  local cert_pems=()
  local current_pem=""
  while IFS= read -r line; do
    if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
      current_pem="$line"
    elif [[ "$line" == "-----END CERTIFICATE-----" ]]; then
      current_pem+=$'\n'"$line"
      cert_pems+=("$current_pem")
      current_pem=""
    elif [[ -n "$current_pem" ]]; then
      current_pem+=$'\n'"$line"
    fi
  done < "$TEST_DIR/empty.crt"

  [[ ${#cert_pems[@]} -eq 0 ]]
}

# =============================================================================
# fixcertpy - with explicit paths (no pip/venv discovery)
# =============================================================================

@test "fixcertpy appends certs to explicit cacert.pem path" {
  # set up fake cert bundle and target
  mkdir -p "$TEST_DIR/.config/certs"
  cp "$TEST_DIR/ca-custom.crt" "$TEST_DIR/.config/certs/ca-custom.crt"
  # create a minimal target cacert.pem
  echo "# existing bundle" > "$TEST_DIR/cacert.pem"

  run fixcertpy "$TEST_DIR/cacert.pem"

  # target should now contain both serials
  grep -qw "$SERIAL1" "$TEST_DIR/cacert.pem"
  grep -qw "$SERIAL2" "$TEST_DIR/cacert.pem"
}

@test "fixcertpy does not duplicate certs on re-run" {
  mkdir -p "$TEST_DIR/.config/certs"
  cp "$TEST_DIR/ca-custom.crt" "$TEST_DIR/.config/certs/ca-custom.crt"
  echo "# existing bundle" > "$TEST_DIR/cacert2.pem"

  # run twice
  fixcertpy "$TEST_DIR/cacert2.pem" 2>/dev/null
  local size_after_first
  size_after_first=$(wc -c < "$TEST_DIR/cacert2.pem")

  fixcertpy "$TEST_DIR/cacert2.pem" 2>/dev/null
  local size_after_second
  size_after_second=$(wc -c < "$TEST_DIR/cacert2.pem")

  # file should not grow on second run
  [[ "$size_after_first" -eq "$size_after_second" ]]
}

@test "fixcertpy reports no certs when bundle is missing" {
  # ensure no cert bundle exists
  rm -f "$TEST_DIR/.config/certs/ca-custom.crt"

  run fixcertpy "$TEST_DIR/some_cacert.pem"
  # should return 0 (no certs to add is not an error)
  [[ "$status" -eq 0 ]]
}

@test "fixcertpy skips nonexistent target paths" {
  mkdir -p "$TEST_DIR/.config/certs"
  cp "$TEST_DIR/ca-custom.crt" "$TEST_DIR/.config/certs/ca-custom.crt"

  # pass a path that doesn't exist
  run fixcertpy "/nonexistent/path/cacert.pem"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"no certifi/cacert.pem bundles found"* ]]
}

# =============================================================================
# cert_intercept deduplication - string-based serial tracking
# =============================================================================

@test "serial dedup string correctly tracks added serials" {
  local _existing_serials=" "

  # simulate adding serials
  _existing_serials+="$SERIAL1 "
  [[ " $_existing_serials " == *" $SERIAL1 "* ]]

  # serial2 should not be present yet
  [[ " $_existing_serials " != *" $SERIAL2 "* ]]

  # add serial2
  _existing_serials+="$SERIAL2 "
  [[ " $_existing_serials " == *" $SERIAL2 "* ]]
}

@test "serial dedup string does not match partial serials" {
  local _existing_serials=" ABC123 "

  # should not match partial
  [[ " $_existing_serials " != *" ABC "* ]]
  [[ " $_existing_serials " != *" 123 "* ]]
  # should match full
  [[ " $_existing_serials " == *" ABC123 "* ]]
}

@test "cert_intercept returns 1 when openssl is missing" {
  # shadow openssl
  type() { return 1; }
  run ! cert_intercept
  [[ "$output" == *"openssl"*"required"* ]]
}
