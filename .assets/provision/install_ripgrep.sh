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
esac

if ! type rg &>/dev/null; then
  while [[ ! -f kubectl-argo-rollouts-linux-amd64 ]]; do
    curl -Lsk -o ripgrep.tgz "https://github.com/BurntSushi/ripgrep/releases/download/${REL}/ripgrep-${REL}-x86_64-unknown-linux-musl.tar.gz"
  done
  tar zxf ripgrep.tgz
  install -o root -g root -m 0755 "ripgrep-${REL}-x86_64-unknown-linux-musl/rg" /usr/bin/rg
  mv -f "ripgrep-${REL}-x86_64-unknown-linux-musl/doc/rg.1" $(manpath | cut -d : -f 1)/man1 &>/dev/null
  mv -f "ripgrep-${REL}-x86_64-unknown-linux-musl/complete/rg.bash" /etc/bash_completion.d &>/dev/null
  rm -fr ripgrep*
fi
