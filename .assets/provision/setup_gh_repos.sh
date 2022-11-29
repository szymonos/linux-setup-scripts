#!/bin/bash
: '
.private/setup_gh_repos.sh --distro "Ubuntu" --repos "devops-scripts vagrant-scripts" --gh_user "szymonos" --win_user "szymo"
'
# parse named parameters
distro=${distro}
repos=${repos}
gh_user=${gh_user}
win_user=${win_user}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done
# calculate variables
ws_path="$HOME/source/workspaces/${distro,,}-devops.code-workspace"
gh_repos=($repos)

# *copy ssh keys on WSL
if [[ -n $WSL_DISTRO_NAME ]]; then
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
for repo in ${gh_repos[@]}; do
  git clone "git@github.com:$gh_user/$repo.git" 2>/dev/null
  if [ -d "$repo" ] && ! grep -qw "$repo" $ws_path; then
    folder="\t{\n\t\t\t\"name\": \"$repo\",\n\t\t\t\"path\": \"..\/repos\/$gh_user\/$repo\"\n\t\t},\n\t"
    sed -i "s/\(\]\)/$folder\1/" $ws_path
  fi
done
