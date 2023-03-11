#!/usr/bin/env bash
: '
sudo .assets/provision/install_yq.sh >/dev/null
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='yq'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/mikefarah/yq/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  ((retry_count++))
  if [[ $retry_count -eq 10 ]]; then
    echo -e "\e[33m$APP version couldn't be retrieved\e[0m" >&2
    exit 0
  fi
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(yq --version | grep -Po '[\d\.]+$')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[32m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[92minstalling $APP v$REL\e[0m" >&2
TMP_DIR=$(mktemp -dp "$PWD")
retry_count=0
while [[ ! -f $TMP_DIR/yq_linux_amd64 && $retry_count -lt 10 ]]; do
  curl -Lsk "https://github.com/mikefarah/yq/releases/download/v${REL}/yq_linux_amd64.tar.gz" | tar -zx -C $TMP_DIR
  ((retry_count++))
done
install -o root -g root -m 0755 $TMP_DIR/yq_linux_amd64 /usr/local/bin/yq
pushd $TMP_DIR >/dev/null && bash ./install-man-page.sh && popd >/dev/null
rm -fr $TMP_DIR
