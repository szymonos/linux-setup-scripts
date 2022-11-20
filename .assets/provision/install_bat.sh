#!/bin/bash
: '
sudo .assets/provision/install_bat.sh
'

APP='bat'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/sharkdp/bat/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [ -n "$REL" ] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(bat --version | grep -Po '(?<=^bat )[\d\.]+')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m" >&2
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*\K(alpine|arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  apk add --no-cache bat >&2 2>/dev/null
  ;;
arch)
  pacman -Sy --needed --noconfirm bat >&2 2>/dev/null
  ;;
fedora)
  dnf install -y bat >&2 2>/dev/null
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  while [[ ! -f bat.deb ]]; do
    curl -Lsk -o bat.deb "https://github.com/sharkdp/bat/releases/download/v${REL}/bat_${REL}_amd64.deb"
  done
  dpkg -i bat.deb >&2 2>/dev/null && rm -f bat.deb
  ;;
opensuse)
  zypper in -y bat >&2 2>/dev/null
  ;;
esac

if ! type $APP &>/dev/null; then
  echo 'Installing from binary.' >&2
  while [[ ! -d "bat-v${REL}-x86_64-unknown-linux-gnu" ]]; do
    curl -Lsk "https://github.com/sharkdp/bat/releases/download/v${REL}/bat-v${REL}-x86_64-unknown-linux-gnu.tar.gz" | tar -zx
  done
  install -o root -g root -m 0755 "bat-v${REL}-x86_64-unknown-linux-gnu/bat" /usr/bin/bat
  rm -fr "bat-v${REL}-x86_64-unknown-linux-gnu"
fi
