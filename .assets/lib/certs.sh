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
# Creates ~/.config/certs/ca-bundle.crt as a PEM bundle for nix-installed tools.
# Linux: symlinks to system CA bundle (requires ca-custom.crt to exist, since
#        the system bundle already includes custom certs after update-ca-certificates).
# macOS: exports all trusted certificates from macOS Keychains (system roots +
#        admin-installed corporate/proxy certs). No ca-custom.crt required -
#        the Keychain is the authoritative trust store on macOS.
# Idempotent: skips if ca-bundle.crt already exists.
build_ca_bundle() {
  local cert_dir="$HOME/.config/certs"
  local custom_certs="$cert_dir/ca-custom.crt"
  local bundle_link="$cert_dir/ca-bundle.crt"

  [ ! -e "$bundle_link" ] || return 0

  mkdir -p "$cert_dir"
  case "$(uname -s)" in
  Linux)
    [ -f "$custom_certs" ] || return 0
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
    local bundle_tmp
    bundle_tmp="$(mktemp)"
    # Export all trusted certs from macOS Keychains (includes corporate/proxy CAs)
    security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain >"$bundle_tmp" 2>/dev/null
    security find-certificate -a -p /Library/Keychains/System.keychain >>"$bundle_tmp" 2>/dev/null
    # Append any manually intercepted certs
    [ -f "$custom_certs" ] && cat "$custom_certs" >>"$bundle_tmp"
    if [ -s "$bundle_tmp" ]; then
      mv -f "$bundle_tmp" "$bundle_link"
      ok "  created ca-bundle.crt from macOS Keychain"
    else
      rm -f "$bundle_tmp"
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
