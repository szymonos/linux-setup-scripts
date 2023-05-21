#!/usr/bin/env bash
: '
.assets/scripts/nopasswd_sudoers.sh
.assets/scripts/nopasswd_sudoers.sh revert
'
if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n'
  exit 1
fi

if [ "$1" = 'revert' ]; then
  # delete user's configuration file from the sudoers.d folder
  if sudo test -f "/etc/sudoers.d/$USER"; then
    sudo rm -f "/etc/sudoers.d/$USER"
    printf "\e[32m\e[1m/etc/sudoers.d/${USER}\e[22m file deleted\e[0m\n"
  else
    printf "\e[33m\e[1m/etc/sudoers.d/${USER}\e[22m file does not exist\e[0m\n"
  fi
else
  # check if user is eligible to run the sudo command
  if id -Gn | grep -Eqw 'wheel|sudo'; then
    if sudo test -f "/etc/sudoers.d/$USER"; then
      printf "\e[33m\e[1m/etc/sudoers.d/${USER}\e[22m file already exists\e[0m\n"
    else
      # disable sudo password prompt for the current user
      echo "$USER ALL=(root) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER >/dev/null
      printf "\e[32m\e[1m/etc/sudoers.d/${USER}\e[22m file created\e[0m\n"
    fi
  else
    printf "\e[33m\e[1m${USER}\e[22m user is not eligible to run the sudo command\e[0m\n"
  fi
fi
