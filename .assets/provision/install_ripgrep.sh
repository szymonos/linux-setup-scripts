#!/usr/bin/env bash
: '
sudo .assets/provision/install_ripgrep.sh >/dev/null
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# set binary flag if package manager is not supported
binary=false
# check if package installed already using package manager
APP='ripgrep'
case $SYS_ID in
alpine)
  apk -e info $APP &>/dev/null && exit 0 || true
  ;;
arch)
  pacman -Qqe $APP &>/dev/null && exit 0 || true
  ;;
fedora | opensuse)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
debian | ubuntu)
  dpkg -s $APP &>/dev/null && exit 0 || true
  ;;
esac

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
REL=${1:-}
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'BurntSushi' --repo 'ripgrep')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  VER=$(rg --version | sed -En 's/.*\s([0-9\.]+)/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
case $SYS_ID in
alpine)
  apk add --no-cache ripgrep >&2 2>/dev/null
  ;;
arch)
  pacman -Sy --needed --noconfirm ripgrep >&2 2>/dev/null || binary=true
  ;;
fedora)
  dnf install -y ripgrep >&2 2>/dev/null || binary=true
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update >&2 && apt-get install -y ripgrep >&2 2>/dev/null || binary=true
  ;;
opensuse)
  zypper --non-interactive in -y ripgrep >&2 2>/dev/null || binary=true
  ;;
*)
  binary=true
  ;;
esac

if [ "$binary" = true ] && [ -n "$REL" ]; then
  echo 'Installing from binary.' >&2
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -d -p "$HOME")
  trap 'rm -fr "$TMP_DIR"' EXIT
  # calculate download uri
  URL="https://github.com/BurntSushi/ripgrep/releases/download/${REL}/ripgrep-${REL}-aarch64-unknown-linux-gnu.tar.gz"
  # download and install file
  if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
    tar -zxf "$TMP_DIR/$(basename $URL)" --strip-components=1 -C "$TMP_DIR"
    install -m 0755 "$TMP_DIR/rg" /usr/bin/
    install -m 0644 "$TMP_DIR/doc/rg.1" "$(manpath | cut -d : -f 1)/man1/"
    install -m 0644 "$TMP_DIR/complete/rg.bash" /etc/bash_completion.d/
  fi
fi
