#!/usr/bin/env sh
: '
sudo .assets/provision/upgrade_system.sh
'
if [ $(id -u) -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

SYS_ID="$(sed -En '/^ID.*(arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
case $SYS_ID in
alpine)
  apk upgrade --available
  ;;
arch)
  # ArchWSL fix for WSL2
  if [ -n "$WSL_DISTRO_NAME" ]; then
    sed -i '/\bfakeroot\b/d' /etc/pacman.conf
    pacman -R --noconfirm fakeroot-tcp 2>/dev/null || true
  fi
  pacman -Sy --needed --noconfirm archlinux-keyring 2>/dev/null
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
  zypper refresh && zypper dup -y
  ;;
esac
