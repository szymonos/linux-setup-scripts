#!/usr/bin/env bash
# Configure git defaults (cross-platform)
: '
nix/configure/git.sh
'
set -eo pipefail

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }

info "configuring git..."

if ! git config --global --get user.name >/dev/null 2>&1; then
  git_user=""
  if command -v gh &>/dev/null && gh auth status -h github.com &>/dev/null; then
    git_user="$(gh api user --jq '.name // empty' 2>/dev/null)"
  fi
  while [[ -z "$git_user" ]]; do
    read -rp "provide git user name: " git_user
  done
  git config --global user.name "$git_user"
fi
if ! git config --global --get user.email >/dev/null 2>&1; then
  git_email=""
  if command -v gh &>/dev/null && gh auth status -h github.com &>/dev/null; then
    git_email="$(gh api user --jq '.email // empty' 2>/dev/null)"
  fi
  while [[ -z "$git_email" ]]; do
    read -rp "provide git user email: " git_email
  done
  git config --global user.email "$git_email"
fi

git config --global core.eol lf
git config --global core.autocrlf input
git config --global core.longpaths true
git config --global push.autoSetupRemote true

ca_bundle="$HOME/.config/certs/ca-bundle.crt"
if [ -f "$ca_bundle" ]; then
  git config --global http.sslCAInfo "$ca_bundle"
  ok "git http.sslCAInfo set to $ca_bundle"
fi

ok "git configured"
