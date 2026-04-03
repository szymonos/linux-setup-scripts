#!/usr/bin/env bash
# Post-install Azure CLI configuration (cross-platform, Nix variant)
set -euo pipefail

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }
warn()  { printf "\e[33m%s\e[0m\n" "$*" >&2; }

info "configuring Azure CLI defaults..."
if command -v az &>/dev/null; then
  az config set core.output=jsonc 2>/dev/null || true
  az config set extension.dynamic_install_allow_preview=true 2>/dev/null || true
  ok "Azure CLI configured"
else
  warn "az binary not found; ensure Nix profile bin is in PATH"
fi
