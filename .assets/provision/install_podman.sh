#!/usr/bin/env bash
: '
sudo .assets/provision/install_podman.sh
'
if [ $EUID -ne 0 ]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(alpine|arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  apk add --no-cache podman
  ;;
arch)
  pacman -Sy --needed --noconfirm podman
  ;;
fedora)
  dnf install -y podman
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y podman
  ;;
opensuse)
  zypper in -y podman
  ;;
esac
