#!/usr/bin/env bash
: '
sudo .assets/provision/install_k9s.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='k9s'
REL=$1
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'derailed' --repo 'k9s')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  VER=$(k9s version -s | sed -En 's/.*v([0-9\.]+)$/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$HOME")
# calculate download uri
URL="https://github.com/derailed/k9s/releases/download/v${REL}/k9s_Linux_amd64.tar.gz"
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  tar -zxf "$TMP_DIR/$(basename $URL)" -C "$TMP_DIR"
  mkdir -p /opt/k9s
  install -m 0755 "$TMP_DIR/k9s" /opt/k9s/
  [ -f /usr/bin/k9s ] || ln -s /opt/k9s/k9s /usr/bin/k9s
fi
# remove temporary dir
rm -fr "$TMP_DIR"
