#!/usr/bin/env bash
# check if the passed parameter starts with rsa phrase
if ! echo "$1" | grep -qE '^(ssh-|ecdsa-)'; then
  printf '\e[31;1mMissing ssh public key in the script parameter.\e[0m\n'
  exit 1
fi

grep -q "$1" ~/.ssh/authorized_keys || echo "$1" >>~/.ssh/authorized_keys
