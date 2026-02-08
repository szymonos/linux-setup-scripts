#!/usr/bin/env bash
: '
sudo .assets/provision/install_distrobox.sh $(id -un)
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='distrobox'
case $SYS_ID in
alpine)
  apk -e info $APP &>/dev/null && installed=true || installed=false
  ;;
arch)
  pacman -Qqe $APP &>/dev/null && installed=true || installed=false
  ;;
fedora | opensuse)
  rpm -q $APP &>/dev/null && installed=true || installed=false
  ;;
debian | ubuntu)
  dpkg -s $APP &>/dev/null && installed=true || installed=false
  ;;
esac
if [ "$installed" = true ]; then
  printf "\e[32m$APP is already installed\e[0m\n"
  exit 0
else
  printf "\e[92minstalling \e[1m$APP\e[0m\n"
fi

case $SYS_ID in
alpine)
  apk add --no-cache $APP
  ;;
arch)
  if pacman -Qqe paru &>/dev/null; then
    user=${1:-$(id -un 1000 2>/dev/null)}
    if ! sudo -u $user true 2>/dev/null; then
      if [ -n "$user" ]; then
        printf "\e[31;1mUser does not exist ($user).\e[0m\n"
      else
        printf "\e[31;1mUser ID 1000 not found.\e[0m\n"
      fi
      exit 1
    fi
    sudo -u $user paru -Sy --needed --noconfirm $APP
  else
    printf '\e[33;1mWarning: paru not installed.\e[0m\n'
  fi
  ;;
fedora)
  dnf install -y $APP
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  add-apt-repository -y ppa:michel-slm/distrobox
  apt-get update && apt-get install -y $APP
  ;;
opensuse)
  zypper --non-interactive in -y $APP
  ;;
esac
