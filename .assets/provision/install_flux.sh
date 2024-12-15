#!/usr/bin/env bash
: '
sudo .assets/provision/install_flux.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='flux'
REL=$1
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'fluxcd' --repo 'flux2')"
  [ -n "$REL" ] || exit 1
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  VER=$(flux --version | sed -En 's/.*\s([0-9\.]+)/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

__install="curl -sk https://fluxcd.io/install.sh | bash"
if type $APP &>/dev/null; then
  eval $__install
else
  retry_count=0
  while ! type $APP &>/dev/null && [ $retry_count -lt 10 ]; do
    eval $__install
    ((retry_count++))
  done
fi

exit 0
