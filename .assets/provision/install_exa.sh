#!/usr/bin/env bash
: '
sudo .assets/provision/install_exa.sh >/dev/null
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='exa'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/ogham/exa/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  ((retry_count++))
  if [[ $retry_count -eq 10 ]]; then
    echo -e "\e[33m$APP version couldn't be retrieved\e[0m" >&2
    exit 0
  fi
  [[ -n "$REL" || $i -eq 10 ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(exa --version | grep -Po '(?<=^v)[\d\.]+')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[32m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[92minstalling $APP v$REL\e[0m" >&2
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
  ;;
esac

if [[ "$binary" = true ]]; then
  echo 'Installing from binary.' >&2
  TMP_DIR=$(mktemp -dp "$PWD")
  retry_count=0
  while [[ ! -f $TMP_DIR/exa-linux-x86_64.zip && $retry_count -lt 10 ]]; do
    curl -Lsk -o $TMP_DIR/exa-linux-x86_64.zip "https://github.com/ogham/exa/releases/download/v${REL}/exa-linux-x86_64-v${REL}.zip"
    ((retry_count++))
  done
  unzip -q $TMP_DIR/exa-linux-x86_64.zip -d $TMP_DIR
  install -o root -g root -m 0755 $TMP_DIR/bin/exa /usr/bin/
  install -o root -g root -m 0644 $TMP_DIR/man/exa.1 $(manpath | cut -d : -f 1)/man1/
  install -o root -g root -m 0644 $TMP_DIR/man/exa_colors.5 $(manpath | cut -d : -f 1)/man5/
  install -o root -g root -m 0644 $TMP_DIR/completions/exa.bash /etc/bash_completion.d/
  rm -fr $TMP_DIR
fi
