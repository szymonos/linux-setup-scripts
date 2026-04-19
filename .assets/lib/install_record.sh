# Installation provenance record writer.
# Writes ~/.config/dev-env/install.json with setup metadata.
# Compatible with bash 3.2 and zsh (sourced by both).
#
# Usage:
#   source .assets/lib/install_record.sh
#
#   # set variables before calling (or before trap fires):
#   _IR_ENTRY_POINT="nix"      # nix, legacy, wsl
#   _IR_SCRIPT_ROOT="/path"    # repo root, for git version detection
#   _IR_SCOPES="az shell"      # space-separated scope list
#   _IR_MODE="install"         # install, upgrade, reconfigure, remove
#   _IR_PLATFORM="Linux"       # macOS, Linux
#
#   # call directly or from an EXIT trap:
#   write_install_record <status> <phase> [error_message]

# shellcheck disable=SC2034  # DEV_ENV_DIR used by sourcing scripts
DEV_ENV_DIR="$HOME/.config/dev-env"

# write_install_record <status> <phase> [error_message]
write_install_record() {
  local status="${1:-unknown}" phase="${2:-unknown}" error="${3:-}"
  local entry_point="${_IR_ENTRY_POINT:-unknown}"

  mkdir -p "$DEV_ENV_DIR"

  # version priority: git describe > VERSION file (tarball) > "unknown"
  local version="" source="" source_ref=""
  local script_root="${_IR_SCRIPT_ROOT:-}"
  if [ -n "$script_root" ] && git -C "$script_root" rev-parse --is-inside-work-tree &>/dev/null; then
    version="$(git -C "$script_root" describe --tags --dirty 2>/dev/null)" || true
    source="git"
    source_ref="$(git -C "$script_root" rev-parse HEAD 2>/dev/null)" || true
  elif [ -n "$script_root" ] && [ -f "$script_root/VERSION" ]; then
    version="$(<"$script_root/VERSION")"
    source="tarball"
  else
    source="tarball"
  fi
  version="${version:-unknown}"

  local nix_ver=""
  nix_ver="$(nix --version 2>/dev/null)" || true

  if command -v jq &>/dev/null; then
    local scopes_json="[]"
    if [ -n "${_IR_SCOPES:-}" ]; then
      # shellcheck disable=SC2086  # intentional word splitting
      scopes_json="$(printf '%s\n' $_IR_SCOPES | jq -R 'select(length > 0)' | jq -sc .)" || scopes_json="[]"
    fi

    jq -n \
      --arg entry_point "$entry_point" \
      --arg version "$version" \
      --arg source "$source" \
      --arg source_ref "${source_ref:-}" \
      --argjson scopes "$scopes_json" \
      --arg installed_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg installed_by "$(id -un)" \
      --arg platform "${_IR_PLATFORM:-unknown}" \
      --arg arch "$(uname -m)" \
      --arg mode "${_IR_MODE:-unknown}" \
      --arg status "$status" \
      --arg phase "$phase" \
      --arg error "$error" \
      --arg nix_version "${nix_ver:-}" \
      --arg shell "${SHELL:-}" \
      '{
        entry_point: $entry_point,
        version: $version,
        source: $source,
        source_ref: $source_ref,
        scopes: $scopes,
        installed_at: $installed_at,
        installed_by: $installed_by,
        platform: $platform,
        arch: $arch,
        mode: $mode,
        status: $status,
        phase: $phase,
        error: $error,
        nix_version: $nix_version,
        shell: $shell
      }' >"$DEV_ENV_DIR/install.json" 2>/dev/null
  else
    # fallback: write minimal JSON without jq (early failures)
    cat >"$DEV_ENV_DIR/install.json" <<IREOF
{
  "entry_point": "$entry_point",
  "version": "$version",
  "source": "$source",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "installed_by": "$(id -un)",
  "platform": "${_IR_PLATFORM:-unknown}",
  "arch": "$(uname -m)",
  "status": "$status",
  "phase": "$phase"
}
IREOF
  fi
}
