#!/bin/bash
: '
sudo .assets/provision/upgrade_system.sh
'

SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)
case $SYS_ID in
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
