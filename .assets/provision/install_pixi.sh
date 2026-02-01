#!/usr/bin/env bash
: '
.assets/provision/install_pixi.sh
'
if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

if [ -x "$HOME/.pixi/bin/pixi" ]; then
  $HOME/.pixi/bin/pixi self-update
else
  curl -fsSL https://pixi.sh/install.sh | sh
fi
