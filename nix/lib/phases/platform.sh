# phase: platform
# OS detection, overlay directory discovery, hook runner.
#
# Reads:  ENV_DIR, NIX_ENV_OVERLAY_DIR (env)
# Writes: platform, NIX_ENV_PLATFORM, OVERLAY_DIR

phase_platform_detect() {
  local os
  os="$(uname -s)"
  case "$os" in
  Darwin) platform="macOS" ;;
  Linux) platform="Linux" ;;
  *) platform="$os" ;;
  esac
  export NIX_ENV_PLATFORM="$platform"
}

phase_platform_run_hooks() {
  local hook_dir="$1"
  [ -d "$hook_dir" ] || return 0
  local hook
  for hook in "$hook_dir"/*.sh; do
    [ -f "$hook" ] || continue
    info "running hook: $(basename "$hook")"
    # shellcheck source=/dev/null
    source "$hook"
  done
}

phase_platform_discover_overlay() {
  OVERLAY_DIR=""
  if [ -n "${NIX_ENV_OVERLAY_DIR:-}" ] && [ -d "$NIX_ENV_OVERLAY_DIR" ]; then
    OVERLAY_DIR="$NIX_ENV_OVERLAY_DIR"
  elif [ -d "$ENV_DIR/local" ]; then
    OVERLAY_DIR="$ENV_DIR/local"
  fi
  if [ -n "$OVERLAY_DIR" ]; then
    info "overlay directory: $OVERLAY_DIR"
    if [ -d "$OVERLAY_DIR/scopes" ]; then
      local _overlay_nix _overlay_name
      for _overlay_nix in "$OVERLAY_DIR/scopes"/*.nix; do
        [ -f "$_overlay_nix" ] || continue
        _overlay_name="local_$(basename "$_overlay_nix")"
        cp "$_overlay_nix" "$ENV_DIR/scopes/$_overlay_name"
      done
      ok "  synced overlay scopes"
    fi
  fi
  export OVERLAY_DIR
}
