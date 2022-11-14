#!/bin/bash
: '
sudo .assets/provision/install_cascadiacode.sh
'

REL=$1
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/microsoft/cascadia-code/releases/latest | grep -Po '"tag_name": *"v\K.*?(?=")')
  [ -n "$REL" ] || echo 'retrying...'
done

echo "Install CascadiaCode v$REL"
while [[ ! -f CascadiaCode.zip ]]; do
  curl -Lsk -o CascadiaCode.zip "https://github.com/microsoft/cascadia-code/releases/download/v${REL}/CascadiaCode-${REL}.zip"
done
unzip -q CascadiaCode.zip
mkdir -p /usr/share/fonts/cascadia-code
\cp -rf ./ttf/* /usr/share/fonts/cascadia-code/
rm -fr otf ttf woff2 CascadiaCode.zip
