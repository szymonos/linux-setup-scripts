#!/usr/bin/env bash

echo 'Cleaning ssh known_hosts file...'
sed -i "/^$1/d" ~/.ssh/known_hosts

echo 'Adding fingerprint to ssh known_hosts file...'
while [[ -z $KEY ]]; do
  KEY=$(ssh-keyscan $1 2>/dev/null)
done
echo $KEY >>~/.ssh/known_hosts
