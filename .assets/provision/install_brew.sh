#!/usr/bin/env bash
: '
# https://docs.brew.sh/Installation
.assets/provision/install_brew.sh >/dev/null
'
if [[ $EUID -eq 0 ]]; then
  echo -e '\e[91mDo not run the script as root!\e[0m'
  exit 1
fi

APP='brew'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/Homebrew/brew/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type brew &>/dev/null; then
  VER=$(brew --version | grep -Po '(?<=^Homebrew )[\d\.]+')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[36m$APP v$VER is already latest\e[0m" >&2
    exit 0
  else
    brew update
  fi
else
  echo -e "\e[96minstalling $APP v$REL\e[0m" >&2
  # unattended installation
  export NONINTERACTIVE=1
  # skip tap cloning
  export HOMEBREW_INSTALL_FROM_API=1
  # install Homebrew in the loop
  while ! [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; do
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  done
fi
