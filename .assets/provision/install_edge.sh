#!/usr/bin/env bash
: '
sudo .assets/provision/install_edge.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
arch)
  sudo -u vagrant paru -Sy --needed --noconfirm microsoft-edge-stable-bin
  ;;
fedora)
  rpm --import 'https://packages.microsoft.com/keys/microsoft.asc'
  if [[ ! -f /etc/yum.repos.d/microsoft-edge-stable.repo ]]; then
    dnf config-manager --add-repo 'https://packages.microsoft.com/yumrepos/edge'
    mv -f /etc/yum.repos.d/packages.microsoft.com_yumrepos_edge.repo /etc/yum.repos.d/microsoft-edge.repo
  fi
  dnf install -y microsoft-edge-stable
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  [ -f /etc/apt/trusted.gpg.d/microsoft.gpg ] || curl -fsSLk https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
  install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
  sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list'
  rm microsoft.gpg
  apt-get update && apt-get install -y microsoft-edge-stable
  ;;
opensuse)
  rpm --import 'https://packages.microsoft.com/keys/microsoft.asc'
  zypper addrepo https://packages.microsoft.com/yumrepos/edge microsoft-edge
  zypper refresh
  zypper install -y microsoft-edge-stable
  ;;
esac
