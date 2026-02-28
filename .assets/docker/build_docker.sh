#!/usr/bin/env bash
# *Build Docker image locally.
: '
.assets/docker/build_docker.sh
'
set -e

# set script working directory to workspace folder
cd "$(readlink -f "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../../")"

target_repo='ps-modules'
# determine if target repository exists and clone if necessary
get_origin='git config --get remote.origin.url'
if [ -d "../$target_repo" ]; then
  pushd "../$target_repo" >/dev/null
  if eval $get_origin | grep -qw "github\.com[:/]szymonos/$target_repo"; then
    git fetch --prune --quiet
    git switch main --force --quiet
    git reset --hard --quiet origin/main
  else
    printf "\e[93manother \"$target_repo\" repository exists\e[0m\n"
    exit 1
  fi
  popd >/dev/null
else
  remote=$(eval $get_origin | sed "s/\([:/]szymonos\/\).*/\1$target_repo.git/")
  git clone $remote "../$target_repo"
fi

# build the image
cd .. && docker build -f linux-setup-scripts/.assets/docker/Dockerfile -t muscimol/pwsh .
