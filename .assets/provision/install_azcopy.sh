#!/usr/bin/env bash
: '
sudo .assets/provision/install_azcopy.sh >/dev/null
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
APP='azcopy'
REL=${1:-}
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'Azure' --repo 'azure-storage-azcopy')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  VER=$(azcopy --version | sed -En 's/azcopy version ([0-9\.]+).*/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
case $SYS_ID in
alpine)
  exit 0
  ;;
fedora)
  dnf install -y "https://github.com/Azure/azure-storage-azcopy/releases/download/v${REL}/azcopy-${REL}.x86_64.rpm" >&2 2>/dev/null
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -d -p "$HOME")
  trap 'rm -fr "$TMP_DIR"' EXIT
  # calculate download uri
  URL="https://github.com/Azure/azure-storage-azcopy/releases/download/v${REL}/azcopy-${REL}.x86_64.deb"
  # download and install file
  if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
    dpkg -i "$TMP_DIR/$(basename $URL)" >&2 2>/dev/null
  fi
  ;;
*)
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -d -p "$HOME")
  trap 'rm -fr "$TMP_DIR"' EXIT
  # calculate download uri
  URL="https://github.com/Azure/azure-storage-azcopy/releases/download/v${REL}/azcopy_linux_amd64_${REL}.tar.gz"
  # download and install file
  if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
    tar -zxf "$TMP_DIR/$(basename $URL)" -C "$TMP_DIR"
    install -m 0755 "$TMP_DIR/azcopy_linux_amd64_${REL}/azcopy" /usr/bin/
  fi
  ;;
esac
