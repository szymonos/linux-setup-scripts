#!/bin/bash
: '
sudo .assets/provision/install_omp.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script with sudo!\e[0m'
  exit 1
fi

APP='oh-my-posh'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(oh-my-posh version)
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m" >&2
while [[ ! -f posh-linux-amd64 ]]; do
  curl -LsOk "https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v${REL}/posh-linux-amd64"
done
install -o root -g root -m 0755 posh-linux-amd64 /usr/bin/oh-my-posh && rm -f posh-linux-amd64
