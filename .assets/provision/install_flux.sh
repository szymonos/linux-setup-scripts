#!/bin/bash
: '
sudo .assets/provision/install_flux.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

while ! type flux &>/dev/null; do
  curl -sk https://fluxcd.io/install.sh | bash
done
