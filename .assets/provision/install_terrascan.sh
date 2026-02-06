#!/usr/bin/env bash
: '
sudo .assets/provision/install_terrascan.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='terrascan'
REL=$1
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'tenable' --repo 'terrascan')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  VER=$($APP version | sed -En 's/.*\sv([0-9\.]+)/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -d -p "$HOME")
trap 'rm -rf "${TMP_DIR:-}" >/dev/null 2>&1 || true' EXIT
# calculate download uri
URL="https://github.com/tenable/terrascan/releases/download/v${REL}/terrascan_${REL}_Linux_x86_64.tar.gz"
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  tar -zxf "$TMP_DIR/$(basename \"$URL\")" -C "$TMP_DIR"
  install -m 0755 "$TMP_DIR/terrascan" /usr/bin/
fi
# remove temporary dir
rm -rf "${TMP_DIR:-}" >/dev/null 2>&1 || true
trap - EXIT
