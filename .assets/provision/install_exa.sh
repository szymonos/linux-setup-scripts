#!/usr/bin/env bash
: '
sudo .assets/provision/install_exa.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='exa'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/ogham/exa/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(exa --version | grep -Po '(?<=^v)[\d\.]+')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m" >&2
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(alpine|arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  apk add --no-cache exa >&2 2>/dev/null
  ;;
arch)
  pacman -Sy --needed --noconfirm exa >&2 2>/dev/null || binary=true
  ;;
fedora)
  dnf install -y exa >&2 2>/dev/null || binary=true
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update >&2 && apt-get install -y exa >&2 2>/dev/null || binary=true
  ;;
opensuse)
  zypper in -y exa >&2 2>/dev/null || binary=true
  ;;
*)
  binary=true
esac

if [[ $binary ]]; then
  echo 'Installing from binary.' >&2
  TMP_DIR=$(mktemp -dp "$PWD")
  while [[ ! -f $TMP_DIR/exa-linux-x86_64.zip ]]; do
    curl -Lsk -o $TMP_DIR/exa-linux-x86_64.zip "https://github.com/ogham/exa/releases/download/v${REL}/exa-linux-x86_64-v${REL}.zip"
  done
  unzip -q $TMP_DIR/exa-linux-x86_64.zip -d $TMP_DIR
  install -o root -g root -m 0755 $TMP_DIR/bin/exa /usr/bin/exa
  mv -f $TMP_DIR/man/* $(manpath | cut -d : -f 1)/man1 &>/dev/null
  mv -f $TMP_DIR/completions/exa.bash /etc/bash_completion.d &>/dev/null
  rm -fr $TMP_DIR
fi
