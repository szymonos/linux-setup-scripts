#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubectl.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
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

REL=$1
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
  TMP_DIR=$(mktemp -dp "$PWD")
  retry_count=0
  while [[ ! -f "$TMP_DIR/$APP" && $retry_count -lt 10 ]]; do
    curl -#Lko "$TMP_DIR/$APP" "https://dl.k8s.io/release/$(curl -sLk https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    ((retry_count++))
  done
  # install
  install -m 0755 "$TMP_DIR/$APP" /usr/bin/
  rm -fr "$TMP_DIR"
fi
