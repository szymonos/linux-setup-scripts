#!/bin/bash
: '
sudo .assets/provision/install_ripgrep.sh
'

APP='rg'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -Po '"tag_name": *"\K.*?(?=")')
  [ -n "$REL" ] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(rg --version | grep -Po '(?<=^ripgrep )[\d\.]+')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m" >&2
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*\K(alpine|arch|centos|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  apk add --no-cache exa >&2
  ;;
arch)
  pacman -Sy --needed --noconfirm ripgrep >&2
  ;;
fedora)
  dnf install -y ripgrep >&2
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update >&2 && apt-get install -y ripgrep >&2
  ;;
opensuse)
  zypper in -y ripgrep >&2
  ;;
*)
  echo 'ripgrep not available...' >&2
  ;;
esac
