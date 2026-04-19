#!/usr/bin/env bash
# shellcheck disable=SC2154  # globals set by phase libraries (bootstrap, scopes, etc.)
# Universal dev environment setup - works on macOS, WSL/Linux, and containers.
# Uses Nix with a buildEnv flake for declarative, cross-platform package management.
# No root/sudo required after the one-time Nix install (see install_nix.sh).
# Additive: scope flags add to existing config; without flags, reconfigures
# using existing package versions. Use --upgrade to pull latest packages.
: '
# :run without scope flags (reconfigure, re-use existing package versions)
nix/setup.sh
# :upgrade all packages to latest nixpkgs
nix/setup.sh --upgrade
# :add new scopes (merged with existing config)
nix/setup.sh --pwsh
nix/setup.sh --k8s-base --pwsh --python --omp-theme "base"
nix/setup.sh --az --conda --k8s-base --pwsh --terraform --nodejs
nix/setup.sh --az --k8s-ext --rice --pwsh
# :run with oh-my-posh theme
nix/setup.sh --shell --omp-theme "base"
# :run with starship prompt
nix/setup.sh --shell --starship-theme "nerd"
# :remove a scope
nix/setup.sh --remove oh_my_posh
# :skip GitHub authentication
nix/setup.sh --az --skip-gh-auth true
# :skip GitHub SSH key registration
nix/setup.sh --az --skip-gh-ssh-key true
# :install everything
nix/setup.sh --all
# :show help
nix/setup.sh --help
'
set -eo pipefail

# ---- resolve paths -----------------------------------------------------------
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="$SCRIPT_ROOT/nix/lib"

# ---- source libraries --------------------------------------------------------
# shellcheck source=lib/io.sh
source "$LIB_DIR/io.sh"
for _p in bootstrap platform scopes nix_profile configure profiles post_install summary; do
  # shellcheck source=/dev/null
  source "$LIB_DIR/phases/$_p.sh"
done
# shellcheck source=../.assets/lib/install_record.sh
source "$SCRIPT_ROOT/.assets/lib/install_record.sh"

# ---- trap + provenance -------------------------------------------------------
_IR_ENTRY_POINT="nix"
_IR_SCRIPT_ROOT="$SCRIPT_ROOT"
_ir_phase="bootstrap"
_ir_skip=false

_on_exit() {
  local exit_code=$?
  [[ "$_ir_skip" == "true" ]] && return 0
  local status="success" error=""
  if [[ $exit_code -ne 0 ]]; then
    status="failed"
    error="${_ir_error:-exit code $exit_code}"
  fi
  _IR_SCOPES="${sorted_scopes[*]:-}"
  _IR_MODE="${_mode:-unknown}"
  _IR_PLATFORM="${platform:-unknown}"
  write_install_record "$status" "$_ir_phase" "$error"
}
trap _on_exit EXIT

# ---- run phases --------------------------------------------------------------
phase_bootstrap_check_root
phase_bootstrap_resolve_paths "$SCRIPT_ROOT"
phase_bootstrap_detect_nix
phase_bootstrap_verify_store
phase_bootstrap_sync_env_dir
phase_bootstrap_install_jq

# source scopes library (requires jq - must come after bootstrap)
# shellcheck source=../.assets/lib/scopes.sh
source "$SCRIPT_ROOT/.assets/lib/scopes.sh"

phase_bootstrap_parse_args "$@"

phase_platform_detect
_ir_phase="pre-setup"
export NIX_ENV_PHASE="pre-setup"
phase_platform_run_hooks "$ENV_DIR/hooks/pre-setup.d"
phase_platform_discover_overlay

_ir_phase="scope-resolve"
phase_scopes_load_existing
phase_scopes_apply_removes
phase_scopes_enforce_prompt_exclusivity
phase_scopes_resolve_and_sort
phase_scopes_detect_init
phase_scopes_write_config

_ir_phase="nix-profile"
phase_nix_profile_load_pinned_rev
phase_nix_profile_print_mode
phase_nix_profile_update_flake
phase_nix_profile_apply
phase_nix_profile_mitm_probe

_ir_phase="configure"
phase_configure_gh "$skip_gh_auth" "$skip_gh_ssh_key"
phase_configure_git "$skip_git_config"
phase_configure_per_scope

_ir_phase="profiles"
phase_profiles_bash
phase_profiles_zsh
phase_profiles_pwsh
export NIX_ENV_PHASE="post-setup"
phase_platform_run_hooks "$ENV_DIR/hooks/post-setup.d"

_ir_phase="post-install"
phase_post_install_common "$update_modules" "${sorted_scopes[@]}"

_ir_phase="complete"
phase_post_install_gc
phase_summary_detect_mode
phase_summary_print
