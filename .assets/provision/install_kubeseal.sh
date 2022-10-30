#!/bin/bash
: '
sudo .assets/provision/install_kubeseal.sh
'

APP='kubeseal'
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [ -n "$REL" ] || echo 'retrying...'
done

if type $APP &>/dev/null; then
  VER=$(kubeseal --version | grep -Po '[\d\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m"
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m"
while [[ ! -f kubeseal ]]; do
  curl -Lsk "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${REL}/kubeseal-${REL}-linux-amd64.tar.gz" | tar -zx kubeseal
done
install -o root -g root -m 0755 kubeseal /usr/local/bin/kubeseal && rm -f kubeseal
