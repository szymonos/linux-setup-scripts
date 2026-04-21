#!/usr/bin/env bash
# Configure GitHub CLI authentication and SSH key (cross-platform)
: '
nix/configure/gh.sh
# skip all interactive steps (unattended mode)
nix/configure/gh.sh true
'
set -eo pipefail

unattended="${1:-false}"

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }
warn()  { printf "\e[33m%s\e[0m\n" "$*" >&2; }

if [[ "$unattended" == "true" ]]; then
  info "skipping GitHub authentication setup (unattended)."
  exit 0
fi

if ! command -v gh &>/dev/null; then
  warn "gh CLI not found - skipping GitHub authentication setup."
  exit 0
fi

# authenticate
info "setting up GitHub authentication..."
if gh auth status -h github.com &>/dev/null; then
  ok "already authenticated to GitHub"
elif gh auth token -h github.com &>/dev/null; then
  ok "GitHub device already authorized"
else
  gh auth login
fi

# SSH key
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ ! -f "$SSH_KEY" ]]; then
  info "generating SSH key..."
  mkdir -p "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -q
fi

# determine hostname label
if [[ "$(uname -s)" == "Darwin" ]]; then
  host_label="macOS $(hostname -s)"
else
  host_label="$(hostname -s)"
fi

# skip when auth comes from an external token (e.g. CI, containers) - can't control scopes
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  info "skipping SSH key registration (using external GITHUB_TOKEN)."
  exit 0
fi

# add SSH key to GitHub if not already registered
pub_key_fp=$(awk '{print $2}' "$SSH_KEY.pub")
if ! gh ssh-key list 2>/dev/null | grep -q "$pub_key_fp"; then
  info "adding SSH key to GitHub..."
  if ! gh ssh-key add "$SSH_KEY.pub" --title "$host_label $(date +%Y-%m-%d)"; then
    warn "SSH key add failed; attempting to refresh admin:public_key scope..."
    if gh auth refresh -h github.com -s admin:public_key; then
      gh ssh-key add "$SSH_KEY.pub" --title "$host_label $(date +%Y-%m-%d)" || warn "could not add SSH key after refresh"
    else
      warn "could not refresh admin:public_key scope"
    fi
  fi
else
  ok "SSH key already registered on GitHub"
fi
