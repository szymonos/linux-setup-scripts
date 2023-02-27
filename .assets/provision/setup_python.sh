#!/usr/bin/env bash
: '
sudo .assets/provision/setup_python.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

echo -e "\e[92minstalling python pip & virtualenv\e[0m" >&2
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(alpine|arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

# install packages
case $SYS_ID in
alpine)
  apk add --no-cache py3-pip py3-virtualenv
  ;;
arch)
  pacman -Sy --needed --noconfirm --color auto python-pip python-virtualenv
  ;;
fedora)
  dnf install -y python3-pip python3-virtualenv
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y python3-pip python3-virtualenv
  ;;
opensuse)
  zypper in -y python3-pip python3-virtualenv
  ;;
esac

# create python symbolic link
[[ -f /usr/bin/python3 ]] && [[ -f /usr/bin/python ]] || ln -s /usr/bin/python3 /usr/bin/python
