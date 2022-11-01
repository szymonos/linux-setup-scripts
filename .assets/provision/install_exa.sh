#!/bin/bash
: '
sudo .assets/provision/install_exa.sh
'

APP='exa'
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/ogham/exa/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [ -n "$REL" ] || echo 'retrying...'
done

if type $APP &>/dev/null; then
  VER=$(exa --version | grep -Po '(?<=^v)[\d\.]+')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m"
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m"
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*\K(alpine|arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  apk add --no-cache exa
  ;;
arch)
  pacman -Sy --needed --noconfirm exa
  ;;
fedora)
  dnf install -y exa
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y exa
  ;;
opensuse)
  zypper in -y exa
  ;;
*)
  while [[ ! -f exa-linux-x86_64.zip ]]; do
    curl -Lsk -o exa-linux-x86_64.zip "https://github.com/ogham/exa/releases/download/v${REL}/exa-linux-x86_64-v${REL}.zip"
  done
  unzip exa-linux-x86_64.zip
  \mv -f bin/exa /usr/bin/exa
  \mv -f man/* $(manpath | cut -d : -f 1)/man1
  \mv -f completions/exa.bash /etc/bash_completion.d
  rm -fr bin completions man exa-linux-x86_64.zip
  ;;
esac
