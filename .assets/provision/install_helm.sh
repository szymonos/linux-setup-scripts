#!/usr/bin/env bash
: '
sudo .assets/provision/install_helm.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

APP='helm'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/helm/helm/releases/latest | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    printf "\e[33m$APP version couldn't be retrieved\e[0m\n" >&2
    exit 0
  fi
  [ -n "$REL" ] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(helm version | sed -En 's/.*v([0-9\.]+).*/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling $APP v$REL\e[0m\n" >&2
__install="curl -sk 'https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3' | bash"
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
