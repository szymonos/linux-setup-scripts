#!/usr/bin/env bash

echo 'Cleaning ssh known_hosts file...'
sed -i "/^$1/d" ~/.ssh/known_hosts

echo 'Adding fingerprint to ssh known_hosts file...'
retry_count=0
while [[ -z "$KEY" && $retry_count -lt 10 ]]; do
  KEY=$(ssh-keyscan $1 2>/dev/null)
  ((retry_count++))
done
echo $KEY >>~/.ssh/known_hosts
