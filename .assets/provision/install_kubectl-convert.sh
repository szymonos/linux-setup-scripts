#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubectl-convert.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

APP='kubectl-convert'

# dotsource file with common functions
. .assets/provision/source.sh
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$HOME")
# calculate download uri
URL="https://dl.k8s.io/release/$(curl -sLk https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  tar -zxf "$TMP_DIR/$(basename $URL)" -C "$TMP_DIR"
  install -m 0755 "$TMP_DIR/$(basename $URL)" /usr/bin/
fi
# remove temporary dir
rm -fr "$TMP_DIR"
