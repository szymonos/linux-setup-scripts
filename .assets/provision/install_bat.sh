#!/bin/bash
: '
sudo .assets/provision/install_bat.sh
'

APP='bat'
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/sharkdp/bat/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [ -n "$REL" ] || echo 'retrying...'
done

if type $APP &>/dev/null; then
  VER=$(bat --version | grep -Po '(?<=^bat )[\d\.]+')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m"
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m"
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

INSTALLED=false
case $SYS_ID in
arch)
  pacman -Sy --needed --noconfirm bat && INSTALLED=true
  ;;
fedora)
  dnf install -y bat && INSTALLED=true
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  while [[ ! -f bat.deb ]]; do
    curl -Lsk -o bat.deb "https://github.com/sharkdp/bat/releases/download/v${REL}/bat_${REL}_amd64.deb"
  done
  dpkg -i bat.deb && rm -f bat.deb && INSTALLED=true
  ;;
opensuse)
  zypper in -y bat && INSTALLED=true
  ;;
esac
$INSTALLED && exit 0

# install from binary if above didn't work
while [[ ! -d "bat-v${REL}-x86_64-unknown-linux-gnu" ]]; do
  curl -Lsk "https://github.com/sharkdp/bat/releases/download/v${REL}/bat-v${REL}-x86_64-unknown-linux-gnu.tar.gz" | tar -zx
done
install -o root -g root -m 0755 "bat-v${REL}-x86_64-unknown-linux-gnu/bat" /usr/bin/bat && rm -fr "bat-v${REL}-x86_64-unknown-linux-gnu"
