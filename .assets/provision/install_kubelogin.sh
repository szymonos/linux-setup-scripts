#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubelogin.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

APP='kubelogin'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/Azure/kubelogin/releases/latest | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    printf "\e[33m$APP version couldn't be retrieved\e[0m\n" >&2
    exit 0
  fi
  [ -n "$REL" ] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(kubelogin --version | sed -En 's/.*v([0-9\.]+).*/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
TMP_DIR=$(mktemp -dp "$PWD")
retry_count=0
while [[ ! -f "$TMP_DIR/kubelogin.zip" && $retry_count -lt 10 ]]; do
  curl -Lsk -o "$TMP_DIR/kubelogin.zip" "https://github.com/Azure/kubelogin/releases/download/v${REL}/kubelogin-linux-amd64.zip"
  ((retry_count++))
done
unzip -q "$TMP_DIR/kubelogin.zip" -d "$TMP_DIR"
install -m 0755 "$TMP_DIR/bin/linux_amd64/kubelogin" /usr/local/bin/
rm -fr "$TMP_DIR"
