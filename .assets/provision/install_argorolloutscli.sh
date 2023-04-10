#!/usr/bin/env bash
: '
sudo .assets/provision/install_argorolloutscli.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='kubectl-argo-rollouts'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/argoproj/argo-rollouts/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    echo -e "\e[33m$APP version couldn't be retrieved\e[0m" >&2
    exit 0
  fi
  [ -n "$REL" ] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(kubectl-argo-rollouts version --short | grep -Po '(?<=v)[0-9\.]+')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[32m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[92minstalling $APP v$REL\e[0m" >&2
retry_count=0
while [[ ! -f kubectl-argo-rollouts-linux-amd64 && $retry_count -lt 10 ]]; do
  curl -LsOk "https://github.com/argoproj/argo-rollouts/releases/download/v${REL}/kubectl-argo-rollouts-linux-amd64"
  ((retry_count++))
done
install -o root -g root -m 0755 kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts && rm -f kubectl-argo-rollouts-linux-amd64
