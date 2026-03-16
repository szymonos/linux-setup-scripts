#!/usr/bin/env bash
: '
.assets/provision/install_copilot.sh
'
set -euo pipefail

if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

# user specific environment
if ! [[ "$PATH" =~ $HOME/.local/bin: ]]; then
  PATH="$HOME/.local/bin:$PATH"
fi
export PATH

if [ -x "$HOME/.local/bin/copilot" ]; then
  printf "\e[92mupdating \e[1mcopilot-cli\e[22m\e[0m\n" >&2
  copilot update
else
  printf "\e[92minstalling \e[1mcopilot-cli\e[22m\e[0m\n" >&2
  curl -fsSL https://gh.io/copilot-install | bash
fi
