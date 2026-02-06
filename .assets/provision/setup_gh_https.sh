#!/usr/bin/env bash
: '
# set up GitHub CLI https authentication for the specified user
sudo .assets/provision/setup_gh_https.sh -u "$(id -un)"
# set up GitHub CLI https authentication with admin:public_key scope
sudo .assets/provision/setup_gh_https.sh -u "$(id -un)" -k
# set up GitHub CLI https authentication with the provided token
sudo .assets/provision/setup_gh_https.sh -u "$(id -un)" -c "$gh_auth"
# set up GitHub CLI https authentication with admin:public_key scope and the provided token
sudo .assets/provision/setup_gh_https.sh -u "$(id -un)" -c "$gh_auth" -k
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
elif ! [ -x /usr/bin/gh ]; then
  printf "\e[31;1mgh cli is not installed.\e[0m\n" >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# initialize local variable to the current user
user="$(id -un 1000 2>/dev/null || echo "unknown")"
# parse named parameters
OPTIND=1
while getopts ":u:c:k" opt; do
  case $opt in
  u)
    user="$OPTARG"
    ;;
  c)
    gh_cfg="$OPTARG"
    ;;
  k)
    key=true
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 1
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

# check if the user exists
if ! id -u "$user" &>/dev/null; then
  printf "\e[31mError: The user \e[1m$user\e[22m does not exist.\e[0m\n" >&2
  exit 1
fi

# define script variables
user_home="/home/$user"
user_gh_cfg="$user_home/.config/gh"

# *Save provided gh config
if [ -n "$gh_cfg" ]; then
  echo "Saving provided gh config to $user_gh_cfg/hosts.yml" >&2
  sudo -u "$user" mkdir -p "$user_gh_cfg"
  echo "$gh_cfg" | sudo -u "$user" tee "$user_gh_cfg/hosts.yml" >/dev/null
  if ! sudo -u "$user" git config --global credential.'https://github.com'.helper | grep -wqF 'gh auth'; then
    sudo -u "$user" git config --global credential.'https://github.com'.helper '!/usr/bin/gh auth git-credential'
  fi
  if ! sudo -u "$user" git config --global credential.'https://gist.github.com'.helper | grep -wqF 'gh auth'; then
    sudo -u "$user" git config --global credential.'https://gist.github.com'.helper '!/usr/bin/gh auth git-credential'
  fi
fi

# *Authenticate user to GitHub
if [ "$key" = true ]; then
  gh_auth="$(login_gh_user -u "$user" -k)"
else
  gh_auth="$(login_gh_user -u "$user")"
fi

if [ "$gh_auth" = 'none' ]; then
  exit 1
else
  # TODO uncomment once copilot-cli is added to the automation
  # install gh-copilot extension if not already installed
  # if ! sudo -u "$user" gh extension list | grep -qF 'github/gh-copilot'; then
  #   sudo -u "$user" gh extension install github/gh-copilot 2>/dev/null
  # fi
  if echo "$gh_auth" | grep -Fwq 'github.com'; then
    if [ "$(readlink /root/.config/gh)" != "$user_gh_cfg" ]; then
      # remove path if it exists
      if [ -d /root/.config/gh ] || [ -f /root/.config/gh ] || [ -L /root/.config/gh ]; then
        rm -rf /root/.config/gh
      fi
      [ -d /root/.config ] || mkdir /root/.config >/dev/null
      # create the symlink
      ln -s "$user_gh_cfg" /root/.config/gh
    fi
    echo "$gh_auth"
    exit 0
  elif [ "$gh_auth" = 'keyring' ]; then
    printf "\e[32mLogging in user \e[1m$(id -un)\e[22m user separately, as \e[1m$user\e[22m user is authenticated to GitHub using keyring.\e[0m\n" >&2
    gh_auth="$(login_gh_user)"
    # check if the user is authenticated
    [ "$gh_auth" = 'none' ] && exit 1 || exit 0
  else
    printf "\e[31;1mUnknown authentication method.\e[0m\n" >&2
    exit 1
  fi
fi
