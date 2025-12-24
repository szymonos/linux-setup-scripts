#!/usr/bin/env bash
: '
sudo .assets/provision/install_kind.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='kind'
REL=$1
OWNER='kubernetes-sigs'
REPO='kind'
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner $OWNER --repo $REPO)"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  VER=$(kind version | sed -En 's/.*v([0-9\.]+).*/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$HOME")
# calculate download uri
URL="https://github.com/$OWNER/$REPO/releases/download/v${REL}/kind-linux-amd64"
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  mkdir -p /opt/kind
  install -m 0755 "$TMP_DIR/kind-linux-amd64" /opt/kind/kind
  [ -f /usr/bin/kind ] || ln -s /opt/kind/kind /usr/bin/kind
fi
# remove temporary dir
rm -fr "$TMP_DIR"
