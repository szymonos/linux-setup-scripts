#!/usr/bin/env bats
# Unit tests for .assets/provision/source.sh
# shellcheck disable=SC2034,SC2154
bats_require_minimum_version 1.5.0

setup() {
  # shellcheck source=../../.assets/provision/source.sh
  source "$BATS_TEST_DIRNAME/../../.assets/provision/source.sh"
}

# =============================================================================
# find_file
# =============================================================================

setup_file() {
  export FIND_FILE_DIR="$(mktemp -d)"
  mkdir -p "$FIND_FILE_DIR/a/b/c"
  touch "$FIND_FILE_DIR/top.txt"
  touch "$FIND_FILE_DIR/a/mid.txt"
  touch "$FIND_FILE_DIR/a/b/c/deep.txt"
}

teardown_file() {
  rm -rf "$FIND_FILE_DIR"
}

@test "find_file finds file in top-level directory" {
  run find_file "$FIND_FILE_DIR" "top.txt"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "$FIND_FILE_DIR/top.txt" ]]
}

@test "find_file finds file in nested directory" {
  run find_file "$FIND_FILE_DIR" "mid.txt"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "$FIND_FILE_DIR/a/mid.txt" ]]
}

@test "find_file finds file in deeply nested directory" {
  run find_file "$FIND_FILE_DIR" "deep.txt"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "$FIND_FILE_DIR/a/b/c/deep.txt" ]]
}

@test "find_file returns 1 when file not found" {
  run ! find_file "$FIND_FILE_DIR" "nonexistent.txt"
}

@test "find_file returns 1 for empty directory" {
  local empty_dir
  empty_dir="$(mktemp -d)"
  run ! find_file "$empty_dir" "anything.txt"
  rmdir "$empty_dir"
}

# =============================================================================
# download_file - parameter validation (no network)
# =============================================================================

@test "download_file fails when uri is missing" {
  run ! download_file --target_dir /tmp
  [[ "$output" == *"uri"*"required"* ]]
}

@test "download_file fails when curl is not available" {
  # shadow curl with a function that doesn't exist
  type() {
    [[ "$1" != "curl" ]] && command type "$@"
    return 1
  }
  run ! download_file --uri "https://example.com/file.tar.gz"
  [[ "$output" == *"curl"*"required"* ]]
}

# =============================================================================
# get_gh_release_latest - parameter validation (no network)
# =============================================================================

@test "get_gh_release_latest fails when owner is missing" {
  run ! get_gh_release_latest --repo "somerepo"
  [[ "$output" == *"owner"*"repo"*"required"* ]]
}

@test "get_gh_release_latest fails when repo is missing" {
  run ! get_gh_release_latest --owner "someowner"
  [[ "$output" == *"owner"*"repo"*"required"* ]]
}

# =============================================================================
# semver extraction from tag_name (testing the sed pattern directly)
# =============================================================================

@test "semver extraction: v1.2.3 -> 1.2.3" {
  result="$(echo "v1.2.3" | sed -E 's/[^0-9]*([0-9]+\.[0-9]+\.[0-9]+)/\1/')"
  [[ "$result" == "1.2.3" ]]
}

@test "semver extraction: release-10.20.30 -> 10.20.30" {
  result="$(echo "release-10.20.30" | sed -E 's/[^0-9]*([0-9]+\.[0-9]+\.[0-9]+)/\1/')"
  [[ "$result" == "10.20.30" ]]
}

@test "semver extraction: 1.2.3 (no prefix) -> 1.2.3" {
  result="$(echo "1.2.3" | sed -E 's/[^0-9]*([0-9]+\.[0-9]+\.[0-9]+)/\1/')"
  [[ "$result" == "1.2.3" ]]
}

@test "semver extraction: chart-1.0.0-beta keeps suffix" {
  result="$(echo "chart-1.0.0-beta" | sed -E 's/[^0-9]*([0-9]+\.[0-9]+\.[0-9]+)/\1/')"
  [[ "$result" == "1.0.0-beta" ]]
}

# =============================================================================
# install_github_release_user - VERSION placeholder (no network)
# =============================================================================

@test "VERSION placeholder replacement works" {
  local file_name="tool-{VERSION}-linux-amd64.tar.gz"
  local latest_release="1.5.2"
  local file="${file_name//\{VERSION\}/$latest_release}"
  [[ "$file" == "tool-1.5.2-linux-amd64.tar.gz" ]]
}

@test "VERSION placeholder: no placeholder passes through unchanged" {
  local file_name="tool-linux-amd64.tar.gz"
  local latest_release="1.5.2"
  local file="${file_name//\{VERSION\}/$latest_release}"
  [[ "$file" == "tool-linux-amd64.tar.gz" ]]
}

@test "VERSION placeholder: multiple placeholders replaced" {
  local file_name="{VERSION}/tool-{VERSION}.tar.gz"
  local latest_release="2.0.0"
  local file="${file_name//\{VERSION\}/$latest_release}"
  [[ "$file" == "2.0.0/tool-2.0.0.tar.gz" ]]
}

@test "install_github_release_user fails when required params missing" {
  run ! install_github_release_user --gh_owner "owner"
  [[ "$output" == *"Missing required parameters"* ]]
}

@test "install_github_release_user fails on unknown parameter" {
  run ! install_github_release_user --unknown_param "value"
  [[ "$output" == *"Unknown parameter"* ]]
}
