#!/usr/bin/env bash
: '
sudo .assets/provision/install_helm.sh >/dev/null
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='helm'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/helm/helm/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(helm version | grep -Po '(?<=Version:"v)[\d\.]+')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m" >&2
__install="curl -sk 'https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3' | bash"
if type $APP &>/dev/null; then
  eval $__install
else
  while ! type $APP &>/dev/null; do
    eval $__install
  done
fi
