#!/usr/bin/env bash
: '
.assets/docker/build_docker.sh
'
# set script working directory to workspace folder
SCRIPT_ROOT=$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd )
pushd "$( cd "${SCRIPT_ROOT}/../../" && pwd )" >/dev/null

docker build -f .assets/docker/Dockerfile -t muscimol/pwsh .

# restore working directory
popd >/dev/null
