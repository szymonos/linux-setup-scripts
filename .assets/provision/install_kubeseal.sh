#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubeseal.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

APP='kubeseal'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/tags | jq -r '.[0].name' | cut -c 2-)
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    printf "\e[33m$APP version couldn't be retrieved\e[0m\n" >&2
    exit 0
  fi
  [[ "$REL" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(kubeseal --version | sed -En 's/.*\s([0-9\.]+)/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
TMP_DIR=$(mktemp -dp "$PWD")
retry_count=0
while [[ ! -f "$TMP_DIR/$APP" && $retry_count -lt 10 ]]; do
  curl -#Lk "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${REL:?}/kubeseal-${REL:?}-linux-amd64.tar.gz" | tar -zx -C "$TMP_DIR"
  ((retry_count++))
done
install -m 0755 "$TMP_DIR/$APP" /usr/local/bin/
rm -fr "$TMP_DIR"
