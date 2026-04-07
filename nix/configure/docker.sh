#!/usr/bin/env bash
# Post-install Docker configuration check (no root required)
set -euo pipefail

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }
warn()  { printf "\e[33m%s\e[0m\n" "$*" >&2; }

if [[ "$(uname -s)" == "Darwin" ]]; then
  ok "Docker Desktop should be installed separately on macOS."
  exit 0
fi

# Linux: check docker is available and user is in docker group
if command -v docker &>/dev/null; then
  if groups | grep -qw docker; then
    ok "docker is available and user is in docker group"
  else
    warn "docker is installed but $(whoami) is not in the docker group."
    warn "Run: sudo usermod -aG docker $(whoami)"
  fi
else
  warn "docker is not installed. Install it separately (requires root)."
fi
