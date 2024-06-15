#!/usr/bin/env bash
: '
sudo .assets/provision/install_k9s.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

APP='k9s'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/derailed/k9s/releases/latest | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
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
  VER=$(k9s version -s | sed -En 's/.*v([0-9\.]+)$/\1/p')
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
URL="https://github.com/derailed/k9s/releases/download/v${REL}/k9s_Linux_amd64.tar.gz"
# download and install file
if download_file --uri $URL --target_dir $TMP_DIR; then
  tar -zxf "$TMP_DIR/$(basename $URL)" -C "$TMP_DIR"
  mkdir -p /opt/k9s
  install -m 0755 "$TMP_DIR/k9s" /opt/k9s/
  [ -f /usr/bin/k9s ] || ln -s /opt/k9s/k9s /usr/bin/k9s
fi
# remove temporary dir
rm -fr "$TMP_DIR"
