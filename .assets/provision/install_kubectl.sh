#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubectl.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(alpine|arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)
# check if package installed already using package manager
APP='kubectl'
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

REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -Lsk https://dl.k8s.io/release/stable.txt)
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    echo -e "\e[33m$APP version couldn't be retrieved\e[0m" >&2
    exit 0
  fi
  [ -n "$REL" ] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if [ -f /usr/bin/kubectl ]; then
  VER=$(/usr/bin/kubectl version --client -o yaml | grep -Po '(?<=gitVersion: )v[0-9\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[32m$APP $VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[92minstalling $APP $REL\e[0m" >&2
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

if [ "$binary" = true ]; then
  echo 'Installing from binary.' >&2
  retry_count=0
  while [[ ! -f kubectl && $retry_count -lt 10 ]]; do
    curl -LOsk "https://dl.k8s.io/release/$(curl -Lsk https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    ((retry_count++))
  done
  # install
  install -o root -g root -m 0755 kubectl /usr/bin/ && rm -f kubectl
fi
