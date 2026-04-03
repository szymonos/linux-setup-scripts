#!/usr/bin/env bash
# Configure git defaults (cross-platform)
set -euo pipefail

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }

info "configuring git..."

if ! git config --global --get user.name >/dev/null 2>&1; then
  read -rp "provide git user name: " git_user
  git config --global user.name "$git_user"
fi
if ! git config --global --get user.email >/dev/null 2>&1; then
  read -rp "provide git user email: " git_email
  git config --global user.email "$git_email"
fi

git config --global core.eol lf
git config --global core.autocrlf input
git config --global core.longpaths true
git config --global push.autoSetupRemote true

ok "git configured"
