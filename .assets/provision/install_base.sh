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
  apk add --no-cache ca-certificates bash bash-completion iputils curl git jq less mandoc openssl tree vim
  ;;
arch)
  pacman -Sy --noconfirm base-devel bash-completion dnsutils git jq man-db openssl tree vim
  ;;
fedora)
  dnf install -y bash-completion bind-utils curl git jq man-db openssl tree vim
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y bash-completion dnsutils curl git jq man-db openssl tree vim
  ;;
opensuse)
  zypper in -y bash-completion bind-utils git jq openssl tree vim
  ;;
esac
