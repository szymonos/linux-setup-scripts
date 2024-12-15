#!/usr/bin/env bash
: '
.assets/provision/install_uv.sh >/dev/null
'
if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='uv'
REL=$1
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'astral-sh' --repo 'uv')"
  [ -n "$REL" ] || exit 1
fi
# return the release
echo $REL

if [ -x "$HOME/.local/bin/uv" ]; then
  VER="$($HOME/.local/bin/uv --version | sed -En 's/.*\s([0-9\.]+)/\1/p')"
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$PWD")
# calculate download uri
URL="https://astral.sh/uv/install.sh"
# download and install file
if download_file --uri $URL --target_dir $TMP_DIR; then
  retry_count=0
  while [ ! -x "$HOME/.local/bin/uv" ] && [ $retry_count -lt 10 ]; do
    sh "$TMP_DIR/install.sh"
    ((retry_count++))
  done
fi
# remove temporary dir
rm -fr "$TMP_DIR"

exit 0
