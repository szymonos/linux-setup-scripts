#!/bin/bash
: '
sudo .assets/provision/install_k3d.sh
'

APP='k3d'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/k3d-io/k3d/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [ -n "$REL" ] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(k3d --version | grep -Po '(?<=v)[\d\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m" >&2
while
  curl -sk 'https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh' | bash >&2
  [[ $(k3d --version 2>/dev/null | grep -Po '(?<=v)[\d\.]+$') != $REL ]]
do :; done
