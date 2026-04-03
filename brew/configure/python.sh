#!/usr/bin/env bash
# Post-install Python tools - uv and prek (cross-platform, user-level)
set -euo pipefail

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }

# uv
if [[ -x "$HOME/.local/bin/uv" ]]; then
  ok "uv is already installed, updating..."
  "$HOME/.local/bin/uv" self update --native-tls || true
else
  info "installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# prek
if [[ -x "$HOME/.local/bin/prek" ]]; then
  ok "prek is already installed, updating..."
  "$HOME/.local/bin/prek" self update || true
else
  info "installing prek..."
  curl -LsSf https://github.com/j178/prek/releases/latest/download/prek-installer.sh | sh
fi
