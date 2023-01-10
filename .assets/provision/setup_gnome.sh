#!/usr/bin/env bash
: '
.assets/provision/setup_gnome.sh
'

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

INSTALL_DASH=true
case $SYS_ID in
arch)
  sudo pacman -Sy --noconfirm sassc
  ;;
fedora)
  sudo dnf install -y @development-tools sassc
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update && sudo apt-get install -y build-essential sassc
  ;;
opensuse)
  sudo zypper in -y -t pattern devel_basis
  INSTALL_DASH=false
  ;;
*)
  INSTALL_DASH=false
  ;;
esac

# install dash-to-dock
if $INSTALL_DASH; then
  GIT_SSL_NO_VERIFY=true git clone https://github.com/micheleg/dash-to-dock.git
  make -C dash-to-dock install && rm -fr dash-to-dock
fi
# button-layout
gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
# keyboard repat and delay settings
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 24
gsettings set org.gnome.desktop.peripherals.keyboard delay 250
# disable desktop screen lock
gsettings set org.gnome.desktop.session idle-delay 0
