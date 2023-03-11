#!/usr/bin/env bash
: '
# https://docs.brew.sh/Installation
.assets/provision/install_brew.sh >/dev/null
'
if [[ $EUID -eq 0 ]]; then
  printf '\e[91mDo not run the script as root!\e[0m\n'
  exit 1
fi

APP='brew'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/Homebrew/brew/releases/latest | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
  ((retry_count++))
  if [[ $retry_count -eq 10 ]]; then
    echo -e "\e[33m$APP version couldn't be retrieved\e[0m" >&2
    exit 0
  fi
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type brew &>/dev/null; then
  VER=$(brew --version | grep -Eo '[0-9\.]+\.[0-9]+\.[0-9]+')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  else
    brew update
  fi
else
  printf "\e[92minstalling $APP v$REL\e[0m\n" >&2
  # unattended installation
  export NONINTERACTIVE=1
  # skip tap cloning
  export HOMEBREW_INSTALL_FROM_API=1
  # install Homebrew in the loop
  retry_count=0
  while [[ ! -f /home/linuxbrew/.linuxbrew/bin/brew && $retry_count -lt 10 ]]; do
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    ((retry_count++))
  done
fi
