#!/usr/bin/env bash
# Uninstall nix-env managed environment and optionally Nix itself.
# Two-phase: (1) remove nix-env user state, (2) optionally remove Nix.
# Handles both Determinate Systems installer and upstream --no-daemon installs.
: '
# interactive uninstall (prompts before each phase)
nix/uninstall.sh
# non-interactive: remove nix-env only, keep Nix
nix/uninstall.sh --env-only
# non-interactive: remove everything including Nix
nix/uninstall.sh --all
# dry run - show what would be removed
nix/uninstall.sh --dry-run
'
set -eo pipefail

# -- Guard: no root -----------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
  printf '\e[31;1mDo not run the script as root (sudo).\e[0m\n'
  exit 1
fi

# -- Helpers -------------------------------------------------------------------
info()    { printf "\e[96m%s\e[0m\n" "$*"; }
ok()      { printf "\e[32m%s\e[0m\n" "$*"; }
warn()    { printf "\e[33m%s\e[0m\n" "$*" >&2; }
err()     { printf "\e[31;1m%s\e[0m\n" "$*" >&2; }
removed() { printf "\e[90m  removed %s\e[0m\n" "$*"; }
skipped() { printf "\e[90m  skipped %s (not found)\e[0m\n" "$*"; }

confirm() {
  local prompt="$1"
  printf "\e[93m%s [y/N] \e[0m" "$prompt"
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

_rm() {
  local target="$1"
  if [[ "$DRY_RUN" == "true" ]]; then
    [[ -e "$target" || -L "$target" ]] && printf "\e[90m  would remove %s\e[0m\n" "$target"
    return 0
  fi
  if [[ -L "$target" ]]; then
    rm -f "$target" && removed "$target"
  elif [[ -d "$target" ]]; then
    rm -rf "$target" && removed "$target"
  elif [[ -f "$target" ]]; then
    rm -f "$target" && removed "$target"
  else
    skipped "$target"
  fi
}

# Remove nix-managed #region blocks from a PowerShell profile file.
# Matches both new (nix:*) and old (base, nix, oh-my-posh, starship, uv) names.
# Leaves generic regions (certs, conda, make completer, etc.) untouched.
_clean_ps_nix_regions() {
  local ps_profile="$1"
  [[ -f "$ps_profile" ]] || return 0
  if grep -qE '#region (nix:|nix$|base$|oh-my-posh$|starship$|uv$)' "$ps_profile" 2>/dev/null; then
    if [[ "$DRY_RUN" == "true" ]]; then
      printf "\e[90m  would remove nix regions from %s\e[0m\n" "$ps_profile"
    else
      local tmp
      tmp="$(mktemp)"
      awk '
        /^#region nix:/ { skip=1; next }
        /^#region nix$/ { skip=1; next }
        /^#region base$/ { skip=1; next }
        /^#region oh-my-posh$/ { skip=1; next }
        /^#region starship$/ { skip=1; next }
        /^#region uv$/ { skip=1; next }
        skip && /^#endregion/ { skip=0; next }
        !skip { print }
      ' "$ps_profile" >"$tmp"
      if [[ ! -s "$tmp" ]] || ! grep -q '[^[:space:]]' "$tmp" 2>/dev/null; then
        rm -f "$ps_profile" "$tmp"
        ok "  removed $ps_profile (empty after cleanup)"
      else
        mv -f "$tmp" "$ps_profile"
        ok "  cleaned nix regions from $ps_profile"
      fi
    fi
  fi
}

# -- Parse args ----------------------------------------------------------------
MODE=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
  --env-only) MODE="env-only" ;;
  --all)      MODE="all" ;;
  --dry-run)  DRY_RUN="true" ;;
  -h | --help)
    cat <<'EOF'
Usage: nix/uninstall.sh [options]

Removes the nix-env managed environment and optionally Nix itself.

Modes:
  (default)     Interactive - prompts before each phase
  --env-only    Remove nix-env state only, keep Nix installed
  --all         Remove everything including Nix (non-interactive)
  --dry-run     Show what would be removed without doing anything

  -h, --help    Show this help
EOF
    exit 0
    ;;
  *)
    err "Unknown option: $1"
    exit 2
    ;;
  esac
  shift
done

# -- Resolve paths -------------------------------------------------------------
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$SCRIPT_ROOT/.assets/lib"
ENV_DIR="$HOME/.config/nix-env"
BLOCK_MARKER="nix-env managed"

printf "\n\e[95;1m>> nix-env uninstaller\e[0m\n\n"

