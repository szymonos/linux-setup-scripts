#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubectl.sh >/dev/null
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='kubectl'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -Lsk https://dl.k8s.io/release/stable.txt)
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if [ -f /usr/bin/kubectl ]; then
  VER=$(/usr/bin/kubectl version --client -o yaml | grep -Po '(?<=gitVersion: )v[\d\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[32m$APP $VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[92minstalling $APP $REL\e[0m" >&2
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
arch)
  pacman -Sy --needed --noconfirm kubectl >&2 2>/dev/null || binary=true
  ;;
fedora)
  [ -f /etc/yum.repos.d/kubernetes.repo ] || cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
  dnf install -y kubectl >&2 2>/dev/null || binary=true
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update >&2 && apt-get install -y apt-transport-https ca-certificates curl >&2 2>/dev/null
  # download the Google Cloud public signing key
  curl -fsSLk -o /usr/share/keyrings/kubernetes-archive-keyring.gpg 'https://packages.cloud.google.com/apt/doc/apt-key.gpg'
  # add the Kubernetes apt repository
  [ -f /etc/apt/sources.list.d/kubernetes.list ] || echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
  # update apt package index with the new repository and install kubectl
  apt-get update >&2 && apt-get install -y kubectl >&2 2>/dev/null || binary=true
  ;;
*)
  binary=true
  ;;
esac

if [[ "$binary" = true ]]; then
  echo 'Installing from binary.' >&2
  while [[ ! -f kubectl ]]; do
    curl -LOsk "https://dl.k8s.io/release/$(curl -Lsk https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  done
  # install
  install -o root -g root -m 0755 kubectl /usr/bin/kubectl && rm -f kubectl
fi
