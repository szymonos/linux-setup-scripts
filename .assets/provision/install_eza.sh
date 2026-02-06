#!/usr/bin/env bash
: '
sudo .assets/provision/install_eza.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='eza'
case $SYS_ID in
alpine)
  apk -e info $APP &>/dev/null && exit 0 || true
  ;;
arch)
  pacman -Qqe $APP &>/dev/null && exit 0 || true
  ;;
fedora)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
debian)
  dpkg -s $APP &>/dev/null && exit 0 || true
  ;;
ubuntu)
  dpkg -s $APP &>/dev/null && exit 0 || true
  ;;
opensuse)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
esac

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
REL=$1
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'eza-community' --repo 'eza')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo "$REL"

if type $APP &>/dev/null; then
  VER=$(eza --version | sed -En 's/v([0-9\.]+).*/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[0m\n" >&2
case $SYS_ID in
alpine)
  if ! apk add --no-cache "$APP" >/dev/null 2>&1; then
    binary=true
    lib='musl'
  fi
  ;;
arch)
  if ! pacman -Sy --needed --noconfirm "$APP" >/dev/null 2>&1; then
    binary=true
    lib='gnu'
  fi
  ;;
fedora)
  if ! dnf install -y "$APP" >/dev/null 2>&1; then
    binary=true
    lib='gnu'
  fi
  ;;
debian)
  export DEBIAN_FRONTEND=noninteractive
  mkdir -p /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/gierens.gpg ]; then
    curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc 2>/dev/null | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  fi
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" >/etc/apt/sources.list.d/gierens.list
  chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  if ! (apt-get update >/dev/null 2>&1 && apt-get install -y "$APP" >/dev/null 2>&1); then
    binary=true
    lib='gnu'
  fi
  ;;
ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  if ! (apt-get update >/dev/null 2>&1 && apt-get install -y "$APP" >/dev/null 2>&1); then
    binary=true
    lib='gnu'
  fi
  ;;
opensuse)
  if ! zypper --non-interactive in -y "$APP" >/dev/null 2>&1; then
    binary=true
    lib='gnu'
  fi
  ;;
*)
  binary=true
  lib='gnu'
  ;;
esac

if [ "${binary:-}" = true ] && [ -n "$REL" ]; then
  printf "Installing $APP \e[1mv$REL\e[22m from binary.\n" >&2
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -d -p "$HOME")
  trap 'rm -rf "${TMP_DIR:-}" >/dev/null 2>&1 || true' EXIT
  # calculate download uri
  URL="https://github.com/eza-community/eza/releases/download/v${REL}/eza_x86_64-unknown-linux-${lib}.tar.gz"
  # download and install file
  if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
    tar -zxf "$TMP_DIR/$(basename \"$URL\")" -C "$TMP_DIR"
    install -m 0755 "$TMP_DIR/eza" /usr/bin/
  fi
  # temporary dir will be removed by trap
  rm -rf "${TMP_DIR:-}" >/dev/null 2>&1 || true
  trap - EXIT
fi
