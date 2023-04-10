#!/usr/bin/env bash
: '
sudo .assets/provision/install_omp.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='oh-my-posh'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    echo -e "\e[33m$APP version couldn't be retrieved\e[0m" >&2
    exit 0
  fi
  [ -n "$REL" ] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(oh-my-posh version)
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[32m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[92minstalling $APP v$REL\e[0m" >&2
retry_count=0
while [[ ! -f posh-linux-amd64 && $retry_count -lt 10 ]]; do
  curl -LsOk "https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v${REL}/posh-linux-amd64"
  ((retry_count++))
done
install -o root -g root -m 0755 posh-linux-amd64 /usr/bin/oh-my-posh && rm -f posh-linux-amd64
