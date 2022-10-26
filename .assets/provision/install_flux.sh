#!/bin/bash
: '
sudo .assets/provision/install_flux.sh
'
while ! type flux &>/dev/null; do
  curl -sk https://fluxcd.io/install.sh | bash
done
