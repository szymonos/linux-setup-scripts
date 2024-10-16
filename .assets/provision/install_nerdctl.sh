#!/usr/bin/env bash
: '
sudo .assets/provision/install_nerdctl.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='nerdctl'
REL=$1
retry_count=0
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  if REL="$(get_gh_release_latest --owner 'containerd' --repo 'nerdctl')"; then
    # return latest release
    echo $REL
  else
    exit 1
  fi
fi

if type $APP &>/dev/null; then
  VER=$(nerdctl --version | sed -En 's/nerdctl version ([0-9\.]+).*/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$PWD")
# calculate download uri
URL="https://github.com/containerd/nerdctl/releases/download/v${REL}/${APP}-${REL}-linux-amd64.tar.gz"
# download and install file
if download_file --uri $URL --target_dir $TMP_DIR; then
  tar -zxf "$TMP_DIR/$(basename $URL)" --no-same-owner -C "$TMP_DIR"
  install -m 0755 "$TMP_DIR/nerdctl" /usr/local/bin/
  install -m 0755 "$TMP_DIR/containerd-rootless-setuptool.sh" /usr/local/bin/
  install -m 0755 "$TMP_DIR/containerd-rootless.sh" /usr/local/bin/
fi
# remove temporary dir
rm -fr "$TMP_DIR"
