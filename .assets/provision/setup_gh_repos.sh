#!/usr/bin/env bash
: '
.assets/provision/setup_gh_repos.sh --repos "szymonos/linux-setup-scripts szymonos/ps-modules"
.assets/provision/setup_gh_repos.sh --repos "szymonos/linux-setup-scripts szymonos/ps-modules" --ws_suffix "scripts"
'
# parse named parameters
repos=${repos}
ws_suffix=${ws_suffix:-devops}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# *calculate variables
gh_repos=($repos)
# calculate workspace name
if [ -n "$WSL_DISTRO_NAME" ]; then
  ID="$WSL_DISTRO_NAME"
  ws_suffix='wsl'
else
  . /etc/os-release
  ws_suffix='vm'
fi
ws_path="$HOME/source/workspaces/${ID,,}-${ws_suffix,,}.code-workspace"

# *setup source folder
# create folders
mkdir -p ~/source/repos
mkdir -p ~/source/workspaces
# create workspace file
if [ ! -f "$ws_path" ]; then
  printf "{\n\t\"folders\": [\n\t]\n}\n" >"$ws_path"
fi

# *clone repositories and add them to workspace file
cd ~/source/repos
for repo in ${gh_repos[@]}; do
  IFS='/' read -ra gh_path <<<"$repo"
  mkdir -p "${gh_path[0]}"
  pushd "${gh_path[0]}" >/dev/null
  git clone "https://github.com/${repo}.git" 2>/dev/null && echo $repo && cloned=true || true
  if ! grep -qw "$repo" "$ws_path" && [ -d "${gh_path[1]}" ]; then
    folder="\t{\n\t\t\t\"name\": \"${gh_path[1]}\",\n\t\t\t\"path\": \"..\/repos\/${repo/\//\\\/}\"\n\t\t},\n\t"
    sed -i "s/\(\]\)/$folder\1/" "$ws_path"
  fi
  popd >/dev/null
done

if [ -z "$cloned" ]; then
  printf "\e[32mall repos already cloned\e[0m\n"
fi
