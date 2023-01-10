#!/usr/bin/env bash
: '
sudo .assets/provision/install_gnome.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  setup-desktop gnome
  apk add --no-cache gnome-apps-extra
  ;;
arch)
  pacman -Sy --needed --noconfirm gnome gnome-extra firefox
  systemctl enable gdm
  ;;
fedora)
  dnf group install -y gnome-desktop
  dnf install -y gnome-tweaks gnome-extensions-app firefox
  systemctl set-default graphical.target
  ;;
debian)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y gnome/stable gnome-tweaks gnome-shell-extensions firefox-esr
  systemctl set-default graphical.target
  ;;
ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y ubuntu-desktop-minimal gnome-tweaks gnome-shell-extensions firefox
  systemctl set-default graphical.target
  ;;
opensuse)
  zypper in -y -t pattern gnome
  zypper in -y firefox
  systemctl set-default graphical.target
  ;;
esac
