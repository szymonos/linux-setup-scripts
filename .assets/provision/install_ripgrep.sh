#!/usr/bin/env bash
: '
sudo .assets/provision/install_ripgrep.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='rg'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    echo -e "\e[33m$APP version couldn't be retrieved\e[0m" >&2
    exit 0
  fi
  [ -n "$REL" ] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(rg --version | grep -Po '(?<=^ripgrep )[0-9\.]+')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[32m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[92minstalling $APP v$REL\e[0m" >&2
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

if [ "$binary" = true ]; then
  echo 'Installing from binary.' >&2
  TMP_DIR=$(mktemp -dp "$PWD")
  retry_count=0
  while [[ ! -f $TMP_DIR/rg && $retry_count -lt 10 ]]; do
    curl -Lsk "https://github.com/BurntSushi/ripgrep/releases/download/${REL}/ripgrep-${REL}-x86_64-unknown-linux-musl.tar.gz" | tar -zx --strip-components=1 -C $TMP_DIR
    ((retry_count++))
  done
  install -o root -g root -m 0755 $TMP_DIR/rg /usr/bin/
  install -o root -g root -m 0644 $TMP_DIR/doc/rg.1 $(manpath | cut -d : -f 1)/man1/
  install -o root -g root -m 0644 $TMP_DIR/complete/rg.bash /etc/bash_completion.d/
  rm -fr $TMP_DIR
fi
