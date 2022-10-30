#!/bin/bash
: '
.assets/provision/setup_gh_repos.sh "fedora" "devops-scripts,vagrant" "szymonos" "szymo"
'
# *parameter variables
ws_path="$HOME/source/workspaces/${1,,}-devops.code-workspace" # convert to lowercase and calculate workspace file path
repos=($2) # convert to indexed array
gh_user=$3
win_user=$4

# *copy ssh keys on WSL
if [ -n $WSL_DISTRO_NAME ]; then
  echo -e "\e[36mcopying ssh keys from the host...\e[0m"
  \mkdir -p ~/.ssh
  \cp /mnt/c/Users/$win_user/.ssh/id_* ~/.ssh/ 2>/dev/null
  chmod 400 ~/.ssh/id_*
fi

# *add github.com to known_hosts
if ! grep -qw 'github.com' ~/.ssh/known_hosts 2>/dev/null; then
  echo -e "\e[36madding github public keys...\e[0m"
  ssh-keyscan github.com 1>>~/.ssh/known_hosts 2>/dev/null
fi

# *setup source folder
# create folders
\mkdir -p ~/source/repos/$gh_user
\mkdir -p ~/source/workspaces
# create workspace file
if [ ! -f $ws_path ]; then
  echo -e "{\n\t\"folders\": [\n\t]\n}" >$ws_path
fi

# clone repositories and add them to workspace file
cd ~/source/repos/$gh_user
echo -e "\e[36mcloning repositories...\e[0m"
for repo in ${repos[@]}; do
  git clone "git@github.com:$gh_user/$repo.git" 2>/dev/null
  if [ -d "$repo" ] && ! grep -qw "$repo" $ws_path; then
    folder="\t{\n\t\t\t\"name\": \"$repo\",\n\t\t\t\"path\": \"..\/repos\/$gh_user\/$repo\"\n\t\t},\n\t"
    sed -i "s/\(\]\)/$folder\1/" $ws_path
  fi
done
