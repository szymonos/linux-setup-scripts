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

# ensure minimal system dependencies needed by root-level provision scripts
ensure_sys_deps() {
  for cmd in curl jq; do
    command -v "$cmd" &>/dev/null && continue
    printf "\e[92minstalling system dependency: \e[1m%s\e[0m\n" "$cmd" >&2
    if command -v apt-get &>/dev/null; then
      apt-get update -qq && apt-get install -y -qq "$cmd"
    elif command -v dnf &>/dev/null; then
      dnf install -y -q "$cmd"
    elif command -v zypper &>/dev/null; then
      zypper --non-interactive --no-refresh in -y "$cmd"
    elif command -v apk &>/dev/null; then
      apk add --no-cache "$cmd"
    elif command -v pacman &>/dev/null; then
      pacman -Sy --needed --noconfirm "$cmd"
    else
      printf "\e[33mCannot install %s - unknown package manager\e[0m\n" "$cmd" >&2
    fi
  done
}

ensure_sys_deps

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
install_args=(install)
# detect environments without systemd (Docker, Coder, CI runners)
if [ "$(uname -s)" = "Linux" ] && ! pidof systemd &>/dev/null; then
  install_args+=(linux --init none)
fi
install_args+=(--no-confirm)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- "${install_args[@]}"
