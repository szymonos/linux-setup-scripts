#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubectl.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='kubectl'
case $SYS_ID in
arch)
  pacman -Qqe $APP &>/dev/null && exit 0 || true
  ;;
fedora)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
esac

REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -Lsk https://dl.k8s.io/release/stable.txt)
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    printf "\e[33m$APP version couldn't be retrieved\e[0m\n" >&2
    exit 0
  fi
  [ -n "$REL" ] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if [ -f /usr/bin/kubectl ]; then
  VER=$(/usr/bin/kubectl version --client -o yaml | sed -En 's/.*gitVersion: (v[0-9\.]+)$/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP $VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m $REL\e[0m\n" >&2
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
  install -m 0755 kubectl /usr/bin/ && rm -f kubectl
fi
