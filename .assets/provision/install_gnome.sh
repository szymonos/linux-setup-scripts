#!/bin/bash
: '
sudo .assets/provision/install_gnome.sh
'

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
arch)
  pacman -Sy --needed --noconfirm gnome gnome-extra
  systemctl enable gdm
  ;;
fedora)
  dnf group install -y gnome-desktop
  dnf install -y gnome-tweaks gnome-extensions-app
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y ubuntu-desktop-minimal gnome-tweaks gnome-shell-extensions
  ;;
opensuse)
  zypper in -y -t pattern gnome
  ;;
esac

systemctl set-default graphical.target
