#!/usr/bin/env bash
: '
sudo .assets/provision/install_minikube.sh >/dev/null
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='minikube'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/kubernetes/minikube/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  ((retry_count++))
  if [[ $retry_count -eq 10 ]]; then
    echo -e "\e[33m$APP version couldn't be retrieved\e[0m" >&2
    exit 0
  fi
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(minikube version | grep -Po '(?<=v)[\d\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[32m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[92minstalling $APP v$REL\e[0m" >&2
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
arch)
  pacman -Sy --needed --noconfirm minikube >&2 2>/dev/null || binary=true
  ;;
fedora)
  dnf install -y "https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm" >&2 2>/dev/null || binary=true
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  retry_count=0
  while [[ ! -f minikube_latest_amd64.deb && $retry_count -lt 10 ]]; do
    curl -LOsk "https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb"
    ((retry_count++))
  done
  dpkg -i minikube_latest_amd64.deb >&2 2>/dev/null && rm -f minikube_latest_amd64.deb || binary=true
  ;;
opensuse)
  zypper in -y --allow-unsigned-rpm "https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm" >&2 2>/dev/null || binary=true
  ;;
*)
  binary=true
  ;;
esac

if [[ "$binary" = true ]]; then
  echo 'Installing from binary.' >&2
  retry_count=0
  while [[ ! -f minikube-linux-amd64 && $retry_count -lt 10 ]]; do
    curl -LOsk "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
    ((retry_count++))
  done
  install -o root -g root -m 0755 minikube-linux-amd64 /usr/local/bin/minikube
fi
