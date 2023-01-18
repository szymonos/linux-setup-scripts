#!/usr/bin/env bash
: '
sudo .assets/provision/install_ripgrep.sh >/dev/null
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='rg'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  [[ -n "$REL" ]] || echo 'retrying...' >&2
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
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(alpine|arch|centos|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  apk add --no-cache ripgrep >&2 2>/dev/null
  ;;
arch)
  pacman -Sy --needed --noconfirm ripgrep >&2 2>/dev/null || binary=true
  ;;
fedora)
  dnf install -y ripgrep >&2 2>/dev/null || binary=true
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update >&2 && apt-get install -y ripgrep >&2 2>/dev/null || binary=true
  ;;
opensuse)
  zypper in -y ripgrep >&2 2>/dev/null || binary=true
  ;;
*)
  binary=true
  ;;
esac

if [[ "$binary" = true ]]; then
  echo 'Installing from binary.' >&2
  TMP_DIR=$(mktemp -dp "$PWD")
  while [[ ! -f $TMP_DIR/rg ]]; do
    curl -Lsk "https://github.com/BurntSushi/ripgrep/releases/download/${REL}/ripgrep-${REL}-x86_64-unknown-linux-musl.tar.gz" | tar -zx -C $TMP_DIR
  done
  install -o root -g root -m 0755 $TMP_DIR/rg /usr/bin/rg
  mv -f $TMP_DIR/doc/rg.1 $(manpath | cut -d : -f 1)/man1 &>/dev/null
  mv -f $TMP_DIR/complete/rg.bash /etc/bash_completion.d &>/dev/null
  rm -fr $TMP_DIR
fi
