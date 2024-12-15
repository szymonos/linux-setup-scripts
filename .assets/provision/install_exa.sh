#!/usr/bin/env bash
: '
sudo .assets/provision/install_exa.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='exa'
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
  REL="$(get_gh_release_latest --owner 'ogham' --repo 'exa')"
  [ -n "$REL" ] || exit 1
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  VER=$(exa --version | sed -En 's/v([0-9\.]+).*/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
case $SYS_ID in
alpine)
  apk add --no-cache exa >&2 2>/dev/null
  ;;
arch)
  pacman -Sy --needed --noconfirm exa >&2 2>/dev/null || binary=true
  ;;
fedora)
  dnf install -y exa >&2 2>/dev/null || binary=true
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update >&2 && apt-get install -y exa >&2 2>/dev/null || binary=true
  ;;
opensuse)
  zypper in -y exa >&2 2>/dev/null || binary=true
  ;;
*)
  binary=true
  ;;
esac

if [ "$binary" = true ] && [ -n "$REL" ]; then
  echo 'Installing from binary.' >&2
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -dp "$PWD")
  # calculate download uri
  URL="https://github.com/ogham/exa/releases/download/v${REL}/exa-linux-x86_64-v${REL}.zip"
  # download and install file
  if download_file --uri $URL --target_dir $TMP_DIR; then
    unzip -q "$TMP_DIR/$(basename $URL)" -d "$TMP_DIR"
    install -m 0755 "$TMP_DIR/bin/exa" /usr/bin/
    install -m 0644 "$TMP_DIR/man/exa.1" "$(manpath | cut -d : -f 1)/man1/"
    install -m 0644 "$TMP_DIR/man/exa_colors.5" "$(manpath | cut -d : -f 1)/man5/"
    install -m 0644 "$TMP_DIR/completions/exa.bash" /etc/bash_completion.d/
  fi
  # remove temporary dir
  rm -fr "$TMP_DIR"
fi
