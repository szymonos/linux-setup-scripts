#!/usr/bin/env bash
: '
sudo .assets/provision/install_smee.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='smee'

if type $APP &>/dev/null; then
  npm update -g smee-client
else
  while ! type $APP &>/dev/null; do
    npm install -g smee-client
  done
fi
