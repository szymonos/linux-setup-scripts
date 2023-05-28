#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubectl-convert.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

APP='kubectl-convert'

retry_count=0
while [[ ! -f kubectl-convert && $retry_count -lt 10 ]]; do
  curl -LOsk "https://dl.k8s.io/release/$(curl -Lsk https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"
  ((retry_count++))
done
# install
install -m 0755 kubectl-convert /usr/bin/ && rm -f kubectl-convert
