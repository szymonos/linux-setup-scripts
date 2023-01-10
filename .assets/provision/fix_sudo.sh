#!/usr/bin/env bash
: '
sudo .assets/provision/fix_sudo.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

cp /etc/sudoers /etc/sudoers.bck
sed -e 's%secure_path = /sbin%secure_path = /usr/local/sbin:/usr/local/bin:%' /etc/sudoers.bck >/etc/sudoers
