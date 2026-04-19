#!/usr/bin/env zsh
# Post-install zsh profile setup (cross-platform, Nix variant)
# Sets up: nix PATH, ~/.local/bin, aliases, fzf integration,
#           uv completions, kubectl completions, and zsh plugins
: '
nix/configure/profiles.zsh
'
set -euo pipefail

SCRIPT_ROOT="${0:A:h}"
REPO_ROOT="${SCRIPT_ROOT:h:h}"
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

info "configuring zsh profile..."

# create .zshrc if missing
[[ -f "$HOME/.zshrc" ]] || touch "$HOME/.zshrc"

# ---------------------------------------------------------------------------
# Copy alias/function files to durable location
# ---------------------------------------------------------------------------
_install_cfg_file() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] || return 0
  if ! cmp -s "$src" "$dst" 2>/dev/null; then
    mkdir -p "${dst:h}"
    cp -f "$src" "$dst"
  fi
}

_install_cfg_file "$BASH_CFG/aliases_nix.sh"     "$HOME/.config/bash/aliases_nix.sh"
_install_cfg_file "$BASH_CFG/aliases_git.sh"     "$HOME/.config/bash/aliases_git.sh"
_install_cfg_file "$BASH_CFG/aliases_kubectl.sh" "$HOME/.config/bash/aliases_kubectl.sh"
_install_cfg_file "$BASH_CFG/functions.sh"       "$HOME/.config/bash/functions.sh"

