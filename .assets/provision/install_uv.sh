#!/usr/bin/env bash
: '
.assets/provision/install_uv.sh >/dev/null
'
set -euo pipefail

if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='uv'
REL=${1:-}
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'astral-sh' --repo 'uv')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if [ -x "$HOME/.local/bin/uv" ]; then
  VER="$($HOME/.local/bin/uv self version | sed -En 's/.*\s([0-9\.]+)/\1/p')"
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  else
    # update uv using the self update command
    printf "\e[92mupdating \e[1m$APP\e[22m\n" >&2
    # retry uv self update up to 5 times if it fails
    retry_count=0
    max_retries=5
    while [ $retry_count -le $max_retries ]; do
      $HOME/.local/bin/uv self update --native-tls >&2
      [ $? -eq 0 ] && break || true
      ((retry_count++)) || true
      echo "retrying... $retry_count/$max_retries" >&2
      if [ $retry_count -eq $max_retries ]; then
        printf "\e[31mFailed to update $APP after $max_retries attempts.\e[0m\n" >&2
        exit 1
      fi
    done
  fi
fi

# check if the binary is already installed
printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -d -p "$HOME")
trap 'rm -fr "$TMP_DIR"' EXIT
# calculate download uri
URL="https://astral.sh/uv/install.sh"
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  retry_count=0
  while [ ! -x "$HOME/.local/bin/uv" ] && [ $retry_count -lt 10 ]; do
    sh "$TMP_DIR/install.sh"
    ((retry_count++)) || true
  done
fi
exit 0
