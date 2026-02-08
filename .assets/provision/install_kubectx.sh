#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubectx.sh >/dev/null
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='kubectx'
REL=${1:-}
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'ahmetb' --repo 'kubectx')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  VER=$(kubectx --version)
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -d -p "$HOME")
trap 'rm -fr "$TMP_DIR"' EXIT
# *install kubectx
# calculate download uri
URL="https://github.com/ahmetb/kubectx/releases/download/v${REL}/${APP}_v${REL}_linux_x86_64.tar.gz"
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  tar -zxf "$TMP_DIR/$(basename $URL)" -C "$TMP_DIR"
  mkdir -p /opt/$APP
  install -m 0755 "$TMP_DIR/$APP" /opt/$APP/
  [ -f /usr/bin/$APP ] || ln -s /opt/$APP/$APP /usr/bin/$APP
fi
# *install kubens
# calculate download uri
URL="https://github.com/ahmetb/kubectx/releases/download/v${REL}/kubens_v${REL}_linux_x86_64.tar.gz"
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  tar -zxf "$TMP_DIR/$(basename $URL)" -C "$TMP_DIR"
  install -m 0755 "$TMP_DIR/kubens" /opt/$APP/
  [ -f /usr/bin/kubens ] || ln -s /opt/$APP/kubens /usr/bin/kubens
fi
