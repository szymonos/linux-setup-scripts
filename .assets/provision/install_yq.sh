#!/bin/bash
: '
sudo .assets/provision/install_yq.sh
'

APP='yq'
while [[ -z $REL ]]; do
  REL=$(curl -sk https://api.github.com/repos/mikefarah/yq/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
done

if type $APP &>/dev/null; then
  VER=$(yq --version | grep -Po '(?<=version )[\d\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m"
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m"
while [[ ! -f yq_linux_amd64 ]]; do
  curl -Lsk "https://github.com/mikefarah/yq/releases/download/v${REL}/yq_linux_amd64.tar.gz" | tar -zx ./yq_linux_amd64
done
install -o root -g root -m 0755 yq_linux_amd64 /usr/local/bin/yq && rm -f yq_linux_amd64
