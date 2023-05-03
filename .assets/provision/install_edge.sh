#!/usr/bin/env bash
: '
sudo .assets/provision/install_edge.sh
sudo .assets/provision/install_edge.sh $(id -un)
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
arch)
  if pacman -Qqe paru &>/dev/null; then
    user=${1:-$(id -un 1000 2>/dev/null)}
    if ! grep -qw "^$user" /etc/passwd; then
      if [ -n "$user" ]; then
        printf "\e[31;1mUser does not exist ($user).\e[0m\n"
      else
        printf "\e[31;1mUser ID 1000 not found.\e[0m\n"
      fi
      exit 1
    fi
    sudo -u $user paru -Sy --needed --noconfirm microsoft-edge-stable-bin
  else
    printf '\e[33;1mWarning: paru not installed.\e[0m\n'
  fi
  ;;
fedora)
  rpm --import 'https://packages.microsoft.com/keys/microsoft.asc'
  if [ ! -f /etc/yum.repos.d/microsoft-edge-stable.repo ]; then
    dnf config-manager --add-repo 'https://packages.microsoft.com/yumrepos/edge'
    mv -f /etc/yum.repos.d/packages.microsoft.com_yumrepos_edge.repo /etc/yum.repos.d/microsoft-edge.repo
  fi
  dnf install -y microsoft-edge-stable
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  [ -f /etc/apt/trusted.gpg.d/microsoft.gpg ] || curl -fsSLk https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
  install -m 644 microsoft.gpg /usr/share/keyrings/
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
