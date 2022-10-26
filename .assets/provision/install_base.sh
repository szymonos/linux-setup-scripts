#!/bin/bash
: '
sudo .assets/provision/install_base.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script with sudo!\e[0m'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*\K(alpine|arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  apk add --no-cache bash-completion curl git jq mandoc man-pages less less-doc openssl tree vim
  ;;
arch)
  pacman -Sy --noconfirm bash-completion curl git jq mandoc man-pages less openssl tree vim
  ;;
fedora)
  dnf install -y bash-completion curl git jq mandoc man-pages less openssl tree vim
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y bash-completion curl git jq mandoc less openssl tree vim
  ;;
opensuse)
  zypper in -y bash-completion curl git jq mandoc man-pages less openssl tree vim
  ;;
esac
