#!/usr/bin/env bash
: '
sudo .assets/provision/install_omp.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='oh-my-posh'
REL=$1
URL=$2
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  response="$(get_gh_release_latest --owner 'JanDeDobbeleer' --repo 'oh-my-posh' --asset 'posh-linux-amd64')"
  [ -n "$response" ] || exit 1
  REL=$(echo $response | jq -r '.version')
  URL=$(echo $response | jq -r '.download_url')
elif [ -z "$URL" ]; then
  printf "\e[31mError: The download URL is required.\e[0m\n" >&2
  exit 1
else
  response="{\"version\":\"$REL\",\"download_url\":\"$URL\"}"
fi
# return json response
echo $response

if type $APP &>/dev/null; then
  VER=$(oh-my-posh version)
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
  install -m 0755 "$TMP_DIR/$(basename $URL)" /usr/bin/oh-my-posh
fi
# remove temporary dir
rm -fr "$TMP_DIR"
