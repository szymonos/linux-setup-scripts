#!/usr/bin/env bash
: '
.assets/provision/setup_gh_ssh.sh
'

if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
elif ! [ -x /usr/bin/gh ]; then
  printf "\e[31;1mgh is not installed. Please install gh first.\e[0m\n" >&2
  exit 1
fi

auth_status="$(gh auth status 2>/dev/null)"
if echo "$auth_status" | grep -Fwq 'admin:public_key'; then
  # check if SSH key already added to GitHub
  ssh_dir="$HOME/.ssh"
  key_path="$ssh_dir/id_ed25519.pub"
  if ! [ -r "$key_path" ]; then
    printf "\e[31mSSH public key file not found or not readable: $key_path\e[0m\n" >&2
    echo '{ "sshKey": "missing" }'
    exit 1
  fi
  pub_key="$(cat $key_path | awk '{print $2}')"
  if [ -z "$pub_key" ]; then
    printf "\e[31mSSH public key is empty or invalid.\e[0m\n" >&2
    echo '{ "sshKey": "missing" }'
    exit 1
  fi
  if gh ssh-key list 2>/dev/null | grep -Fwq "$pub_key"; then
    printf "\e[32mSSH authentication key already exists in GitHub.\e[0m\n" >&2
    echo '{ "sshKey": "existing" }'
  else
    # add the SSH key to GitHub
    title="${USER}@$(uname -n)"
    gh ssh-key add "$key_path" --title "$title" >/dev/null || {
      printf "\e[31mFailed to add SSH key to GitHub.\e[0m\n" >&2
      echo '{ "sshKey": "missing" }'
      exit 1
    }
    printf "\e[32mSSH key added to GitHub successfully.\e[0m\n" >&2
    echo '{ "sshKey": "added", "title": "'"$title"'" }'
  fi
else
  printf "\e[31;1mMissing admin:public_key scope.\e[0m\n" >&2
  echo '{ "sshKey": "missing" }'
  exit 1
fi

# *add github.com to known_hosts
if ! grep -qw 'github.com' ~/.ssh/known_hosts 2>/dev/null; then
  printf "\e[32madding GitHub fingerprint\e[0m\n" >&2
  ssh-keyscan github.com 1>>~/.ssh/known_hosts 2>/dev/null
fi
