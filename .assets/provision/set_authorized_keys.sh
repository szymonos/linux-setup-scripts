#!/usr/bin/env bash
set -euo pipefail

# create .ssh directory and authorized_keys file if they don't exist
[ -d "$HOME/.ssh" ] || mkdir -m 0700 "$HOME/.ssh"
[ -f "$HOME/.ssh/authorized_keys" ] || touch "$HOME/.ssh/authorized_keys" && chmod 0600 "$HOME/.ssh/authorized_keys"

# check if the passed parameter starts with rsa phrase
if ! echo "${1:-}" | grep -qE '^(ssh-|ecdsa-)'; then
  printf '\e[31;1mMissing ssh public key in the script parameter.\e[0m\n'
  exit 1
fi

grep -q "${1:-}" ~/.ssh/authorized_keys || echo "${1:-}" >>~/.ssh/authorized_keys
