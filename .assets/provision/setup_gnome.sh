#!/bin/bash
: '
.assets/provision/setup_gnome.sh
'

# install dash-to-dock
GIT_SSL_NO_VERIFY=true git clone https://github.com/micheleg/dash-to-dock.git
make -C dash-to-dock install && rm -fr dash-to-dock
# button-layout
gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
# keyboard repat and delay settings
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 24
gsettings set org.gnome.desktop.peripherals.keyboard delay 250
# disable desktop screen lock
gsettings set org.gnome.desktop.session idle-delay 0
