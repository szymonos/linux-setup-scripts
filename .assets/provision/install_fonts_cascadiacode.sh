#!/usr/bin/env bash
: '
#
sudo .assets/provision/install_fonts_cascadiacode.sh >/dev/null
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

# variables
REL=$1
TMP_DIR=$(mktemp -dp "$PWD")

# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/microsoft/cascadia-code/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  ((retry_count++))
  if [[ $retry_count -eq 10 ]]; then
    echo -e "\e[33m$APP version couldn't be retrieved\e[0m" >&2
    exit 0
  fi
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

echo "Install CascadiaCode v$REL" >&2
retry_count=0
while [[ ! -f CascadiaCode.zip && $retry_count -lt 10 ]]; do
  curl -Lsk -o $TMP_DIR/CascadiaCode.zip "https://github.com/microsoft/cascadia-code/releases/download/v${REL}/CascadiaCode-${REL}.zip"
  ((retry_count++))
done
unzip -q $TMP_DIR/CascadiaCode.zip -d $TMP_DIR
mkdir -p /usr/share/fonts/cascadia-code
cp -rf $TMP_DIR/ttf/*.ttf /usr/share/fonts/cascadia-code/
rm -fr $TMP_DIR
# build font information caches
fc-cache -f /usr/share/fonts/cascadia-code/
