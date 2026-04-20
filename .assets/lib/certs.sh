# Shared CA bundle builder and VS Code Server cert env setup.
# Compatible with bash 3.2 and zsh (sourced by nix and legacy setup paths).
#
# Usage:
#   source .assets/lib/certs.sh
#   build_ca_bundle     # creates ca-bundle.crt if ca-custom.crt exists
#   setup_vscode_certs  # writes NODE_EXTRA_CA_CERTS to server-env-setup
#
# Requires: ok() helper defined by caller (printf green line).

# Default TLS probe URL for MITM detection and cert interception.
: "${NIX_ENV_TLS_PROBE_URL:=https://www.google.com}"

# build_ca_bundle
# Creates ~/.config/certs/ca-bundle.crt when ca-custom.crt is present.
# Linux: symlinks to system CA bundle (which already contains custom certs
#        after update-ca-certificates).
# macOS: merges nix CA bundle with custom certs (system store not available
#        as a PEM file).
# Idempotent: skips if ca-bundle.crt already exists.
build_ca_bundle() {
  local cert_dir="$HOME/.config/certs"
  local custom_certs="$cert_dir/ca-custom.crt"
  local bundle_link="$cert_dir/ca-bundle.crt"

  [ -f "$custom_certs" ] || return 0
  [ ! -e "$bundle_link" ] || return 0

  mkdir -p "$cert_dir"
  case "$(uname -s)" in
  Linux)
    for sys_bundle in \
      /etc/ssl/certs/ca-certificates.crt \
      /etc/pki/tls/certs/ca-bundle.crt; do
      if [ -f "$sys_bundle" ]; then
        ln -sf "$sys_bundle" "$bundle_link"
        ok "  symlinked ca-bundle.crt -> $sys_bundle"
        break
      fi
    done
    ;;
  Darwin)
    local nix_bundle="$HOME/.nix-profile/etc/ssl/certs/ca-bundle.crt"
    if [ -f "$nix_bundle" ]; then
      cat "$nix_bundle" "$custom_certs" >"$bundle_link"
      ok "  created merged ca-bundle.crt (nix CAs + custom certs)"
    fi
    ;;
  esac
}

# setup_vscode_certs
# Writes NODE_EXTRA_CA_CERTS to ~/.vscode-server/server-env-setup so that
# VS Code Server (remote-SSH, WSL) picks up custom CA certs without needing
# a login shell. Creates the directory and file if they don't exist yet.
# Idempotent: updates the value if already present, appends otherwise.
setup_vscode_certs() {
  local cert_dir="$HOME/.config/certs"
  local custom_certs="$cert_dir/ca-custom.crt"
  local env_file="$HOME/.vscode-server/server-env-setup"

  [ -f "$custom_certs" ] || return 0

  mkdir -p "$HOME/.vscode-server"

  local export_line="export NODE_EXTRA_CA_CERTS=\"$custom_certs\""
  if [ -f "$env_file" ] && grep -q 'NODE_EXTRA_CA_CERTS' "$env_file" 2>/dev/null; then
    if ! grep -qF "$export_line" "$env_file" 2>/dev/null; then
      local tmp
      tmp="$(mktemp)"
      grep -v 'NODE_EXTRA_CA_CERTS' "$env_file" >"$tmp"
      printf '%s\n' "$export_line" >>"$tmp"
      mv -f "$tmp" "$env_file"
      ok "  updated NODE_EXTRA_CA_CERTS in $env_file"
    fi
  else
    printf '%s\n' "$export_line" >>"$env_file"
    ok "  added NODE_EXTRA_CA_CERTS to $env_file"
  fi
}
