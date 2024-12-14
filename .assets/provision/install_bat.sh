#!/usr/bin/env bash
: '
sudo .assets/provision/install_bat.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='bat'
case $SYS_ID in
alpine)
  apk -e info $APP &>/dev/null && exit 0 || true
  ;;
arch)
  pacman -Qqe $APP &>/dev/null && exit 0 || true
  ;;
fedora | opensuse)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
debian | ubuntu)
  dpkg -s $APP &>/dev/null && exit 0 || true
  ;;
esac

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
REL=$1
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'sharkdp' --repo 'bat')"
  if [ -n "$REL" ]; then
    echo $REL
  else
    exit 1
  fi
fi

if type $APP &>/dev/null; then
  VER=$(bat --version | sed -En 's/.*\s([0-9\.]+)/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
case $SYS_ID in
alpine)
  apk add --no-cache $APP >&2 2>/dev/null
  ;;
arch)
  pacman -Sy --needed --noconfirm $APP >&2 2>/dev/null || binary=true
  ;;
fedora)
  dnf install -y $APP >&2 2>/dev/null || binary=true
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -dp "$PWD")
  # calculate download uri
  URL="https://github.com/sharkdp/bat/releases/download/v${REL}/bat_${REL}_amd64.deb"
  # download and install file
  if download_file --uri $URL --target_dir $TMP_DIR; then
    dpkg -i "$TMP_DIR/$(basename $URL)" >&2 2>/dev/null || binary=true
  fi
  # remove temporary dir
  rm -fr "$TMP_DIR"
  ;;
opensuse)
  zypper in -y $APP >&2 2>/dev/null || binary=true
  ;;
*)
  binary=true
  ;;
esac

if [ "$binary" = true ]; then
  echo 'Installing from binary.' >&2
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -dp "$PWD")
  # calculate download uri
  URL="https://github.com/sharkdp/bat/releases/download/v${REL}/bat-v${REL}-x86_64-unknown-linux-gnu.tar.gz"
  # download and install file
  if download_file --uri $URL --target_dir $TMP_DIR; then
    tar -zxf "$TMP_DIR/$(basename $URL)" --strip-components=1 -C "$TMP_DIR"
    install -m 0755 "$TMP_DIR/bat" /usr/bin/
    install -m 0644 "$TMP_DIR/bat.1" "$(manpath | cut -d : -f 1)/man1/"
    install -m 0644 "$TMP_DIR/autocomplete/bat.bash" /etc/bash_completion.d/
  fi
  # remove temporary dir
  rm -fr "$TMP_DIR"
fi
