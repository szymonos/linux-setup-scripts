#!/bin/bash
: '
sudo .assets/provision/install_cascadiacode.sh
'

REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/microsoft/cascadia-code/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [ -n "$REL" ] || echo 'retrying...' >&2
done
# return latest release
echo $REL

echo "Install CascadiaCode v$REL" >&2
while [[ ! -f CascadiaCode.zip ]]; do
  curl -Lsk -o CascadiaCode.zip "https://github.com/microsoft/cascadia-code/releases/download/v${REL}/CascadiaCode-${REL}.zip"
done
unzip -q CascadiaCode.zip
mkdir -p /usr/share/fonts/cascadia-code
\cp -rf ./ttf/* /usr/share/fonts/cascadia-code/
rm -fr otf ttf woff2 CascadiaCode.zip
