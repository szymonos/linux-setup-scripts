#!/usr/bin/env bash
: '
sudo .assets/provision/install_terrascan.sh
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
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
# dotsource file with common functions
. .assets/provision/source.sh
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$PWD")
# calculate download uri
URL="https://github.com/tenable/terrascan/releases/download/v${REL}/terrascan_${REL}_Linux_x86_64.tar.gz"
# download and install file
if download_file --uri $URL --target_dir $TMP_DIR; then
  tar -zxf "$TMP_DIR/$(basename $URL)" -C "$TMP_DIR"
  install -m 0755 "$TMP_DIR/terrascan" /usr/bin/
fi
# remove temporary dir
rm -fr "$TMP_DIR"
