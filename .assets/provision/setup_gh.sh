#!/usr/bin/env bash
: '
sudo .assets/provision/setup_gh.sh --user "$(id -un)"
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
elif ! [ -x /usr/bin/gh ]; then
  printf "\e[31;1mgh is not installed. Please install gh first.\e[0m\n" >&2
  exit 1
fi

# parse named parameters
user=${user:-$(id -un 1000 2>/dev/null)}
# user=${user:-$(id -u)}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# *check if user specified and exists
if [ -z "$user" ]; then
  printf "\e[31;1mUser not specified.\e[0m\n" >&2
  exit 1
elif [ -n "$user" ] && ! id -u "$user" &>/dev/null; then
  printf "\e[31;1mUser does not exist: $user.\e[0m\n" >&2
  exit 1
fi

# *check gh authentication status and login to GitHub if necessary
# check authentication status as the specified user
if sudo -u "$user" gh auth status | grep -qw '✓'; then
  printf "\e[32mUser \e[1m$user\e[22m is already authenticated to GitHub.\e[0m\n" >&2
else
  printf "\e[33mUser \e[1m$user\e[22m is not authenticated to GitHub. Attempting to log in...\e[0m\n" >&2
  token=''
  retry_count=0
  while [[ $retry_count -lt 5 ]] && [ -z "$token" ]; do
    sudo -u "$user" gh auth login
    token="$(sudo -u "$user" gh auth token 2>/dev/null)"
    ((retry_count++))
  done

  # if authentication still fails after retries, log error and exit.
  if [ -z "$token" ]; then
    printf "\e[31mFailed to authenticate user to GitHub after 5 retries.\e[0m\n" >&2
    exit 1
  fi
fi

# *create symlink for .config/gh if it doesn't exist
# check if the symlink already exists and points to the /home/$user/.config/gh
if [ "$(readlink /root/.config/gh)" != "/home/$user/.config/gh" ]; then
  # remove path if it exists
  if [ -d /root/.config/gh ] || [ -f /root/.config/gh ] || [ -L /root/.config/gh ]; then
    rm -rf /root/.config/gh
  fi
  [ -d /root/.config ] || mkdir /root/.config >/dev/null
  # create the symlink
  ln -s "/home/$user/.config/gh" /root/.config/gh
fi

# *install gh-copilot extension if not already installed
if [ -n "$token" ] && ! sudo -u "$user" gh extension list | grep -qF 'github/gh-copilot'; then
  sudo -u "$user" gh extension install github/gh-copilot 2>/dev/null
fi
