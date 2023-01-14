#!/usr/bin/env bash
: '
sudo .assets/provision/install_docker.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
arch)
  sudo -u vagrant paru -Sy --needed --noconfirm docker
  ;;
fedora)
  dnf config-manager --add-repo 'https://download.docker.com/linux/fedora/docker-ce.repo'
  dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get remove -y docker docker-engine docker.io 2>/dev/null
  apt-get update && apt-get -y install lsb-release gnupg apt-transport-https ca-certificates curl software-properties-common
  curl -fsSLk "https://download.docker.com/linux/$SYS_ID/gpg" | gpg --dearmor -o "/etc/apt/trusted.gpg.d/$SYS_ID.gpg"
  add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/$SYS_ID $(lsb_release -cs) stable"
  apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  ;;
opensuse)
  zypper in -y docker containerd docker-compose
  ;;
esac

usermod -aG docker vagrant
newgrp docker

systemctl enable --now docker.service
systemctl enable --now containerd.service
