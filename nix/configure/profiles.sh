#!/usr/bin/env bash
# Post-install bash profile setup (cross-platform, Nix variant)
# Sets up: nix PATH, aliases, fzf integration, completions,
: '
nix/configure/profiles.sh
'
#           uv completions, make completions, kubectl completions
set -eo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_ROOT/../.." && pwd)"
LIB="$REPO_ROOT/.assets/lib"

info() { printf "\e[96m%s\e[0m\n" "$*"; }
ok()   { printf "\e[32m%s\e[0m\n" "$*"; }

# shellcheck source=../../.assets/lib/profile_block.sh
source "$LIB/profile_block.sh"
# shellcheck source=../../.assets/lib/env_block.sh
source "$LIB/env_block.sh"
# shellcheck source=../../.assets/lib/certs.sh
source "$LIB/certs.sh"

BLOCK_MARKER="nix-env managed"
BASH_CFG="$REPO_ROOT/.assets/config/bash_cfg"

info "configuring bash profile..."

# create .bashrc if missing
[ -f "$HOME/.bashrc" ] || touch "$HOME/.bashrc"

# ---------------------------------------------------------------------------
# Copy alias/function files to durable location
# ---------------------------------------------------------------------------
_install_cfg_file() {
  local src="$1" dst="$2"
  [ -f "$src" ] || return 0
  if ! cmp -s "$src" "$dst" 2>/dev/null; then
    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst"
  fi
}

_install_cfg_file "$BASH_CFG/aliases_nix.sh"    "$HOME/.config/bash/aliases_nix.sh"
_install_cfg_file "$BASH_CFG/aliases_git.sh"    "$HOME/.config/bash/aliases_git.sh"
_install_cfg_file "$BASH_CFG/aliases_kubectl.sh" "$HOME/.config/bash/aliases_kubectl.sh"
_install_cfg_file "$BASH_CFG/functions.sh"      "$HOME/.config/bash/functions.sh"

