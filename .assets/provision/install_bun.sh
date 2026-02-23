#!/usr/bin/env bash
: '
.assets/provision/install_bun.sh
'
set -euo pipefail

if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

if [ -x "$HOME/.bun/bin/bun" ]; then
  $HOME/.bun/bin/bun upgrade
else
  printf "\e[92minstalling \e[1mbun\e[22m\e[0m\n" >&2
  curl -fsSL https://bun.sh/install | bash
fi
