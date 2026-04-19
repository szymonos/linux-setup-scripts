#!/usr/bin/env bash
: '
sudo .assets/provision/install_base_nix.sh
Install minimal system dependencies (curl, build tools) for the Nix setup path.
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# skip on macOS - Xcode Command Line Tools provide these (xcode-select --install)
[ "$(uname -s)" = "Darwin" ] && exit 0

SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

printf "\e[92minstalling \e[1msystem dependencies\e[0m\n" >&2
case ${SYS_ID:-} in
alpine)
  apk add --no-cache build-base curl jq
  ;;
arch)
  pacman -Sy --needed --noconfirm base-devel curl jq
  ;;
fedora)
  dnf install -y -q curl jq make gcc
  ;;
debian | ubuntu)
  apt-get update -qq && apt-get install -y -qq build-essential curl jq
  ;;
opensuse)
  zypper --non-interactive --no-refresh in -y curl jq make gcc
  ;;
*)
  printf '\e[33mUnsupported distro, skipping system deps install.\e[0m\n' >&2
  ;;
esac