# ---------------------------------------------------------------------------
# Copy overlay shell config files (if overlay directory is active)
# ---------------------------------------------------------------------------
if [[ -n "${OVERLAY_DIR:-}" ]] && [[ -d "$OVERLAY_DIR/bash_cfg" ]]; then
  for _overlay_cfg in "$OVERLAY_DIR/bash_cfg"/*.sh; do
    [[ -f "$_overlay_cfg" ]] || continue
    _install_cfg_file "$_overlay_cfg" "$HOME/.config/bash/${_overlay_cfg:t}"
  done
fi

# ---------------------------------------------------------------------------
# Install zsh plugins (git clone / pull, not injected into managed block;
# the source lines go into the block below)
# ---------------------------------------------------------------------------
ZSH_PLUGIN_DIR="$HOME/.zsh"
mkdir -p "$ZSH_PLUGIN_DIR"

typeset -A ZSH_PLUGINS
ZSH_PLUGINS=(
  zsh-autocomplete        'https://github.com/marlonrichert/zsh-autocomplete.git'
  zsh-make-complete       'https://github.com/22peacemaker/zsh-make-complete.git'
  zsh-autosuggestions     'https://github.com/zsh-users/zsh-autosuggestions.git'
  zsh-syntax-highlighting 'https://github.com/zsh-users/zsh-syntax-highlighting.git'
)

typeset -A ZSH_PLUGIN_FILES
ZSH_PLUGIN_FILES=(
  zsh-autocomplete        'zsh-autocomplete.plugin.zsh'
  zsh-make-complete       'zsh-make-complete.plugin.zsh'
  zsh-autosuggestions     'zsh-autosuggestions.zsh'
  zsh-syntax-highlighting 'zsh-syntax-highlighting.zsh'
)

# ordered list for deterministic block output
ZSH_PLUGIN_ORDER=(zsh-autocomplete zsh-make-complete zsh-autosuggestions zsh-syntax-highlighting)

for plugin in "${ZSH_PLUGIN_ORDER[@]}"; do
  local url="${ZSH_PLUGINS[$plugin]}"
  if [[ -d "$ZSH_PLUGIN_DIR/$plugin" ]]; then
    git -C "$ZSH_PLUGIN_DIR/$plugin" pull --quiet 2>/dev/null || true
  else
    git clone --depth 1 "$url" "$ZSH_PLUGIN_DIR/$plugin"
    ok "installed zsh plugin: $plugin"
  fi
done

# ---------------------------------------------------------------------------
# Build the CA bundle and configure VS Code Server certs
# ---------------------------------------------------------------------------
build_ca_bundle
setup_vscode_certs

# ---------------------------------------------------------------------------
# Render the managed block content
# ---------------------------------------------------------------------------
_render_zsh_block() {
  printf '# :path\n'

  # 1. Nix profile script (sets NIX_SSL_CERT_FILE, XDG_DATA_DIRS, adds default bin)
  for nix_profile in \
    "$HOME/.nix-profile/etc/profile.d/nix.sh" \
    /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; do
    if [[ -f "$nix_profile" ]]; then
      printf '. %s\n' "$nix_profile"
      break
    fi
  done

  # 2. Nix profile PATH (prepend over nix-daemon defaults)
  if [[ -d "$HOME/.nix-profile/bin" ]]; then
    printf 'export PATH="$HOME/.nix-profile/bin:$PATH"\n'
  fi

  # 4. Nix aliases (generic aliases moved to managed env block)
  if [[ -f "$HOME/.config/bash/aliases_nix.sh" ]] && command -v nix &>/dev/null; then
    printf '\n# :aliases\n'
    printf '. "$HOME/.config/bash/aliases_nix.sh"\n'
  fi
  if [[ -f "$HOME/.config/bash/aliases_git.sh" ]] && [[ -x "$HOME/.nix-profile/bin/git" ]]; then
    printf '[ -f "$HOME/.config/bash/aliases_git.sh" ] && . "$HOME/.config/bash/aliases_git.sh"\n'
  fi
  if [[ -f "$HOME/.config/bash/aliases_kubectl.sh" ]] && [[ -x "$HOME/.nix-profile/bin/kubectl" ]]; then
    printf '[ -f "$HOME/.config/bash/aliases_kubectl.sh" ] && . "$HOME/.config/bash/aliases_kubectl.sh"\n'
  fi

  # 5. fzf integration
  if command -v fzf &>/dev/null; then
    printf '\n# :fzf\n'
    printf '[ -x "$HOME/.nix-profile/bin/fzf" ] && eval "$(fzf --zsh)"\n'
  fi

  # 6. uv / uvx completion
  if command -v uv &>/dev/null; then
    printf '\n# :uv\n'
    printf 'if [ -x "$HOME/.nix-profile/bin/uv" ]; then\n'
    printf '  export UV_SYSTEM_CERTS=true\n'
    printf '  eval "$(uv generate-shell-completion zsh)"\n'
    printf '  eval "$(uvx --generate-shell-completion zsh)"\n'
    printf 'fi\n'
  fi

  # 7. kubectl completion
  if command -v kubectl &>/dev/null; then
    printf '\n# :kubectl\n'
    printf 'if [ -x "$HOME/.nix-profile/bin/kubectl" ]; then\n'
    printf '  source <(kubectl completion zsh)\n'
    printf 'fi\n'
  fi

  # 8. oh-my-posh prompt
  if command -v oh-my-posh &>/dev/null && [[ -f "$HOME/.config/nix-env/omp/theme.omp.json" ]]; then
    printf '\n# :oh-my-posh\n'
    printf '[ -x "$HOME/.nix-profile/bin/oh-my-posh" ] && eval "$(oh-my-posh init zsh --config $HOME/.config/nix-env/omp/theme.omp.json)"\n'
  fi

  # 9. starship prompt
  if command -v starship &>/dev/null; then
    printf '\n# :starship\n'
    printf '[ -x "$HOME/.nix-profile/bin/starship" ] && eval "$(starship init zsh)"\n'
  fi

  # 10. zsh plugins
  printf '\n# :zsh plugins\n'
  for plugin in "${ZSH_PLUGIN_ORDER[@]}"; do
    local file="${ZSH_PLUGIN_FILES[$plugin]}"
    if [[ -f "$ZSH_PLUGIN_DIR/$plugin/$file" ]]; then
      printf 'source "$HOME/.zsh/%s/%s"\n' "$plugin" "$file"
    fi
  done

  # 11. keybindings
  printf '\n# :keybindings\n'
  printf "bindkey '^ ' autosuggest-accept\n"
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
  [[ -f "$rc" ]] || return 0
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

_cleanup_legacy_prompt "$HOME/.zshrc"

# migrate old cert-only markers
manage_block "$HOME/.zshrc" "nix-env certs" remove
manage_block "$HOME/.zshrc" "managed certs" remove

# remove both blocks to enforce ordering on re-append
manage_block "$HOME/.zshrc" "$BLOCK_MARKER" remove
manage_block "$HOME/.zshrc" "$ENV_BLOCK_MARKER" remove

render_env_block >"$ENV_TMP"
manage_block "$HOME/.zshrc" "$ENV_BLOCK_MARKER" upsert "$ENV_TMP"

_render_zsh_block >"$BLOCK_TMP"
manage_block "$HOME/.zshrc" "$BLOCK_MARKER" upsert "$BLOCK_TMP"

ok "zsh profile configured"