if [[ "$DRY_RUN" == "true" ]]; then
  info "[dry-run mode - no changes will be made]"
  printf "\n"
fi

# ============================================================================
# Phase 1: Remove nix-env managed environment
# ============================================================================
run_phase1() {
  info "phase 1: removing nix-env managed environment..."

  # 1a. Remove nix-env managed block from shell rc files (leaves certs block)
  info "removing managed blocks from shell profiles..."
  if [[ -f "$LIB/profile_block.sh" ]]; then
    # shellcheck source=../.assets/lib/profile_block.sh
    source "$LIB/profile_block.sh"
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      [[ -f "$rc" ]] || continue
      if [[ "$DRY_RUN" == "true" ]]; then
        if manage_block "$rc" "$BLOCK_MARKER" inspect >/dev/null 2>&1; then
          printf "\e[90m  would remove managed block from %s\e[0m\n" "$rc"
        fi
      else
        if manage_block "$rc" "$BLOCK_MARKER" inspect >/dev/null 2>&1; then
          manage_block "$rc" "$BLOCK_MARKER" remove
          ok "  removed managed block from $rc"
        fi
      fi
    done
  else
    warn "profile_block.sh not found - falling back to manual block removal"
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      [[ -f "$rc" ]] || continue
      if grep -q "# >>> $BLOCK_MARKER >>>" "$rc" 2>/dev/null; then
        if [[ "$DRY_RUN" == "true" ]]; then
          printf "\e[90m  would remove managed block from %s\e[0m\n" "$rc"
        else
          local tmp
          tmp="$(mktemp)"
          awk -v begin="# >>> $BLOCK_MARKER >>>" -v end="# <<< $BLOCK_MARKER <<<" '
            $0 == begin { skip=1; next }
            skip && $0 == end { skip=0; next }
            !skip { print }
          ' "$rc" >"$tmp"
          mv -f "$tmp" "$rc"
          ok "  removed managed block from $rc"
        fi
      fi
    done
  fi

  # 1b. Remove legacy oh-my-posh/starship init lines outside managed block
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$rc" ]] || continue
    if grep -qE 'oh-my-posh init|starship init' "$rc" 2>/dev/null; then
      if [[ "$DRY_RUN" == "true" ]]; then
        printf "\e[90m  would remove legacy prompt init lines from %s\e[0m\n" "$(basename "$rc")"
      else
        local tmp
        tmp="$(mktemp)"
        awk '
          /^# (oh-my-posh|starship) prompt$/ { next }
          /oh-my-posh init/ { next }
          /starship init/ { next }
          { print }
        ' "$rc" >"$tmp"
        mv -f "$tmp" "$rc"
        ok "  removed legacy prompt init lines from $(basename "$rc")"
      fi
    fi
  done

  # 1c. Remove conda shell init blocks (conda init writes its own block)
  info "removing conda init blocks from shell profiles..."
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$rc" ]] || continue
    if grep -q '>>> conda initialize >>>' "$rc" 2>/dev/null; then
      if [[ "$DRY_RUN" == "true" ]]; then
        printf "\e[90m  would remove conda init block from %s\e[0m\n" "$(basename "$rc")"
      else
        local tmp
        tmp="$(mktemp)"
        awk '
          /# >>> conda initialize >>>/ { skip=1; next }
          skip && /# <<< conda initialize <<</ { skip=0; next }
          !skip { print }
        ' "$rc" >"$tmp"
        mv -f "$tmp" "$rc"
        ok "  removed conda init block from $(basename "$rc")"
      fi
    fi
  done

  # 1d. Remove nix:-prefixed PowerShell profile regions (keep generic ones)
  info "removing nix: regions from PowerShell profiles..."
  _clean_ps_nix_regions "$HOME/.config/powershell/profile.ps1"
  _clean_ps_nix_regions "$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"

  # 1e. Remove durable state directories and nix-specific config files
  info "removing nix-env config and state files..."
  _rm "$ENV_DIR"
  _rm "$HOME/.config/bash/aliases_nix.sh"
  rmdir "$HOME/.config/bash" 2>/dev/null || true
  _rm "$HOME/.config/powershell/Scripts/_aliases_nix.ps1"
  _rm "$HOME/.config/starship.toml"

  # 1f. Remove zsh plugins installed by profiles.zsh
  info "removing zsh plugins..."
  for plugin in zsh-autocomplete zsh-make-complete zsh-autosuggestions zsh-syntax-highlighting; do
    _rm "$HOME/.zsh/$plugin"
  done
  if [[ -d "$HOME/.zsh" ]] && [[ "$DRY_RUN" != "true" ]]; then
    rmdir "$HOME/.zsh" 2>/dev/null && removed "$HOME/.zsh (empty)" || true
  fi

  # 1g. Remove miniforge/conda if installed
  if [[ -d "$HOME/miniforge3" ]]; then
    info "removing miniforge3..."
    _rm "$HOME/miniforge3"
  fi

  # 1h. Remove nix profile entry (after all _rm calls - removing the profile
  #     earlier would break tools resolved through ~/.nix-profile/bin).
  if command -v nix &>/dev/null; then
    if nix profile list --json 2>/dev/null | grep -q 'nix-env' \
       || nix profile list 2>/dev/null | grep -q 'nix-env'; then
      if [[ "$DRY_RUN" == "true" ]]; then
        printf "\e[90m  would remove nix profile entry 'nix-env'\e[0m\n"
      else
        nix profile remove nix-env 2>/dev/null && ok "  removed nix profile entry 'nix-env'"
        hash -r
      fi
    fi
  fi

  # 1i. Remove nix profile symlink and local state
  _rm "$HOME/.nix-profile"
  _rm "$HOME/.local/state/nix"

  # 1j. Clean up nixenv backup files from shell rc files
  if [[ "$DRY_RUN" != "true" ]]; then
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      for backup in "${rc}.nixenv-backup-"*; do
        [[ -f "$backup" ]] && rm -f "$backup" && removed "$backup"
      done
    done
  fi

  # 1k. Strip trailing blank lines from rc files (bash builtins only -
  # external tools like awk/sed may have been removed with the nix profile).
  if [[ "$DRY_RUN" != "true" ]]; then
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      [[ -f "$rc" ]] || continue
      local content
      content="$(<"$rc")"
      # parameter expansion: remove trailing newlines (bash does this
      # naturally with command substitution), then write back with one.
      printf '%s\n' "$content" >"$rc"
    done
  fi

  ok "phase 1 complete - nix-env environment removed"
}

