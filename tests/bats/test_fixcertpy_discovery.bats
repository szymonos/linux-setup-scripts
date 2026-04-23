#!/usr/bin/env bats
# Unit tests for fixcertpy auto-discovery parsing patterns
# Tests the sed/grep patterns used to extract paths from pip show output.
# The actual fixcertpy function is tested with explicit paths in test_functions.bats;
# these tests cover the auto-discovery codepath's parsing logic.
# shellcheck disable=SC2030,SC2031
bats_require_minimum_version 1.5.0

# Sample pip show -f certifi output
CERTIFI_SHOW='Name: certifi
Version: 2024.2.2
Summary: Python package for providing Mozilla CA Bundle.
Home-page: https://github.com/certifi/python-certifi
Author: Kenneth Reitz
Location: /home/user/.local/lib/python3.12/site-packages
Files:
  certifi/__init__.py
  certifi/__main__.py
  certifi/cacert.pem
  certifi/core.py
  certifi/py.typed'

# Sample pip show -f pip output (cacert.pem is deeper)
PIP_SHOW='Name: pip
Version: 24.0
Summary: The PyPA recommended tool for installing Python packages.
Location: /usr/lib/python3/dist-packages
Files:
  pip/__init__.py
  pip/_vendor/certifi/cacert.pem
  pip/_vendor/certifi/core.py'

# Sample output with no cacert.pem
NO_CACERT_SHOW='Name: requests
Version: 2.31.0
Summary: Python HTTP library
Location: /home/user/.local/lib/python3.12/site-packages
Files:
  requests/__init__.py
  requests/api.py'

# =============================================================================
# Location extraction: sed -n 's/^Location: //p'
# =============================================================================

@test "location extraction: standard certifi output" {
  run bash -c 'echo "$1" | sed -n "s/^Location: //p"' -- "$CERTIFI_SHOW"
  [ "$output" = "/home/user/.local/lib/python3.12/site-packages" ]
}

@test "location extraction: pip output" {
  run bash -c 'echo "$1" | sed -n "s/^Location: //p"' -- "$PIP_SHOW"
  [ "$output" = "/usr/lib/python3/dist-packages" ]
}

@test "location extraction: empty when no Location field" {
  run bash -c 'echo "Name: foo" | sed -n "s/^Location: //p"'
  [ -z "$output" ]
}

# =============================================================================
# cacert.pem path extraction: grep -oE '[^[:space:]]+cacert\.pem$'
# =============================================================================

@test "cacert extraction: certifi package" {
  run bash -c 'echo "$1" | grep -oE "[^[:space:]]+cacert\.pem$"' -- "$CERTIFI_SHOW"
  [ "$output" = "certifi/cacert.pem" ]
}

@test "cacert extraction: pip vendored certifi" {
  run bash -c 'echo "$1" | grep -oE "[^[:space:]]+cacert\.pem$"' -- "$PIP_SHOW"
  [ "$output" = "pip/_vendor/certifi/cacert.pem" ]
}

@test "cacert extraction: empty when no cacert.pem" {
  run bash -c 'echo "$1" | grep -oE "[^[:space:]]+cacert\.pem$"' -- "$NO_CACERT_SHOW"
  [ -z "$output" ]
}

# =============================================================================
# Combined: build full path (Location + cacert)
# =============================================================================

@test "full path: certifi package" {
  local location cacert
  location=$(echo "$CERTIFI_SHOW" | sed -n 's/^Location: //p')
  cacert=$(echo "$CERTIFI_SHOW" | grep -oE '[^[:space:]]+cacert\.pem$')
  [ "${location}/${cacert}" = "/home/user/.local/lib/python3.12/site-packages/certifi/cacert.pem" ]
}

@test "full path: pip vendored certifi" {
  local location cacert
  location=$(echo "$PIP_SHOW" | sed -n 's/^Location: //p')
  cacert=$(echo "$PIP_SHOW" | grep -oE '[^[:space:]]+cacert\.pem$')
  [ "${location}/${cacert}" = "/usr/lib/python3/dist-packages/pip/_vendor/certifi/cacert.pem" ]
}

@test "full path: empty cacert yields no path addition" {
  local location cacert
  location=$(echo "$NO_CACERT_SHOW" | sed -n 's/^Location: //p')
  cacert=$(echo "$NO_CACERT_SHOW" | grep -oE '[^[:space:]]+cacert\.pem$' || true)
  [ -z "$cacert" ]
}

# =============================================================================
# Edge cases
# =============================================================================

@test "location with spaces in path" {
  local show='Name: certifi
Location: /home/user/my projects/venv/lib/python3.12/site-packages
Files:
  certifi/cacert.pem'
  local location
  location=$(echo "$show" | sed -n 's/^Location: //p')
  [ "$location" = "/home/user/my projects/venv/lib/python3.12/site-packages" ]
}

@test "multiple cacert.pem matches picks all" {
  # grep -oE returns all matches; the function uses only the first one per pip show call
  local show='Files:
  certifi/cacert.pem
  old/certifi/cacert.pem'
  run bash -c 'echo "$1" | grep -oE "[^[:space:]]+cacert\.pem$"' -- "$show"
  [ "${lines[0]}" = "certifi/cacert.pem" ]
  [ "${lines[1]}" = "old/certifi/cacert.pem" ]
  [ "${#lines[@]}" -eq 2 ]
}
