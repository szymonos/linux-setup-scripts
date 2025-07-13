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
  pub_key="$(cat $key_path | awk '{print $2}')"
  if gh ssh-key list 2>/dev/null | grep -Fwq "$pub_key"; then
    printf "\e[32mSSH authentication key already exists in GitHub.\e[0m\n" >&2
    echo '{ "sshKey": true }'
  else
    # add the SSH key to GitHub
    gh ssh-key add "$key_path" --title "$(cat "$key_path" | awk '{print $3}')" >/dev/null || {
      printf "\e[31mFailed to add SSH key to GitHub.\e[0m\n" >&2
      echo '{ "sshKey": false }'
      exit 1
    }
    printf "\e[32mSSH key added to GitHub successfully.\e[0m\n" >&2
    echo '{ "sshKey": true }'
  fi
else
  printf "\e[31;1mMissing admin:public_key scope.\e[0m\n" >&2
  echo '{ "sshKey": false }'
  exit 1
fi
