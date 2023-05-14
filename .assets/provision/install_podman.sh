#!/usr/bin/env bash
: '
sudo .assets/provision/install_podman.sh
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='podman'
case $SYS_ID in
alpine)
  apk -e info $APP &>/dev/null && exit 0 || true
  ;;
arch)
  pacman -Qqe $APP &>/dev/null && exit 0 || true
  ;;
fedora | opensuse)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
debian | ubuntu)
  dpkg -s $APP &>/dev/null && exit 0 || true
  ;;
esac

case $SYS_ID in
alpine)
  apk add --no-cache $APP
  ;;
arch)
  pacman -Sy --noconfirm $APP shadow
  ;;
fedora)
  dnf install -y $APP
  # fix shadow-utils
  rpm -V shadow-utils >/dev/null || dnf reinstall -y shadow-utils
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y $APP
  ;;
opensuse)
  zypper in -y $APP
  ;;
esac
