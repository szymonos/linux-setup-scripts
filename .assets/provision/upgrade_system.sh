#!/bin/bash
: '
sudo .assets/provision/upgrade_system.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script with sudo!\e[0m'
  exit 1
fi

SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)
case $SYS_ID in
alpine)
  apk upgrade --available
  ;;
arch)
  pacman -Syu --noconfirm
  ;;
fedora)
  dnf upgrade -y
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get dist-upgrade -qy --allow-downgrades --allow-remove-essential --allow-change-held-packages
  ;;
opensuse)
  zypper dup -y
  ;;
esac
