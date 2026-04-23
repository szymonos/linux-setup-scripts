#!/usr/bin/env bash
# Post-install starship prompt configuration (cross-platform, Nix variant)
# The config is always at a fixed path (~/.config/starship.toml).
: '
# reconfigure with the existing theme
nix/configure/starship.sh
# set a specific theme
nix/configure/starship.sh base
nix/configure/starship.sh nerd
nix/configure/starship.sh omp_base
nix/configure/starship.sh omp_nerd
'
# Shell rc files point to this path once; config changes just replace the file.
set -eo pipefail

starship_theme="${1:-}"

info() { printf "\e[96m%s\e[0m\n" "$*"; }
ok() { printf "\e[32m%s\e[0m\n" "$*"; }
warn() { printf "\e[33m%s\e[0m\n" "$*" >&2; }

if ! command -v starship &>/dev/null; then
  exit 0
fi

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# -- Fixed config path ---------------------------------------------------------
STARSHIP_CFG="$HOME/.config/starship.toml"

# -- Install/update config file ------------------------------------------------
if [[ -n "$starship_theme" ]]; then
  info "setting starship theme to '$starship_theme'..."
  theme_src="$SCRIPT_ROOT/.assets/config/starship_cfg/${starship_theme}.toml"
  if [[ -f "$theme_src" ]]; then
    cp -f "$theme_src" "$STARSHIP_CFG"
    ok "installed starship theme '$starship_theme' to $STARSHIP_CFG"
  else
    warn "starship theme '$starship_theme' not found"
    exit 1
  fi
elif [[ ! -f "$STARSHIP_CFG" ]]; then
  # no theme specified and no existing config - install default (base)
  if [[ -f "$SCRIPT_ROOT/.assets/config/starship_cfg/base.toml" ]]; then
    cp -f "$SCRIPT_ROOT/.assets/config/starship_cfg/base.toml" "$STARSHIP_CFG"
    ok "installed default starship theme (base) to $STARSHIP_CFG"
  fi
fi
