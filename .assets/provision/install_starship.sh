#!/usr/bin/env bash
: '
sudo .assets/provision/install_starship.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='starship'
REL=$1

# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'starship' --repo 'starship')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if [ -x /usr/local/bin/starship ] &>/dev/null; then
  VER=$($APP --version | sed -En 's/.*\s([0-9\.]+)/\1/p' | head -1)
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2

curl -sS https://starship.rs/install.sh | sh -s -- --yes >/dev/null 2>&1
