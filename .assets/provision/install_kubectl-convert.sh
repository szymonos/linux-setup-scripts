#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubectl-convert.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

APP='kubectl-convert'

TMP_DIR=$(mktemp -dp "$PWD")
retry_count=0
while [[ ! -f "$TMP_DIR/$APP" && $retry_count -lt 10 ]]; do
  curl -#Lko "$TMP_DIR/$APP" "https://dl.k8s.io/release/$(curl -sLk https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"
  ((retry_count++))
done
# install
install -m 0755 "$TMP_DIR/$APP" /usr/bin/
rm -fr "$TMP_DIR"
