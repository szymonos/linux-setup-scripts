#!/usr/bin/env bash
: '
sudo .assets/provision/install_kustomize.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

APP='kustomize'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest | sed -En 's/.*"tag_name": "kustomize\/([^"]*)".*/\1/p')
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    printf "\e[33m$APP version couldn't be retrieved\e[0m\n" >&2
    exit 0
  fi
  [[ -n "$REL" || $i -eq 10 ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER="$(kustomize version)"
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP $VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

# dotsource file with common functions
. .assets/provision/source.sh
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$PWD")
# calculate download uri
URL='https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh'
# download and install file
if download_file --uri $URL --target_dir $TMP_DIR; then
  bash -C "$TMP_DIR/$(basename $URL)"
  install -m 0755 kustomize /usr/bin/
fi
# remove temporary dir
rm -fr kustomizell "$TMP_DIR"
