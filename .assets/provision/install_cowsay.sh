#!/usr/bin/env bash
: '
sudo .assets/provision/install_cowsay.sh
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='cowsay'
case $SYS_ID in
alpine)
  exit 0
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

printf "\e[92minstalling \e[1m$APP\e[0m\n"
case $SYS_ID in
arch)
  pacman -Sy --needed --noconfirm --color=auto $APP
  ;;
fedora)
  dnf install -y $APP
  ;;
debian | ubuntu)
  apt-get update && apt-get install -y $APP
  ;;
opensuse)
  zypper in -y $APP
  ;;
esac
