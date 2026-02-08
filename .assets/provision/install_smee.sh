#!/usr/bin/env bash
: '
sudo .assets/provision/install_smee.sh
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

APP='smee'

if type $APP &>/dev/null; then
  npm update -g smee-client
else
  retry_count=0
  while ! type $APP &>/dev/null && [ $retry_count -lt 10 ]; do
    npm install -g smee-client
    ((retry_count++))
  done
fi

exit 0
