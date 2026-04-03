#!/usr/bin/env bash
: '
# https://docs.determinate.systems/ds-nix/how-to/install/
sudo .assets/provision/install_nix.sh
# :uninstall
sudo /nix/nix-installer uninstall --no-confirm
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

APP='nix'

# check if nix is already installed
if [ -d /nix/store ] && [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  VER=$(/nix/var/nix/profiles/default/bin/nix --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' || true)
  if [ -n "$VER" ]; then
    printf "\e[32m$APP v$VER is already installed\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[0m\n" >&2
# Use the Determinate Systems installer:
# - Enables flakes and nix-command by default
# - Works on Linux (all major distros), WSL, and macOS (including Apple Silicon)
# - Provides an uninstaller (/nix/nix-installer uninstall)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
