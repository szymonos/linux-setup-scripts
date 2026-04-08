#!/usr/bin/env bash
# Post-install Azure CLI configuration (cross-platform, Nix variant)
# Azure CLI is installed via uv (not Nix) for better cross-platform compatibility.
# macOS uses native TLS (system keychain) - no certifi patching needed.
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_ROOT/../.." && pwd)"

info() { printf "\e[96m%s\e[0m\n" "$*"; }

info "installing azure-cli via uv..."
install_args=()
# on Linux/WSL, patch the certifi bundle with system CA certificates so az
# commands work behind a MITM proxy; macOS keychain integration is not supported
if [ "$(uname -s)" = "Linux" ]; then
  install_args+=(--fix_certify true)
fi
"$REPO_ROOT/.assets/provision/install_azurecli_uv.sh" "${install_args[@]}"
