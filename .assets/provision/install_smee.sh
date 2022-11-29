#!/bin/bash
: '
sudo .assets/provision/install_smee.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script with sudo!\e[0m'
  exit 1
fi

while ! type smee &>/dev/null; do
  npm install -g smee-client
done
