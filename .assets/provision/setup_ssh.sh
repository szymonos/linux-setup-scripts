#!/usr/bin/env bash
: '
# :generate new SSH key if missing
.assets/provision/setup_ssh.sh
# :generate SSH key and print the public one
./setup_ssh.sh print_pub
'
set -euo pipefail


# prepare clean $HOME/.ssh directory
if [ -d "$HOME/.ssh" ]; then
  if [ -f "$HOME/.ssh/id_ed25519" ] && [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    # correct permissions if needed
    if [ "$(stat -c %a "$HOME/.ssh/id_ed25519")" != "600" ]; then
      chmod 600 "$HOME/.ssh/id_ed25519"
    fi
    if [ "$(stat -c %a "$HOME/.ssh/id_ed25519.pub")" != "644" ]; then
      chmod 644 "$HOME/.ssh/id_ed25519.pub"
    fi
    # both key files exist
    key_exist=true
  elif [ -f "$HOME/.ssh/id_ed25519" ]; then
    rm -f "$HOME/.ssh/id_ed25519.pub"
  elif [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    rm -f "$HOME/.ssh/id_ed25519"
  fi
else
  mkdir "$HOME/.ssh" >/dev/null
fi
# generate new SSH key
if [ "${key_exist:-false}" != true ]; then
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -q
fi

# print the pub key if parameter provided
if [ "${1:-}" = "print_pub" ]; then
  printf "\033[96mAdd the following key on: \033[34;4mhttps://github.com/settings/ssh/new\033[0m\n\n"
  cat "$HOME/.ssh/id_ed25519.pub"
fi
