#!/usr/bin/env bash
: '
sudo .assets/provision/install_gnome.sh
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

case $SYS_ID in
alpine)
  setup-desktop kde
  apk add --no-cache gnome-apps-extra
  ;;
arch)
  pacman -Sy --needed --noconfirm plasma kde-applications firefox
  systemctl enable sddm
  ;;
fedora)
  dnf group install -y kde-desktop-environment
  dnf install -y kde-apps firefox
  systemctl set-default graphical.target
  ;;
debian)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y kde-plasma-desktop kde-standard firefox-esr
  systemctl set-default graphical.target
  ;;
ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y kde-plasma-desktop kde-standard sddm firefox
  systemctl set-default graphical.target
  systemctl enable sddm
  ;;
opensuse)
  zypper --non-interactive install -t pattern kde kde_plasma
  zypper --non-interactive install -y firefox
  systemctl set-default graphical.target
  ;;
esac
