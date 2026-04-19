#!/usr/bin/env bats
# Unit tests for .assets/lib/scopes.sh (bash 3.2 compatible helpers)
# shellcheck disable=SC2034,SC2154  # variables like omp_theme, sorted_scopes used by sourced lib
bats_require_minimum_version 1.5.0

setup() {
  # shellcheck source=../../.assets/lib/scopes.sh
  source "$BATS_TEST_DIRNAME/../../.assets/lib/scopes.sh"
  _scope_set=" "
}

# -- scope_add / scope_has / scope_del ----------------------------------------

@test "scope_has returns false on empty set" {
  run ! scope_has "shell"
}

@test "scope_add makes scope_has return true" {
  scope_add "shell"
  scope_has "shell"
}

@test "scope_has returns false for absent scope" {
  scope_add "shell"
  run ! scope_has "python"
}

@test "scope_add is idempotent - no duplicates" {
  scope_add "shell"
  scope_add "python"
  scope_add "shell"
  [[ "$_scope_set" == " shell python " ]]
}

@test "scope_del removes a scope" {
  scope_add "shell"
  scope_add "python"
  scope_del "shell"
  run ! scope_has "shell"
  scope_has "python"
}

@test "scope_del on absent scope is a no-op" {
  scope_add "python"
  scope_del "nonexistent"
  scope_has "python"
}

@test "scope_has does not match partial names" {
  scope_add "shell"
  run ! scope_has "shel"
  run ! scope_has "hell"
  run ! scope_has "shells"
}

# -- VALID_SCOPES / INSTALL_ORDER loaded from JSON ----------------------------

@test "VALID_SCOPES is non-empty" {
  [[ ${#VALID_SCOPES[@]} -gt 0 ]]
}

@test "INSTALL_ORDER is non-empty" {
  [[ ${#INSTALL_ORDER[@]} -gt 0 ]]
}

@test "shell is a valid scope" {
  local found=false
  for v in "${VALID_SCOPES[@]}"; do
    [[ "$v" == "shell" ]] && found=true
  done
  [[ "$found" == "true" ]]
}

# -- validate_scopes ----------------------------------------------------------

@test "validate_scopes accepts valid scopes" {
  validate_scopes "shell" "python"
}

@test "validate_scopes rejects unknown scope" {
  run ! validate_scopes "nonexistent"
}

# -- resolve_scope_deps -------------------------------------------------------

@test "pwsh pulls in shell" {
  scope_add "pwsh"
  resolve_scope_deps
  scope_has "shell"
}

@test "k8s_ext pulls in k8s_base, k8s_dev, and docker" {
  scope_add "k8s_ext"
  resolve_scope_deps
  scope_has "k8s_base"
  scope_has "k8s_dev"
  scope_has "docker"
}

@test "az pulls in python" {
  scope_add "az"
  resolve_scope_deps
  scope_has "python"
}

@test "omp_theme variable triggers oh_my_posh scope" {
  scope_add "shell"
  omp_theme="base"
  resolve_scope_deps
  scope_has "oh_my_posh"
}

@test "oh_my_posh pulls in shell" {
  scope_add "oh_my_posh"
  resolve_scope_deps
  scope_has "shell"
}

@test "starship pulls in shell" {
  scope_add "starship"
  resolve_scope_deps
  scope_has "shell"
}

@test "zsh pulls in shell" {
  scope_add "zsh"
  resolve_scope_deps
  scope_has "shell"
}

# -- sort_scopes --------------------------------------------------------------

@test "sort_scopes respects install_order" {
  scope_add "rice"
  scope_add "shell"
  scope_add "python"
  scope_add "docker"
  sort_scopes
  [[ "${sorted_scopes[*]}" == "docker python shell rice" ]]
}

@test "sort_scopes with empty set gives empty array" {
  sort_scopes
  [[ ${#sorted_scopes[@]} -eq 0 ]]
}

@test "sort_scopes omits scopes not in set" {
  scope_add "python"
  sort_scopes
  [[ "${sorted_scopes[*]}" == "python" ]]
}

# -- hyphen normalization (nix/setup.sh pattern) ------------------------------

@test "global hyphen-to-underscore normalization works" {
  _scope_set=" k8s-base k8s-ext "
  _scope_set="${_scope_set//-/_}"
  scope_has "k8s_base"
  scope_has "k8s_ext"
  run ! scope_has "k8s-base"
}
