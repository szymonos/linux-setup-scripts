#!/bin/bash
: '
sudo .assets/provision/install_xrdp.sh
'

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
arch)
  su - vagrant -c 'paru -Sy --needed --noconfirm xrdp'
  ;;
fedora)
  # Load the Hyper-V kernel module
  if ! [ -f "/etc/modules-load.d/hv_sock.conf" ] || [ "$(cat /etc/modules-load.d/hv_sock.conf | grep hv_sock)" = "" ]; then
    echo "hv_sock" | tee -a /etc/modules-load.d/hv_sock.conf &>/dev/null
  fi
  dnf -y install xrdp tigervnc-server
  # enable firewall rules
  firewall-cmd --add-port=3389/tcp
  firewall-cmd --runtime-to-permanent
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y xrdp tigervnc-standalone-server tigervnc-xorg-extension tigervnc-viewer
  usermod -a -G ssl-cert xrdp
  ufw allow 3389
  ;;
esac

systemctl enable --now xrdp
