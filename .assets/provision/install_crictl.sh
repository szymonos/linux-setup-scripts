#!/usr/bin/env bash
: '
sudo .assets/provision/install_crictl.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='crictl'
REL=$1
retry_count=0
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  if REL="$(get_gh_release_latest --owner 'kubernetes-sigs' --repo 'cri-tools')"; then
    # return latest release
    echo $REL
  else
    exit 1
  fi
fi

if type $APP &>/dev/null; then
  VER=$(crictl --version | sed -En 's/crictl version v([0-9\.]+).*/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$PWD")
# calculate download uri
URL="https://github.com/kubernetes-sigs/cri-tools/releases/download/v${REL}/${APP}-v${REL}-linux-amd64.tar.gz"
# download and install file
if download_file --uri $URL --target_dir $TMP_DIR; then
  tar -zxf "$TMP_DIR/$(basename $URL)" --no-same-owner -C "$TMP_DIR"
  install -m 0755 "$TMP_DIR/crictl" /usr/local/bin/
fi
# remove temporary dir
rm -fr "$TMP_DIR"
