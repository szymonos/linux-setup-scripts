#!/bin/bash
# check if the passed parameter starts with rsa phrase
if ! echo "$1" | grep -qE '^(ssh-|ecdsa-)'; then
  echo -e '\e[91mMissing ssh public key in the script parameter!'
  exit 1
fi

grep -q "$1" ~/.ssh/authorized_keys || echo "$1" >>~/.ssh/authorized_keys
