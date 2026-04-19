#!/usr/bin/env bash
: '
# https://docs.determinate.systems/ds-nix/how-to/install/
sudo .assets/provision/install_base_nix.sh  # install curl and build tools first
sudo .assets/provision/install_nix.sh
# :single-user install (no daemon, for Coder/containers)
sudo .assets/provision/install_nix.sh --no-daemon
# :uninstall (multi-user)
sudo /nix/nix-installer uninstall --no-confirm
# :uninstall (single-user)
# rm -rf /nix ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.config/nix
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

APP='nix'
no_daemon=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  --no-daemon) no_daemon=true ;;
  *) printf '\e[31;1mUnknown option: %s\e[0m\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

# check if nix is already installed
if [ -d /nix/store ]; then
  nix_bin=""
  if [ -x /nix/var/nix/profiles/default/bin/nix ]; then
    nix_bin=/nix/var/nix/profiles/default/bin/nix
  elif [ -n "${SUDO_USER:-}" ]; then
    user_nix="$(getent passwd "$SUDO_USER" | cut -d: -f6)/.nix-profile/bin/nix"
    [ -x "$user_nix" ] && nix_bin="$user_nix"
  fi
  if [ -n "$nix_bin" ]; then
    VER=$("$nix_bin" --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' || true)
    if [ -n "$VER" ]; then
      printf "\e[32m$APP v$VER is already installed\e[0m\n" >&2
      exit 0
    fi
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[0m\n" >&2

if [ "$no_daemon" = true ]; then
  # Single-user install via upstream Nix installer (no daemon, no root at runtime).
  # Intended for Coder workspaces and containers where running a root daemon
  # is undesirable. The user owns /nix directly and nix commands access the
  # store without a daemon.
  if [ -z "${SUDO_USER:-}" ]; then
    printf '\e[31;1m--no-daemon requires running via sudo (need SUDO_USER).\e[0m\n' >&2
    exit 1
  fi
  user_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  # create /nix owned by the calling user
  mkdir -p /nix
  chown "$SUDO_USER" /nix
  # enable flakes and disable sandbox (containers lack namespace support)
  nix_conf="$user_home/.config/nix/nix.conf"
  mkdir -p "$(dirname "$nix_conf")"
  cat >"$nix_conf" <<'NIXCONF'
experimental-features = nix-command flakes
sandbox = false
NIXCONF
  chown -R "$SUDO_USER" "$(dirname "$nix_conf")"
  # run upstream installer as the calling user
  su - "$SUDO_USER" -c "curl -sL https://nixos.org/nix/install | sh -s -- --no-daemon"
else
  # Multi-user install via Determinate Systems installer:
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
fi
