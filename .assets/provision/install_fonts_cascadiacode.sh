#!/usr/bin/env bash
: '
#
sudo .assets/provision/install_fonts_cascadiacode.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
REL=$1
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'microsoft' --repo 'cascadia-code')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

echo "Install CascadiaCode v$REL" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$HOME")
# calculate download uri
URL="https://github.com/microsoft/cascadia-code/releases/download/v${REL}/CascadiaCode-${REL}.zip"
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  unzip -q "$TMP_DIR/$(basename $URL)" -d "$TMP_DIR"
  mkdir -p /usr/share/fonts/cascadia-code
  find "$TMP_DIR/ttf" -type f -name "*.ttf" -exec cp {} /usr/share/fonts/cascadia-code/ \;
  # build font information caches
  fc-cache -f /usr/share/fonts/cascadia-code/
fi
# remove temporary dir
rm -fr "$TMP_DIR"
