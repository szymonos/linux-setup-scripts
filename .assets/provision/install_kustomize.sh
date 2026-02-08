#!/usr/bin/env bash
: '
sudo .assets/provision/install_kustomize.sh >/dev/null
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='kustomize'
REL=${1:-}
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'kubernetes-sigs' --repo 'kustomize')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  VER="$(kustomize version | sed -En 's/.*v([0-9\.]+)$/\1/p')"
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP $VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$HOME")
# calculate download uri
URL='https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh'
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  bash -C "$TMP_DIR/$(basename $URL)"
  install -m 0755 kustomize /usr/bin/
fi
# remove temporary dir
rm -fr kustomize "$TMP_DIR"
