#!/usr/bin/env bash
: '
sudo .assets/provision/install_fastfetch.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='fastfetch'
case $SYS_ID in
alpine)
  exit 0
  ;;
arch)
  pacman -Qqe $APP &>/dev/null && exit 0 || true
  ;;
fedora | opensuse)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
esac

REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
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
  VER=$($APP --version | grep -Po '(?<=\s)[0-9\.]+(?=\s)')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
case $SYS_ID in
arch)
  if pacman -Qqe paru &>/dev/null; then
    user=${1:-$(id -un 1000 2>/dev/null)}
    if ! sudo -u $user true 2>/dev/null; then
      if [ -n "$user" ]; then
        printf "\e[31;1mUser does not exist ($user).\e[0m\n"
      else
        printf "\e[31;1mUser ID 1000 not found.\e[0m\n"
      fi
      exit 1
    fi
    sudo -u $user paru -Sy --needed --noconfirm $APP
  else
    printf '\e[33;1mWarning: paru not installed.\e[0m\n'
  fi
  ;;
fedora)
  dnf install -y $APP >&2 2>/dev/null
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  # dotsource file with common functions
  . .assets/provision/source.sh
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -dp "$PWD")
  # calculate download uri
  URL="https://github.com/fastfetch-cli/fastfetch/releases/download/${REL}/fastfetch-linux-amd64.deb"
  # download and install file
  if download_file --uri $URL --target_dir $TMP_DIR; then
    dpkg -i "$TMP_DIR/$(basename $URL)" >&2 2>/dev/null
  fi
  # remove temporary dir
  rm -fr "$TMP_DIR"
opensuse)
  zypper in -y $APP >&2 2>/dev/null
  ;;
esac
