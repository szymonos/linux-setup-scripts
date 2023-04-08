#!/usr/bin/env bash
: '
sudo .assets/provision/install_k3d.sh >/dev/null
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='k3d'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/k3d-io/k3d/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  ((retry_count++))
  if [[ $retry_count -eq 10 ]]; then
    echo -e "\e[33m$APP version couldn't be retrieved\e[0m" >&2
    exit 0
  fi
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(k3d --version | grep -Po '(?<=v)[0-9\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[32m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[92minstalling $APP v$REL\e[0m" >&2
retry_count=0
while
  curl -sk 'https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh' | bash >&2
  ((retry_count++))
  [[ $(k3d --version 2>/dev/null | grep -Po '(?<=v)[0-9\.]+$') != $REL && $retry_count -le 10 ]]
do :; done
