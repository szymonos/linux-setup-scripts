#!/usr/bin/env bash
: '
Shared scope definitions, dependency resolution, and install ordering.
Loads scope data from scopes.json via jq.
Sourced by nix/setup.sh and .assets/scripts/linux_setup.sh.

Contract: callers use a space-delimited string `_scope_set` (e.g. " shell python ")
with the helper functions below. This avoids bash 4+ associative arrays for macOS compat.

Why JSON (and why jq)?
----------------------
scopes.json is the single source of truth for scope metadata (valid names,
install order, dependency rules). It has three first-class consumers that
each parse it natively:

  - bash (this file) via jq
  - PowerShell: modules/SetupUtils/SetupUtils.psm1, wsl/wsl_setup.ps1
    (ConvertFrom-Json - built-in, no dependency)
  - Python: tests/hooks/validate_scopes.py (json stdlib)

JSON is the only format all three parse without a custom parser. Switching
to a bash-sourceable format would break the PowerShell and Python consumers
or force parallel data files (source-of-truth split).

The only cost of this choice is that bash 3.2 on bare macOS has no JSON
parser, so jq must be bootstrapped before scope resolution runs. See
nix/scopes/base_init.nix and the `needsBootstrap`/`isInit` handling in
nix/setup.sh:183-197 and nix/flake.nix. The bootstrap is ~13 lines, runs
once per machine (seconds), and is documented in ARCHITECTURE.md under
"Bootstrap dependency (base_init.nix)".
'

SCOPES_JSON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scopes.json"

if ! command -v jq &>/dev/null; then
  printf '\e[31;1mjq is required but not installed.\e[0m\n' >&2
  exit 1
fi

# -- Load from JSON ----------------------------------------------------------
VALID_SCOPES=()
while IFS= read -r _l; do VALID_SCOPES+=("$_l"); done < <(jq -r '.valid_scopes[]' "$SCOPES_JSON")
INSTALL_ORDER=()
while IFS= read -r _l; do INSTALL_ORDER+=("$_l"); done < <(jq -r '.install_order[]' "$SCOPES_JSON")

# -- Scope-set helpers (bash 3.2 compatible) ---------------------------------
# _scope_set is a space-padded string: " scope1 scope2 scope3 "
# Callers must initialize: _scope_set=" "

# Check if scope is in the set. Returns 0 (true) or 1 (false).
scope_has() { [[ " $_scope_set " == *" $1 "* ]]; }

# Add a scope to the set (idempotent).
scope_add() { scope_has "$1" || _scope_set+="$1 "; }

# Remove a scope from the set.
scope_del() { _scope_set="${_scope_set/ $1 / }"; }

# -- Dependency resolution ---------------------------------------------------
# Expands implicit scope dependencies in-place.
# Expects: `_scope_set` string populated by the caller.
# Optional: variable `omp_theme` (non-empty triggers oh_my_posh).
resolve_scope_deps() {
  if [[ -n "${omp_theme:-}" ]]; then
    scope_add oh_my_posh
  fi

  local rules
  rules=$(jq -c '.dependency_rules[]' "$SCOPES_JSON")
  while IFS= read -r rule; do
    local trigger
    trigger=$(jq -r '.if' <<<"$rule")
    if scope_has "$trigger"; then
      local adds=()
      while IFS= read -r _l; do adds+=("$_l"); done < <(jq -r '.add[]' <<<"$rule")
      for a in "${adds[@]}"; do
        scope_add "$a"
      done
    fi
  done <<<"$rules"
}

# -- Sort scopes by install order --------------------------------------------
# Populates `sorted_scopes` array from `_scope_set`.
sort_scopes() {
  sorted_scopes=()
  for sc in "${INSTALL_ORDER[@]}"; do
    if scope_has "$sc"; then
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
