#!/usr/bin/env bash
# *Build Docker image locally.
: '
.assets/docker/build_docker.sh
'
# set script working directory to workspace folder
cd "$(readlink -f "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../../")"

# determine if ps-modules repository exist and clone if necessary
origin="$(git config --get remote.origin.url)"
remote=${origin/linux-setup-scripts/ps-modules}
if [ -d ../ps-modules ]; then
  pushd ../ps-modules >/dev/null
  if echo $remote | grep -Fqw 'szymonos/ps-modules.git'; then
    git fetch -q && git reset --hard -q "origin/$(git branch --show-current)"
  else
    modules=()
  fi
  popd >/dev/null
else
  git clone $remote ../ps-modules
fi

# build the image
cd .. && docker build -f linux-setup-scripts/.assets/docker/Dockerfile -t muscimol/pwsh .
