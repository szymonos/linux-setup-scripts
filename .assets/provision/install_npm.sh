#!/bin/bash
: '
sudo .assets/provision/install_npm.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script with sudo!\e[0m'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(alpine|arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  apk add --no-cache npm
  ;;
arch)
  pacman -Sy --noconfirm icu npm
  ;;
fedora)
  dnf install -y npm
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y npm
  ;;
opensuse)
  zypper in -y npm
  ;;
esac
