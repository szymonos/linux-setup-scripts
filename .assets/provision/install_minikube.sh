#!/bin/bash
: '
sudo .assets/provision/install_minikube.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='minikube'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/kubernetes/minikube/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(minikube version | grep -Po '(?<=v)[\d\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m" >&2
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
arch)
  pacman -Sy --needed --noconfirm minikube >&2 2>/dev/null
  ;;
fedora)
  dnf install -y "https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm" >&2 2>/dev/null
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  while [[ ! -f minikube_latest_amd64.deb ]]; do
    curl -LOsk "https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb"
  done
  dpkg -i minikube_latest_amd64.deb >&2 2>/dev/null && rm -f minikube_latest_amd64.deb
  ;;
opensuse)
  zypper in -y --allow-unsigned-rpm "https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm" >&2 2>/dev/null
  ;;
esac

if ! type $APP &>/dev/null; then
  echo 'Installing from binary.' >&2
  while [[ ! -f minikube-linux-amd64 ]]; do
    curl -LOsk "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
  done
  install -o root -g root -m 0755 minikube-linux-amd64 /usr/local/bin/minikube
fi