# ============================================================================
# Phase 2: Uninstall Nix itself
# ============================================================================
run_phase2() {
  info "phase 2: uninstalling Nix..."

  if [[ -x /nix/nix-installer ]]; then
    # Determinate Systems installer - has a built-in uninstaller
    info "detected Determinate Systems Nix installer"
    if [[ "$DRY_RUN" == "true" ]]; then
      printf "\e[90m  would run: sudo /nix/nix-installer uninstall\e[0m\n"
    else
      info "running: sudo /nix/nix-installer uninstall"
      info "(this will ask for your password and confirm before proceeding)"
      sudo /nix/nix-installer uninstall
    fi
  else
    # Single-user install (--no-daemon / upstream Nix installer).
    # Remove /nix only when the user has root access (they installed it
    # themselves). In pre-installed environments (Coder, CI) sudo is
    # unavailable and /nix must be left in place.
    info "detected single-user Nix install (no Determinate installer)"
    if [[ -d /nix ]] && sudo -n true 2>/dev/null; then
      if [[ "$DRY_RUN" == "true" ]]; then
        printf "\e[90m  would remove /nix\e[0m\n"
      else
        sudo rm -rf /nix && removed "/nix"
      fi
    elif [[ -d /nix ]]; then
      info "/nix left in place (no root access - pre-installed environment)"
    fi
  fi

  # clean up items common to both installer types
  _rm "$HOME/.nix-profile"
  _rm "$HOME/.nix-defexpr"
  _rm "$HOME/.nix-channels"
  _rm "$HOME/.local/state/nix"
  _rm "$HOME/.config/nix"

  ok "phase 2 complete - Nix uninstalled"
}

# ============================================================================
# Main
# ============================================================================
case "$MODE" in
env-only)
  run_phase1
  ;;
all)
  run_phase1
  run_phase2
  ;;
*)
  # Interactive mode
  if confirm "Remove nix-env managed environment? (shell configs, aliases, scopes)"; then
    run_phase1
  else
    info "skipping phase 1"
  fi
  printf "\n"
  if confirm "Uninstall Nix itself? (removes /nix, daemon, build users)"; then
    run_phase2
  else
    info "skipping phase 2 - Nix remains installed"
  fi
  ;;
esac

printf "\n\e[95;1m<< Uninstall complete >>\e[0m\n"
printf "\e[97mRestart your terminal for changes to take effect.\e[0m\n\n"
