#!/usr/bin/env bash
: '
sudo .assets/provision/install_kustomize.sh
'
if [ $EUID -ne 0 ]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

retry_count=0
while [[ ! -f kustomize && $retry_count -lt 10 ]]; do
  curl -sk 'https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh' | bash
  ((retry_count++))
done
install -o root -g root -m 0755 kustomize /usr/local/bin/ && rm -f kustomize

exit 0
