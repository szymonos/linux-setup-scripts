#!/usr/bin/env bash
# Post-install conda/miniforge + pixi configuration (cross-platform, Nix variant)
# Nix does not package miniforge, so we install it via the official installer.
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }
warn()  { printf "\e[33m%s\e[0m\n" "$*" >&2; }

find_conda() {
  local candidates=(
    "$HOME/miniforge3/bin/conda"
    "$HOME/miniforge3/condabin/conda"
  )
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

# install miniforge if not present
if ! find_conda &>/dev/null; then
  info "installing Miniforge..."
  OS_NAME="$(uname -s)"
  ARCH="$(uname -m)"
  case "$OS_NAME" in
    Linux)  os_label="Linux" ;;
    Darwin) os_label="MacOSX" ;;
    *)      err "Unsupported OS: $OS_NAME"; exit 1 ;;
  esac
  MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-${os_label}-${ARCH}.sh"
  curl -fsSL "$MINIFORGE_URL" -o /tmp/miniforge.sh
  bash /tmp/miniforge.sh -b -p "$HOME/miniforge3"
  rm -f /tmp/miniforge.sh
fi

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
