#!/usr/bin/env bash
# Post-install conda/miniforge + pixi configuration (cross-platform)
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }
warn()  { printf "\e[33m%s\e[0m\n" "$*" >&2; }

find_conda() {
  local candidates=(
    "$HOME/miniforge3/bin/conda"
    "/opt/homebrew/Caskroom/miniforge/base/bin/conda"
    "/opt/homebrew/Caskroom/miniforge/base/condabin/conda"
    "/usr/local/Caskroom/miniforge/base/bin/conda"
    "/usr/local/Caskroom/miniforge/base/condabin/conda"
  )
  # on Linux, brew installs miniforge differently
  local brew_prefix
  if command -v brew &>/dev/null; then
    brew_prefix="$(brew --prefix)"
    candidates+=(
      "$brew_prefix/Caskroom/miniforge/base/bin/conda"
      "$brew_prefix/Caskroom/miniforge/base/condabin/conda"
    )
  fi
  for c in "${candidates[@]}"; do
    if [[ -x "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  if command -v conda &>/dev/null; then
    command -v conda
    return 0
  fi
  return 1
}

# miniforge post-install
conda_bin="$(find_conda || true)"
if [[ -n "$conda_bin" ]]; then
  # fix certifi certificates before update (handles MITM proxy certs)
  "$SCRIPT_ROOT/.assets/fix/fix_certifi_certs.sh" || true
  info "updating conda..."
  "$conda_bin" update --name base --channel conda-forge conda --yes --update-all 2>/dev/null || warn "conda update failed"
  # fix certifi certificates after update (update may replace cacert.pem)
  "$SCRIPT_ROOT/.assets/fix/fix_certifi_certs.sh" || true
  "$conda_bin" clean --yes --all 2>/dev/null || true
  # initialize shell integration and disable auto-activate
  "$conda_bin" init bash zsh 2>/dev/null || true
  "$conda_bin" config --set auto_activate_base false
  ok "conda configured"
else
  warn "conda binary not found after miniforge install"
fi

# pixi
if [[ -x "$HOME/.pixi/bin/pixi" ]]; then
  ok "pixi is already installed, updating..."
  "$HOME/.pixi/bin/pixi" self-update || true
else
  info "installing pixi..."
  curl -fsSL https://pixi.sh/install.sh | sh
fi
