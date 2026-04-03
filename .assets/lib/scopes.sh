#!/usr/bin/env bash
: '
Shared scope definitions, dependency resolution, and install ordering.
Loads scope data from scopes.json via jq.
Sourced by brew/setup.sh and .assets/scripts/linux_setup.sh.
'

SCOPES_JSON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scopes.json"

if ! command -v jq &>/dev/null; then
  printf '\e[31;1mjq is required but not installed.\e[0m\n' >&2
  exit 1
fi

# -- Load from JSON ----------------------------------------------------------
mapfile -t VALID_SCOPES < <(jq -r '.valid_scopes[]' "$SCOPES_JSON")
mapfile -t INSTALL_ORDER < <(jq -r '.install_order[]' "$SCOPES_JSON")

# -- Dependency resolution ---------------------------------------------------
# Expands implicit scope dependencies in-place.
# Expects: an associative array `scope_set` with scope names as keys
#          and "true" as the value for enabled scopes.
# Optional: variable `omp_theme` (non-empty triggers oh_my_posh).
# shellcheck disable=SC2154  # scope_set is declared by the caller
resolve_scope_deps() {
  if [[ -n "${omp_theme:-}" ]]; then
    scope_set[oh_my_posh]=true
  fi

  local rules
  rules=$(jq -c '.dependency_rules[]' "$SCOPES_JSON")
  while IFS= read -r rule; do
    local trigger
    trigger=$(jq -r '.if' <<<"$rule")
    if [[ "${scope_set[$trigger]:-}" == "true" ]]; then
      local adds
      mapfile -t adds < <(jq -r '.add[]' <<<"$rule")
      for a in "${adds[@]}"; do
        scope_set[$a]=true
      done
    fi
  done <<<"$rules"
}

# -- Sort scopes by install order --------------------------------------------
# Populates `sorted_scopes` array from the `scope_set` associative array.
# shellcheck disable=SC2154  # scope_set is declared by the caller
sort_scopes() {
  sorted_scopes=()
  for sc in "${INSTALL_ORDER[@]}"; do
    if [[ "${scope_set[$sc]:-}" == "true" ]]; then
      sorted_scopes+=("$sc")
    fi
  done
}

# -- Validate scope names ---------------------------------------------------
# Returns 0 if all arguments are valid scope names, 1 otherwise.
validate_scopes() {
  local valid
  for s in "$@"; do
    valid=false
    for v in "${VALID_SCOPES[@]}"; do
      if [[ "$s" == "$v" ]]; then
        valid=true
        break
      fi
    done
    if [[ "$valid" == "false" ]]; then
      printf '\e[31;1mUnknown scope: %s\e[0m\n' "$s" >&2
      printf 'Valid scopes: %s\n' "${VALID_SCOPES[*]}" >&2
      return 1
    fi
  done
}
