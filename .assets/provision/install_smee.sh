#!/bin/bash
: '
sudo .assets/provision/install_smee.sh
'

while ! type smee &>/dev/null; do
  npm install -g smee-client
done
