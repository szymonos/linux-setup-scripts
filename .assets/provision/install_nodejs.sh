#!/usr/bin/env bash
: '
sudo .assets/provision/install_nodejs.sh
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='nodejs'
case $SYS_ID in
alpine)
  apk -e info $APP &>/dev/null && exit 0 || true
  ;;
arch)
  exit 0
  # pacman -Qqe $APP &>/dev/null && exit 0 || true
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
alpine)
  apk add --no-cache $APP npm
  ;;
arch)
  pacman -Sy --needed --noconfirm $APP npm
  ;;
fedora)
  dnf install -y $APP
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  # dotsource file with common functions
  . .assets/provision/source.sh
  retry_count=0
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -dp "$PWD")
  # calculate download uri
  URL="https://deb.nodesource.com/setup_lts.x"
  # download and install homebrew
  if download_file --uri $URL --target_dir $TMP_DIR; then
    bash -c "$TMP_DIR/setup_lts.x"
  fi
  # remove temporary dir
  rm -fr "$TMP_DIR"
  # install nodejs
  apt-get update && apt-get install -y $APP
  ;;
opensuse)
  zypper in -y $APP npm
  ;;
esac

exit 0
