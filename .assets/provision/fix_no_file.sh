#!/usr/bin/env sh
: '
# Fixes the "Too many open files" error.
sudo .assets/provision/fix_no_file.sh
'
set -eu

if [ "$(id -u)" -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

if [ -f '/etc/systemd/user.conf' ] && grep -qw '#DefaultLimitNOFILE' '/etc/systemd/user.conf'; then
  sed -i 's/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=65535/' /etc/systemd/user.conf
fi
