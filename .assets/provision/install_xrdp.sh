#!/usr/bin/env bash
: '
sudo .assets/provision/install_xrdp.sh $(id -un)
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
    if ! sudo -u $user true 2>/dev/null; then
      if [ -n "$user" ]; then
        printf "\e[31;1mUser does not exist ($user).\e[0m\n"
      else
        printf "\e[31;1mUser ID 1000 not found.\e[0m\n"
      fi
      exit 1
    fi
    sudo -u $user paru -Sy --needed --noconfirm xrdp
  else
    printf '\e[33;1mWarning: paru not installed.\e[0m\n'
  fi
  ;;
fedora)
  # Load the Hyper-V kernel module
  if ! [ -f "/etc/modules-load.d/hv_sock.conf" ] || [ "$(cat /etc/modules-load.d/hv_sock.conf | grep hv_sock)" = "" ]; then
    echo "hv_sock" | tee -a /etc/modules-load.d/hv_sock.conf &>/dev/null
  fi
  dnf -y install xrdp tigervnc-server
  # enable firewall rules
  firewall-cmd --permanent --add-service=rdp
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y xrdp tigervnc-standalone-server tigervnc-xorg-extension tigervnc-viewer
  usermod -a -G ssl-cert xrdp
  ufw allow 3389
  ;;
esac

systemctl enable --now xrdp
