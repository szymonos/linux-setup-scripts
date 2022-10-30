#!/bin/bash
: '
sudo .assets/provision/install_etcdctl.sh
'

APP='etcdctl'
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/etcd-io/etcd/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [ -n "$REL" ] || echo 'retrying...'
done

if type $APP &>/dev/null; then
  VER=$(etcdctl version | grep -Po '(?<=etcdctl version: )[\d\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m"
    exit 0
  fi
fi

echo -e "\e[96minstalling $APP v$REL\e[0m"
while [[ ! -f kubectl-argo-rollouts-linux-amd64 ]]; do
  'https://github.com/etcd-io/etcd/releases/download/v${REL}/etcd-v${REL}-linux-amd64.tar.gz'
  curl -Lsk "https://github.com/etcd-io/etcd/releases/download/v${REL}/etcd-v${REL}-linux-amd64.tar.gz" | tar -zx
done
install -o root -g root -m 0755 "etcd-v${REL}-linux-amd64/etcdctl" /usr/local/bin/etcdctl && rm -fr "etcd-v${REL}-linux-amd64"
