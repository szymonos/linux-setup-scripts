#!/bin/bash
: '
sudo .assets/provision/install_ripgrep.sh
'

APP='rg'
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -Po '"tag_name": *"\K.*?(?=")')
  [ -n "$REL" ] || echo 'retrying...'
done

if type $APP &>/dev/null; then
  VER=$(rg --version | grep -Po '(?<=^ripgrep )[\d\.]+')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m"
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m"
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*\K(alpine|arch|centos|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  apk add --no-cache exa && INSTALLED=true
  ;;
arch)
  pacman -Sy --needed --noconfirm ripgrep
  ;;
fedora)
  dnf install -y ripgrep
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y ripgrep
  ;;
opensuse)
  zypper in -y ripgrep
  ;;
*)
  echo 'ripgrep not available...'
  ;;
esac
