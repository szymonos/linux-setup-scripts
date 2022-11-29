#!/bin/bash
: '
sudo .assets/provision/install_helm.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script with sudo!\e[0m'
  exit 1
fi

while ! type helm &>/dev/null; do
  curl -sk 'https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3' | bash
done
