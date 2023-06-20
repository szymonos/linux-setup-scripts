#!/usr/bin/env bash
: '
sudo .assets/provision/install_btop.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='btop'
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

printf "\e[92minstalling $APP v$REL\e[0m\n" >&2
case $SYS_ID in
alpine)
  apk add --no-cache $APP >&2 2>/dev/null
  ;;
arch)
  pacman -Sy --needed --noconfirm --color=auto $APP >&2 2>/dev/null
  ;;
fedora)
  dnf install -y $APP >&2 2>/dev/null
  ;;
debian | ubuntu)
  apt-get update && apt-get install -y $APP >&2 2>/dev/null
  ;;
opensuse)
  zypper in -y $APP >&2 2>/dev/null
  ;;
esac