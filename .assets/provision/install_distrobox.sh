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
  apk add --no-cache distrobox
  ;;
arch)
  sudo -u $(id -un 1000) paru -Sy --needed --noconfirm distrobox
  ;;
fedora)
  dnf install -y distrobox
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  add-apt-repository -y ppa:michel-slm/distrobox
  apt-get update && apt-get install -y distrobox
  ;;
opensuse)
  zypper in -y distrobox
  ;;
esac
