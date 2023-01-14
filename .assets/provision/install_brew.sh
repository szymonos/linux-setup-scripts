#!/usr/bin/env bash
: '
# https://docs.brew.sh/Installation
sudo true && .assets/provision/install_brew.sh
'
if [[ $EUID -eq 0 ]]; then
  echo -e '\e[91mDo not run the script as root!\e[0m'
  exit 1
fi

# unattended installation
export NONINTERACTIVE=1
# skip tap cloning
export HOMEBREW_INSTALL_FROM_API=1

# install Homebrew in the loop
while ! [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; do
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
done
