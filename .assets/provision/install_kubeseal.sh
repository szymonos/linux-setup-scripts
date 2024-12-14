#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubeseal.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='kubeseal'
REL=$1
URL=$2
retry_count=0
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  if response="$(get_gh_release_latest --owner 'bitnami-labs' --repo 'sealed-secrets' --regex '^kubeseal-.+-linux-amd64.tar.gz$')"; then
    REL=$(echo $response | jq -r '.version')
    URL=$(echo $response | jq -r '.download_url')
    # return json response
    echo $response
  else
    exit 1
  fi
fi
# exit if the URL is not set
if [ -z "$URL" ]; then
  printf "\e[31mError: The download URL is required.\e[0m\n" >&2
  exit 1
fi

if type $APP &>/dev/null; then
  VER=$(kubeseal --version | sed -En 's/.*\s([0-9\.]+)/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$PWD")
# download and install file
if download_file --uri $URL --target_dir $TMP_DIR; then
  tar -zxf "$TMP_DIR/$(basename $URL)" -C "$TMP_DIR"
  install -m 0755 "$TMP_DIR/$APP" /usr/local/bin/
fi
# remove temporary dir
rm -fr "$TMP_DIR"
