#!/usr/bin/env bash
: '
sudo .assets/provision/install_k3d.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='k3d'
REL=$1
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'k3d-io' --repo 'k3d')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo "$REL"

if type $APP &>/dev/null; then
  VER=$(k3d --version | sed -En 's/.*v([0-9\.]+)$/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
retry_count=0
while
  curl -sk 'https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh' | bash >&2
  ((retry_count++))
  [[ $(k3d --version 2>/dev/null | sed -En 's/.*v([0-9\.]+)$/\1/p') != $REL && $retry_count -le 10 ]]
do :; done

exit 0
