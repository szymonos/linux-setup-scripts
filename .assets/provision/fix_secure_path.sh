#!/usr/bin/env bash
: '
sudo .assets/provision/fix_secure_path.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

if grep -Eqw '^Defaults\s+secure_path' /etc/sudoers &&
  ! grep -Eqw '^Defaults\s+secure_path.+/usr/local/bin' /etc/sudoers; then
  [[ -f /etc/sudoers.bak ]] || cp /etc/sudoers /etc/sudoers.bak
  sed -Ei 's/(^Defaults\s+secure_path\s*=\s*"?)/\1\/usr\/local\/sbin:\/usr\/local\/bin:/' /etc/sudoers
fi
