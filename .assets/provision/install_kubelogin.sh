#!/bin/bash
: '
sudo .assets/provision/install_kubelogin.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script with sudo!\e[0m'
  exit 1
fi

APP='kubelogin'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/Azure/kubelogin/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(kubelogin --version | grep -Po '(?<=v)[\d\.]+(?=/)')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m" >&2
while [[ ! -f kubelogin-linux-amd64.zip ]]; do
  curl -LOsk "https://github.com/Azure/kubelogin/releases/download/v${REL}/kubelogin-linux-amd64.zip"
done
mkdir -p /tmp/kubelogin && unzip -q ./kubelogin-linux-amd64.zip -d /tmp/kubelogin
install -o root -g root -m 0755 /tmp/kubelogin/bin/linux_amd64/kubelogin /usr/local/bin/kubelogin
rm -fr /tmp/kubelogin kubelogin-linux-amd64.zip
