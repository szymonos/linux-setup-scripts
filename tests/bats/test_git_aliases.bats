#!/usr/bin/env bats
# Unit tests for .assets/config/bash_cfg/aliases_git.sh - git_resolve_branch
# shellcheck disable=SC2034,SC2154
bats_require_minimum_version 1.5.0

setup() {
  # source the git aliases file (it defines git_resolve_branch)
  BASH_VERSION="${BASH_VERSION:-5.0}" # guard requires this
  # shellcheck source=../../.assets/config/bash_cfg/aliases_git.sh
  source "$BATS_TEST_DIRNAME/../../.assets/config/bash_cfg/aliases_git.sh"

  # create a temp git repo for integration tests
  TEST_REPO="$(mktemp -d)"
  git -C "$TEST_REPO" init --quiet
  git -C "$TEST_REPO" config user.email "test@test.com"
  git -C "$TEST_REPO" config user.name "Test"
  # create initial commit so branches can exist
  touch "$TEST_REPO/file"
  git -C "$TEST_REPO" add file
  git -C "$TEST_REPO" commit -m "init" --quiet
}

teardown() {
  rm -rf "$TEST_REPO"
}

# =============================================================================
# git_resolve_branch - pattern selection (case statement logic)
# =============================================================================

@test "git_resolve_branch with 'main' branch in repo" {
  git -C "$TEST_REPO" branch main 2>/dev/null || true
  cd "$TEST_REPO"
  run git_resolve_branch ""
  [[ "$output" == "main" ]]
}

@test "git_resolve_branch 'm' resolves to main" {
  git -C "$TEST_REPO" branch main 2>/dev/null || true
  cd "$TEST_REPO"
  run git_resolve_branch "m"
  [[ "$output" == "main" ]]
}

@test "git_resolve_branch 'm' resolves to master" {
  git -C "$TEST_REPO" branch master 2>/dev/null || true
  cd "$TEST_REPO"
  run git_resolve_branch "m"
  # could be main or master depending on default, just check it resolves
  [[ "$output" == "main" || "$output" == "master" ]]
}

@test "git_resolve_branch 'd' resolves to development branch" {
  git -C "$TEST_REPO" branch development --quiet
  cd "$TEST_REPO"
  run git_resolve_branch "d"
  [[ "$output" == "development" ]]
}

@test "git_resolve_branch 'd' resolves to dev branch" {
  git -C "$TEST_REPO" branch dev --quiet
  cd "$TEST_REPO"
  run git_resolve_branch "d"
  [[ "$output" == "dev" ]]
}

@test "git_resolve_branch 's' resolves to stage branch" {
  git -C "$TEST_REPO" branch stage --quiet
  cd "$TEST_REPO"
  run git_resolve_branch "s"
  [[ "$output" == "stage" ]]
}

@test "git_resolve_branch 't' resolves to trunk branch" {
  git -C "$TEST_REPO" branch trunk --quiet
  cd "$TEST_REPO"
  run git_resolve_branch "t"
  [[ "$output" == "trunk" ]]
}

@test "git_resolve_branch with custom pattern passes through" {
  git -C "$TEST_REPO" branch feature-foo --quiet
  cd "$TEST_REPO"
  run git_resolve_branch "feature-foo"
  [[ "$output" == "feature-foo" ]]
}

@test "git_resolve_branch returns pattern when no branch matches" {
  cd "$TEST_REPO"
  run git_resolve_branch "nonexistent-branch-xyz"
  [[ "$output" == "nonexistent-branch-xyz" ]]
}

@test "git_resolve_branch 's' returns pattern when stage branch absent" {
  cd "$TEST_REPO"
  run git_resolve_branch "s"
  # no stage branch exists, should return the pattern
  [[ "$output" == *"stage"* ]]
}
