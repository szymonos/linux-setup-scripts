#!/usr/bin/env bash
: '
sudo .assets/provision/install_base.sh
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(alpine|arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  apk add --no-cache build-base ca-certificates iputils curl git jq less lsb-release-minimal mandoc openssl tar tree unzip vim
  ;;
arch)
  pacman -Sy --needed --noconfirm --color auto base-devel bash-completion dnsutils git jq lsb-release man-db openssh openssl tar tree unzip vim 2>/dev/null
  # install paru
  if ! pacman -Qqe paru &>/dev/null; then
    user=${1:-$(id -un 1000 2>/dev/null)}
    if ! grep -qw "^$user" /etc/passwd; then
      if [ -n "$user" ]; then
        printf "\e[31;1mUser does not exist ($user).\e[0m\n"
      else
        printf "\e[31;1mUser ID 1000 not found.\e[0m\n"
      fi
      exit 1
    fi
    sudo -u $user bash -c 'git clone https://aur.archlinux.org/paru-bin.git && cd paru-bin && makepkg -si --noconfirm && cd .. && rm -fr paru-bin'
    grep -qw '^BottomUp' /etc/paru.conf || sed -i 's/^#BottomUp/BottomUp/' /etc/paru.conf
  fi
  ;;
fedora)
  rpm -q patch &>/dev/null || dnf groupinstall -y 'Development Tools'
  dnf install -qy bash-completion bind-utils curl dnf-plugins-core git iputils jq redhat-lsb-core man-db openssl tar tree unzip vim
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y build-essential bash-completion ca-certificates gnupg dnsutils curl git iputils-tracepath jq lsb-release man-db openssl tar tree unzip vim
  ;;
opensuse)
  rpm -q patch &>/dev/null || zypper in -yt pattern devel_basis
  zypper in -y bash-completion bind-utils git jq lsb-release openssl tar tree unzip vim
  ;;
esac
