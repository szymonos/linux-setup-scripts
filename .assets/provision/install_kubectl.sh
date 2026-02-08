#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubectl.sh >/dev/null
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='kubectl'
case $SYS_ID in
arch)
  pacman -Qqe $APP &>/dev/null && exit 0 || true
  ;;
esac

REL=${1:-}
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sLk https://dl.k8s.io/release/stable.txt)
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    printf "\e[33m$APP version couldn't be retrieved\e[0m\n" >&2
    exit 0
  fi
  [[ "$REL" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if [ -f /usr/bin/kubectl ]; then
  VER=$(/usr/bin/kubectl version --client -o yaml | sed -En 's/.*gitVersion: (v[0-9\.]+)$/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP $VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m $REL\e[0m\n" >&2
case $SYS_ID in
arch)
  pacman -Sy --needed --noconfirm kubectl >&2 2>/dev/null || binary=true
  ;;
*)
  binary=true
  ;;
esac

if [ "$binary" = true ]; then
  echo 'Installing from binary.' >&2
  # dotsource file with common functions
  . .assets/provision/source.sh
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -dp "$HOME")
  # calculate download uri
  URL="https://dl.k8s.io/release/${REL}/bin/linux/amd64/kubectl"
  # download and install file
  if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
    install -m 0755 "$TMP_DIR/$(basename $URL)" /usr/bin/
  fi
  # remove temporary dir
  rm -fr "$TMP_DIR"
fi
