# phase: nix-profile
# Flake update, nix profile upgrade, MITM proxy certificate detection.
# shellcheck disable=SC2154  # globals set by bootstrap phase
#
# Reads:  ENV_DIR, upgrade_packages, SCRIPT_ROOT
# Writes: PINNED_REV, _ir_error

should_update_flake() {
  local upgrade_flag="${1:-false}"
  [[ "$upgrade_flag" == "true" ]] && return 0
  return 1
}

phase_nix_profile_load_pinned_rev() {
  PINNED_REV=""
  if [[ -f "$ENV_DIR/pinned_rev" ]]; then
    PINNED_REV="$(tr -d '[:space:]' <"$ENV_DIR/pinned_rev")"
  fi
}

phase_nix_profile_print_mode() {
  if [[ ! -f "$ENV_DIR/flake.lock" ]]; then
    info "first run - resolving nixpkgs and installing..."
  elif should_update_flake "$upgrade_packages"; then
    if [[ -n "$PINNED_REV" ]]; then
      info "pinning nixpkgs to $PINNED_REV..."
    else
      info "upgrading all packages to latest (nix flake update + profile upgrade)..."
    fi
  else
    info "applying nix configuration (use --upgrade to pull latest packages)..."
  fi
}

phase_nix_profile_update_flake() {
  SECONDS=0
  if should_update_flake "$upgrade_packages"; then
    if [[ -n "$PINNED_REV" ]]; then
      _io_nix flake lock --override-input nixpkgs "github:nixos/nixpkgs/$PINNED_REV" --flake "$ENV_DIR" 2>/dev/null ||
        warn "flake lock failed - using existing lock"
    else
      _io_nix flake update --flake "$ENV_DIR" 2>/dev/null ||
        warn "flake update failed (network issue?) - using existing lock"
    fi
  fi
}

phase_nix_profile_apply() {
  if ! _io_nix profile add "path:$ENV_DIR" 2>&1; then
    warn "nix profile add failed (may already exist) - continuing with upgrade"
  fi
  _io_nix profile upgrade nix-env ||
    { _ir_error="nix profile upgrade failed"; err "$_ir_error"; exit 1; }
  ok "nix profile updated in ${SECONDS}s"
}

phase_nix_profile_mitm_probe() {
  # shellcheck source=../../../.assets/lib/certs.sh
  source "$SCRIPT_ROOT/.assets/lib/certs.sh"
  if ! _io_curl_probe "$NIX_ENV_TLS_PROBE_URL" && command -v openssl &>/dev/null; then
    warn "SSL verification failed - MITM proxy detected, intercepting certificates..."
    # shellcheck source=../../../.assets/config/bash_cfg/functions.sh
    source "$SCRIPT_ROOT/.assets/config/bash_cfg/functions.sh"
    cert_intercept
    build_ca_bundle
    local ca_bundle="$HOME/.config/certs/ca-bundle.crt"
    if [[ -f "$ca_bundle" ]]; then
      export NIX_SSL_CERT_FILE="$ca_bundle"
      export SSL_CERT_FILE="$ca_bundle"
      ok "set NIX_SSL_CERT_FILE and SSL_CERT_FILE to merged CA bundle"
    fi
  fi
}
