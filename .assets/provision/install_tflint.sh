#!/usr/bin/env bash
: '
sudo .assets/provision/install_tflint.sh >/dev/null
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='tflint'
REL=${1:-}
OWNER='terraform-linters'
REPO='tflint'
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner $OWNER --repo $REPO)"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  VER=$($APP --version | sed -En 's/.* ([0-9\.]+)$/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -d -p "$HOME")
trap 'rm -fr "$TMP_DIR"' EXIT
# calculate download uri
URL="https://github.com/$OWNER/$REPO/releases/download/v${REL}/tflint_linux_amd64.zip"
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  unzip -q "$TMP_DIR/$(basename $URL)" -d "$TMP_DIR"
  install -m 0755 "$TMP_DIR/tflint" /usr/bin/
fi
