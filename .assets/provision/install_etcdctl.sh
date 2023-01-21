#!/usr/bin/env bash
: '
sudo .assets/provision/install_etcdctl.sh >/dev/null
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='etcdctl'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/etcd-io/etcd/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(etcdctl version | grep -Po '(?<=etcdctl version: )[\d\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[32m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[92minstalling $APP v$REL\e[0m" >&2
TMP_DIR=$(mktemp -dp "$PWD")
while [[ ! -f $TMP_DIR/etcdctl ]]; do
  curl -Lsk "https://github.com/etcd-io/etcd/releases/download/v${REL}/etcd-v${REL}-linux-amd64.tar.gz" | tar -zx -C $TMP_DIR
done
install -o root -g root -m 0755 $TMP_DIR/etcdctl /usr/local/bin/etcdctl
rm -fr $TMP_DIR
