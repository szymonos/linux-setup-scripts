#!/usr/bin/env bash
: '
sudo .assets/provision/install_terrascan.sh
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

APP='terrascan'
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/tenable/terrascan/releases/latest | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    printf "\e[33m$APP version couldn't be retrieved\e[0m\n" >&2
    exit 0
  fi
  [[ -n "$REL" || $i -eq 10 ]] || echo 'retrying...' >&2
done

if type $APP &>/dev/null; then
  VER=$($APP version | sed -En 's/.*\sv([0-9\.]+)/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
TMP_DIR=$(mktemp -dp "$PWD")
retry_count=0
while [[ ! -f "$TMP_DIR/terrascan" && $retry_count -lt 10 ]]; do
  curl -#Lk "https://github.com/tenable/terrascan/releases/download/v${REL}/terrascan_${REL}_Linux_x86_64.tar.gz" | tar -zx -C "$TMP_DIR"
  ((retry_count++))
done
install -m 0755 "$TMP_DIR/terrascan" /usr/bin/
rm -fr "$TMP_DIR"

exit 0
