#!/bin/bash
: '
sudo .assets/provision/install_helm.sh
'

while ! type helm &>/dev/null; do
  curl -sk 'https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3' | bash
done
