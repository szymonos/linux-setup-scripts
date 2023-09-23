#!/usr/bin/env bash
: '
sudo .assets/provision/install_eza.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='eza'
case $SYS_ID in
alpine)
  true
  # TODO replace after eza will be added to Alpine repos
  # apk -e info $APP &>/dev/null && exit 0 || true
  ;;
arch)
  pacman -Qqe $APP &>/dev/null && exit 0 || true
  ;;
fedora)
  true
  # TODO replace after eza will be added to Fedora repos
  # rpm -q $APP &>/dev/null && exit 0 || true
  ;;
debian | ubuntu)
  dpkg -s $APP &>/dev/null && exit 0 || true
  ;;
opensuse)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
esac

REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/eza-community/eza/releases/latest | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
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
  VER=$(eza --version | sed -En 's/v([0-9\.]+).*/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
case $SYS_ID in
alpine)
  binary=true
  lib='musl'
  # apk add --no-cache eza >&2 2>/dev/null
  ;;
arch)
  pacman -Sy --needed --noconfirm $APP >&2 2>/dev/null || binary=true
  ;;
fedora)
  binary=true
  lib='gnu'
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
  chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  apt-get update >&2 && apt-get install -y $APP >&2 2>/dev/null || binary=true
  ;;
opensuse)
  zypper in -y eza >&2 2>/dev/null || binary=true
  ;;
*)
  binary=true
  ;;
esac

if [ "$binary" = true ]; then
  echo 'Installing from binary.' >&2
  TMP_DIR=$(mktemp -dp "$PWD")
  retry_count=0
  while [[ ! -f "$TMP_DIR/eza-linux-x86_64.tar.gz" && $retry_count -lt 10 ]]; do
    curl -Lsk -o "$TMP_DIR/eza-linux-x86_64.tar.gz" "https://github.com/eza-community/eza/releases/download/v${REL}/eza_x86_64-unknown-linux-${lib}.tar.gz"
    ((retry_count++))
  done
  tar -zxf "$TMP_DIR/eza-linux-x86_64.tar.gz" -C "$TMP_DIR"
  install -m 0755 "$TMP_DIR/eza" /usr/bin/
  rm -fr "$TMP_DIR"
fi
