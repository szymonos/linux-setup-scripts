#!/usr/bin/env bash
: '
.assets/scripts/nopasswd_sudoers.sh
.assets/scripts/nopasswd_sudoers.sh revert
'
if [[ $EUID -eq 0 ]]; then
  echo -e '\e[91mDo not run the script as root!\e[0m'
  exit 1
fi

user=$USER

if [[ "$1" = 'revert' ]]; then
  sudo rm -f "/etc/sudoers.d/$user"
elif id -nG "$USER" | grep -qw 'wheel'; then
  # disable sudo password prompt for current user
  cat <<EOF | sudo tee /etc/sudoers.d/$user >/dev/null
$user ALL=(root) NOPASSWD: ALL
EOF
else
  echo -e "\e[33mUser \e[1m${USER}\e[22m is not in the \e[1mwheel\e[22m group\e[0m"
fi
