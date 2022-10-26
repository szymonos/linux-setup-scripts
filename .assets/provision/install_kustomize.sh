#!/bin/bash
: '
sudo .assets/provision/install_kustomize.sh
'

while [[ ! -f kustomize ]]; do
  curl -sk 'https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh' | bash
done
\mv -f kustomize /usr/local/bin/kustomize