# ---------------------------------------------------------------------------
# Copy overlay shell config files (if overlay directory is active)
# ---------------------------------------------------------------------------
if [ -n "${OVERLAY_DIR:-}" ] && [ -d "$OVERLAY_DIR/bash_cfg" ]; then
  for _overlay_cfg in "$OVERLAY_DIR/bash_cfg"/*.sh; do
    [ -f "$_overlay_cfg" ] || continue
    _install_cfg_file "$_overlay_cfg" "$HOME/.config/bash/$(basename "$_overlay_cfg")"
  done
fi

# ---------------------------------------------------------------------------
# Build the CA bundle and configure VS Code Server certs
# ---------------------------------------------------------------------------
build_ca_bundle
setup_vscode_certs

# ---------------------------------------------------------------------------
# Render the managed block content
# ---------------------------------------------------------------------------
_render_bash_block() {
  printf '# :path\n'

  # 1. Nix profile script (sets NIX_SSL_CERT_FILE, XDG_DATA_DIRS, adds default bin)
  for nix_profile in \
    "$HOME/.nix-profile/etc/profile.d/nix.sh" \
    /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; do
    if [ -f "$nix_profile" ]; then
      printf '. %s\n' "$nix_profile"
      break
    fi
  done

  # 2. Nix profile PATH (prepend over nix-daemon defaults)
  if [ -d "$HOME/.nix-profile/bin" ]; then
    printf 'export PATH="$HOME/.nix-profile/bin:$PATH"\n'
  fi

  # 3. Override NIX_SSL_CERT_FILE with merged CA bundle (MITM proxy support)
  if [ -f "$HOME/.config/certs/ca-bundle.crt" ]; then
    printf 'export NIX_SSL_CERT_FILE="$HOME/.config/certs/ca-bundle.crt"\n'
  fi

  # 4. Nix aliases (generic aliases moved to managed env block)
  if [ -f "$HOME/.config/bash/aliases_nix.sh" ] && command -v nix &>/dev/null; then
    printf '\n# :aliases\n'
    printf '. "$HOME/.config/bash/aliases_nix.sh"\n'
  fi
  if [ -f "$HOME/.config/bash/aliases_git.sh" ] && [ -x "$HOME/.nix-profile/bin/git" ]; then
    printf '[ -f "$HOME/.config/bash/aliases_git.sh" ] && . "$HOME/.config/bash/aliases_git.sh"\n'
  fi
  if [ -f "$HOME/.config/bash/aliases_kubectl.sh" ] && [ -x "$HOME/.nix-profile/bin/kubectl" ]; then
    printf '[ -f "$HOME/.config/bash/aliases_kubectl.sh" ] && . "$HOME/.config/bash/aliases_kubectl.sh"\n'
  fi

  # 5. fzf integration
  if [ -x "$HOME/.nix-profile/bin/fzf" ]; then
    printf '\n# :fzf\n'
    printf '[ -x "$HOME/.nix-profile/bin/fzf" ] && eval "$(fzf --bash)"\n'
  fi

  # 6. uv / uvx completion
  if [ -x "$HOME/.nix-profile/bin/uv" ]; then
    printf '\n# :uv\n'
    printf 'if [ -x "$HOME/.nix-profile/bin/uv" ]; then\n'
    printf '  export UV_SYSTEM_CERTS=true\n'
    printf '  eval "$(uv generate-shell-completion bash)"\n'
    printf '  eval "$(uvx --generate-shell-completion bash)"\n'
    printf 'fi\n'
  fi

  # 7. kubectl completion
  if [ -x "$HOME/.nix-profile/bin/kubectl" ]; then
    printf '\n# :kubectl\n'
    printf 'if [ -x "$HOME/.nix-profile/bin/kubectl" ]; then\n'
    printf '  source <(kubectl completion bash)\n'
    printf '  complete -o default -F __start_kubectl k\n'
    printf 'fi\n'
  fi

  # 8. make completion
  # shellcheck disable=SC2016
  printf '\n# :make\n'
  printf 'complete -W "$(if [ -f Makefile ]; then grep -oE '\''^[a-zA-Z0-9_-]+:([^=]|$)'\'' Makefile | sed '\''s/[^a-zA-Z0-9_-]*$//'\''
elif [ -f makefile ]; then grep -oE '\''^[a-zA-Z0-9_-]+:([^=]|$)'\'' makefile | sed '\''s/[^a-zA-Z0-9_-]*$//'\''
fi)" make\n'

  # 9. oh-my-posh prompt
  if [ -x "$HOME/.nix-profile/bin/oh-my-posh" ] && [ -f "$HOME/.config/nix-env/omp/theme.omp.json" ]; then
    printf '\n# :oh-my-posh\n'
    # shellcheck disable=SC2016
    printf '[ -x "$HOME/.nix-profile/bin/oh-my-posh" ] && eval "$(oh-my-posh init bash --config $HOME/.config/nix-env/omp/theme.omp.json)"\n'
  fi

  # 10. starship prompt
  if [ -x "$HOME/.nix-profile/bin/starship" ]; then
    printf '\n# :starship\n'
    # shellcheck disable=SC2016
    printf '[ -x "$HOME/.nix-profile/bin/starship" ] && eval "$(starship init bash)"\n'
  fi
}

# ---------------------------------------------------------------------------
# Generic env block (local path + cert env vars) from env_block.sh.
# Not nix-specific - survives nix-env uninstall.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Clean up legacy prompt init lines (now rendered inside managed block)
# ---------------------------------------------------------------------------
_cleanup_legacy_prompt() {
  local rc="$1"
  [ -f "$rc" ] || return 0
  if grep -qE 'oh-my-posh init|starship init' "$rc" 2>/dev/null; then
    local tmp
    tmp="$(mktemp)"
    awk '
      /^# (oh-my-posh|starship) prompt$/ { next }
      /oh-my-posh init/ { next }
      /starship init/ { next }
      { print }
    ' "$rc" >"$tmp"
    mv -f "$tmp" "$rc"
  fi
}

# ---------------------------------------------------------------------------
# Write the managed blocks (managed env first - generic/persistent,
# nix-env managed second - added/removed with nix)
# ---------------------------------------------------------------------------
BLOCK_TMP="$(mktemp)"
ENV_TMP="$(mktemp)"
trap 'rm -f "$BLOCK_TMP" "$ENV_TMP"' EXIT

_cleanup_legacy_prompt "$HOME/.bashrc"

# migrate old cert-only markers
manage_block "$HOME/.bashrc" "nix-env certs" remove
manage_block "$HOME/.bashrc" "managed certs" remove

# remove both blocks to enforce ordering on re-append
manage_block "$HOME/.bashrc" "$BLOCK_MARKER" remove
manage_block "$HOME/.bashrc" "$ENV_BLOCK_MARKER" remove

render_env_block >"$ENV_TMP"
manage_block "$HOME/.bashrc" "$ENV_BLOCK_MARKER" upsert "$ENV_TMP"

_render_bash_block >"$BLOCK_TMP"
manage_block "$HOME/.bashrc" "$BLOCK_MARKER" upsert "$BLOCK_TMP"

ok "bash profile configured"
