#!/bin/bash
: '
sudo .assets/provision/install_xrdp.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script with sudo!\e[0m'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
arch)
  sudo -u vagrant paru -Sy --needed --noconfirm xrdp
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
