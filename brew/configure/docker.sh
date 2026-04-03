#!/usr/bin/env bash
# Post-install Docker configuration (platform-specific)
set -euo pipefail

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }
warn()  { printf "\e[33m%s\e[0m\n" "$*" >&2; }

if [[ "$(uname -s)" == "Darwin" ]]; then
  ok "Docker Desktop installed via cask - no additional configuration needed on macOS."
  exit 0
fi

# Linux: add current user to the docker group (requires sudo)
if command -v docker &>/dev/null; then
  if ! groups | grep -qw docker; then
    if command -v sudo &>/dev/null; then
      info "adding $(whoami) to the docker group..."
      sudo usermod -aG docker "$(whoami)"
      ok "added to docker group - log out and back in to apply"
    else
      warn "sudo not available; cannot add user to docker group"
    fi
  else
    ok "user already in docker group"
  fi
else
  warn "docker binary not found"
fi
