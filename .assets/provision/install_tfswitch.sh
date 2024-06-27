#!/usr/bin/env bash
: '
sudo .assets/provision/install_tfswitch.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='tfswitch'
REL=$1
retry_count=0
# get latest release if not provided as a parameter
[ -z "$REL" ] && REL="$(get_gh_release_latest --owner 'warrensbox' --repo 'terraform-switcher')"
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$($APP --version | sed -En 's/.*\sv?([0-9\.]+)/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
__install="curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash"
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
