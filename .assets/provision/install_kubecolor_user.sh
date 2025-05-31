#!/usr/bin/env bash
: '
./install_kubecolor_user.sh
'

APP='kubecolor'
# check if latest version is already installed
if type $APP &>/dev/null; then
  printf "\e[32m$APP already installed\e[0m\n"
  exit 0
fi

# try 6 times to get latest release if not provided as a parameter
retry_count=0
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/kubecolor/kubecolor/releases/latest | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
  if [ $retry_count -eq 5 ]; then
    printf "\e[33m$APP version couldn't be retrieved\e[0m\n"
    exit 1
  fi
  [[ "$REL" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] || echo 'retrying...'
  ((retry_count++))
done

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n"
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$HOME")
asset="kubecolor_${REL}_linux_amd64.tar.gz"
URL="https://github.com/kubecolor/kubecolor/releases/download/v${REL}/${asset}"
printf "\e[96mdownloading \e[4m$asset\e[24m from GitHub...\e[0m\n"
retry_count=0
while [[ ! -f "$TMP_DIR/$asset" && $retry_count -lt 8 ]]; do
  curl -#Lko "$TMP_DIR/$asset" "$URL"
  if [ $retry_count -eq 5 ]; then
    printf "\e[33m$APP couldn't be downloaded\e[0m\n"
    exit 1
  fi
  ((retry_count++))
done
# extract and install binary
tar -zxf "$TMP_DIR/$asset" -C "$TMP_DIR"
# create ~/.local/bin for non-root users
[ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin"
# install binary
printf "\e[96minstalling $APP to \e[4m~/.local/bin\e[0m\n"
install -m 0755 "$TMP_DIR/$APP" "$HOME/.local/bin/"
rm -fr "$TMP_DIR"
