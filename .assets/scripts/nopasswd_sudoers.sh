#!/usr/bin/env bash
: '
.assets/scripts/nopasswd_sudoers.sh
.assets/scripts/nopasswd_sudoers.sh revert
'
if [[ $EUID -eq 0 ]]; then
  echo -e '\e[91mDo not run the script as root!\e[0m'
  exit 1
fi

# store user name in separate variable tu use in sudo commands.
user=$USER

if [[ "$1" = 'revert' ]]; then
  # delete user's configuration file from sudoers folder
  sudo rm -f "/etc/sudoers.d/$user"
  echo -e "\e[32mFile \e[1m/etc/sudoers.d/${user}\e[22m deleted.\e[0m"
else
  # check if user is eligible to run sudo commands
  group=$(id -nG "$USER" | grep -Eow 'wheel|sudo')
  if [[ -n $group ]]; then
    if [[ -f /etc/sudoers.d/$user ]]; then
      echo -e "\e[33mFile \e[1m/etc/sudoers.d/${user}\e[22m already exists.\e[0m"
    else
      # disable sudo password prompt for current user
      echo "$user ALL=(root) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$user >/dev/null
      echo -e "\e[32mFile \e[1m/etc/sudoers.d/${user}\e[22m created.\e[0m"
    fi
  else
    echo -e "\e[33mUser \e[1m${user}\e[22m is not in the \e[1m${group}\e[22m group.\e[0m"
  fi
fi
