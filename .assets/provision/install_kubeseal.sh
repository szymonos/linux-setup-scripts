#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubeseal.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='kubeseal'
REL=$1
retry_count=0
# get latest release if not provided as a parameter
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
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$PWD")
# calculate download uri
URL="https://github.com/bitnami-labs/sealed-secrets/releases/download/v${REL:?}/kubeseal-${REL:?}-linux-amd64.tar.gz"
# download and install file
if download_file --uri $URL --target_dir $TMP_DIR; then
  tar -zxf "$TMP_DIR/$(basename $URL)" -C "$TMP_DIR"
  install -m 0755 "$TMP_DIR/$APP" /usr/local/bin/
fi
# remove temporary dir
rm -fr "$TMP_DIR"
