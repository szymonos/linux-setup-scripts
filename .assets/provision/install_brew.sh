#!/usr/bin/env bash
: '
# https://docs.brew.sh/Installation
.assets/provision/install_brew.sh >/dev/null
'
if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='brew'
REL=$1
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'Homebrew' --repo 'brew')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if type brew &>/dev/null; then
  VER=$(brew --version | grep -Eo '[0-9\.]+\.[0-9]+\.[0-9]+')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  else
    brew update
  fi
else
  printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
  # unattended installation
  export NONINTERACTIVE=1
  # skip tap cloning
  export HOMEBREW_INSTALL_FROM_API=1
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -d -p "$HOME")
  trap 'rm -rf "${TMP_DIR:-}" >/dev/null 2>&1 || true' EXIT
  # calculate download uri
  URL="https://raw.githubusercontent.com/Homebrew/install/master/install.sh"
  # download and install homebrew
  if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
    bash -c "$TMP_DIR/$(basename \"$URL\")"
  fi
  # temporary dir cleaned by trap
  rm -rf "${TMP_DIR:-}" >/dev/null 2>&1 || true
  trap - EXIT
fi
