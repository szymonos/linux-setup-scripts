#!/usr/bin/env bash
: '
sudo .assets/provision/install_yq.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='yq'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/mikefarah/yq/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(yq --version | grep -Po '[\d\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m" >&2
while [[ ! -f yq_linux_amd64 ]]; do
  curl -Lsk "https://github.com/mikefarah/yq/releases/download/v${REL}/yq_linux_amd64.tar.gz" | tar -zx ./yq_linux_amd64
done
install -o root -g root -m 0755 yq_linux_amd64 /usr/local/bin/yq && rm -f yq_linux_amd64
