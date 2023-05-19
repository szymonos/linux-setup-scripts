#!/usr/bin/env sh
: '
sudo .assets/provision/fix_secure_path.sh
'
if [ $(id -u) -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

if grep -Eqw '^Defaults\s+secure_path' /etc/sudoers &&
  ! grep -Eqw '^Defaults\s+secure_path.+/usr/local/bin' /etc/sudoers; then
  [ -f /etc/sudoers.bak ] || cp /etc/sudoers /etc/sudoers.bak
  sed -Ei 's/(^Defaults\s+secure_path\s*=\s*"?)/\1\/usr\/local\/sbin:\/usr\/local\/bin:/' /etc/sudoers
fi
