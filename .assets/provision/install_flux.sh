#!/usr/bin/env bash
: '
sudo .assets/provision/install_flux.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='flux'

__install="curl -sk https://fluxcd.io/install.sh | bash"
if type $APP &>/dev/null; then
  eval $__install
else
  while ! type $APP &>/dev/null; do
    eval $__install
  done
fi
