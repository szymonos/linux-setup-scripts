#!/usr/bin/env bash
: '
Universal dev environment setup - works on macOS, WSL/Linux, and Coder.
Uses Nix with a buildEnv flake for declarative, cross-platform package management.
No root/sudo required - Nix must be pre-installed (see prerequisites below).

Idempotent: when run without scope flags, upgrades all packages to latest
and re-runs configuration. New scopes are added when explicitly requested
via scope flags. Removing a scope from config.nix and re-running will
uninstall its packages automatically.

Prerequisites:
  # install Nix via the Determinate Systems installer (requires root, one-time)
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# :run without scope flags (upgrade existing + reconfigure)
nix/setup.sh
# :run with selected scopes (install new packages)
nix/setup.sh --pwsh
nix/setup.sh --k8s-base --pwsh --python --oh-my-posh --omp-theme "base"
nix/setup.sh --az --conda --k8s-base --pwsh --terraform --nodejs
nix/setup.sh --az --k8s-ext --rice --pwsh
# :run with oh-my-posh theme
nix/setup.sh --shell --oh-my-posh --omp-theme "base"
# :skip GitHub authentication
nix/setup.sh --az --skip-gh-auth true
# :skip GitHub SSH key registration
nix/setup.sh --az --skip-gh-ssh-key true
# :install everything
nix/setup.sh --all
# :show help
nix/setup.sh --help
'
set -euo pipefail

# -- Guard: no root ----------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
  printf '\e[31;1mDo not run the script as root (sudo).\e[0m\n'
  exit 1
fi

# -- Resolve script root -----------------------------------------------------
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NIX_SRC="$SCRIPT_ROOT/nix"
CONFIGURE_DIR="$SCRIPT_ROOT/nix/configure"
# durable config lives in the user's home -- persists after repo is removed
ENV_DIR="$HOME/.config/nix-env"
CONFIG_NIX="$ENV_DIR/config.nix"

# -- Helper functions --------------------------------------------------------
info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }
warn()  { printf "\e[33m%s\e[0m\n" "$*" >&2; }
err()   { printf "\e[31;1m%s\e[0m\n" "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: nix/setup.sh [options]

When run without scope flags, upgrades all existing nix packages and
re-runs configuration for detected tools (idempotent).

Scope flags (install new packages):
  --az          Azure CLI + azcopy
  --bun         Bun JavaScript/TypeScript runtime
  --conda       Miniforge + Pixi
  --docker      Docker post-install check (Docker itself installed separately)
  --gcloud      Google Cloud CLI
  --k8s-base    kubectl, kubelogin, k9s, kubecolor, kubectx/kubens
  --k8s-dev     argo rollouts, cilium, flux, helm, hubble, kustomize, trivy
  --k8s-ext     minikube, k3d, kind
  --nodejs      Node.js
  --oh-my-posh  oh-my-posh prompt
  --pwsh        PowerShell
  --python      uv + prek (python managed by uv/conda, not nix)
  --rice        btop, cmatrix, cowsay, fastfetch
  --shell       fzf, eza, bat, ripgrep, yq
  --terraform   terraform, tflint
  --zsh         zsh plugins (autosuggestions, syntax-highlighting, completions)
  --all         Enable all scopes above

Options:
  --omp-theme <name>        Set oh-my-posh theme (implies --oh-my-posh)
  --skip-gh-auth <bool>     Skip GitHub auth setup (default: false)
  --skip-gh-ssh-key <bool>  Skip adding SSH key to GitHub (default: false)
  --skip-git-config <bool>  Skip interactive git config setup (default: false)
  --update-modules          Update installed PowerShell modules
  -h, --help                Show this help
EOF
}

# -- Parse parameters --------------------------------------------------------
omp_theme=""
skip_gh_auth="false"
skip_gh_ssh_key="false"
skip_git_config="false"
update_modules="false"
quiet_summary="false"

# -- Bootstrap Nix + jq (needed before scopes.sh) ---------------------------
if ! command -v nix &>/dev/null; then
  for nix_profile in "$HOME/.nix-profile/etc/profile.d/nix.sh" /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; do
    if [[ -f "$nix_profile" ]]; then
      # shellcheck source=/dev/null
      . "$nix_profile"
      break
    fi
  done
fi
if ! command -v nix &>/dev/null; then
  err "Nix is not installed. Install it first (requires root, one-time):"
  err "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
  exit 1
fi
# start nix daemon if not running (containers without systemd)
if [[ ! -S /nix/var/nix/daemon-socket/socket ]]; then
  if [[ -x /nix/var/nix/profiles/default/bin/nix ]]; then
    info "starting nix daemon (no systemd detected)..."
    sudo /nix/var/nix/profiles/default/bin/nix daemon &>/dev/null &
    for _ in $(seq 1 30); do
      [[ -S /nix/var/nix/daemon-socket/socket ]] && break
      sleep 0.1
    done
  fi
fi
if ! command -v jq &>/dev/null; then
  info "bootstrapping jq via nix..."
  nix profile add nixpkgs#jq
fi

# -- Sync nix declarations to ~/.config/nix-env/ ----------------------------
# The repo is transient automation tooling; the user's ENV_DIR is durable state.
mkdir -p "$ENV_DIR"
cp "$NIX_SRC/flake.nix" "$ENV_DIR/"
cp -r "$NIX_SRC/scopes" "$ENV_DIR/"
ok "synced nix declarations to $ENV_DIR"

# -- Migrate from home-manager or imperative nix profile (one-time) ----------
# If the user previously used home-manager, clean up the HM profile.
if [[ -d "$HOME/.local/state/nix/profiles" ]] && ls "$HOME/.local/state/nix/profiles"/home-manager-*-link &>/dev/null 2>&1; then
  warn "detected home-manager profile -- cleaning up..."
  # remove home-manager-path from default profile if present
  if nix profile list --json 2>/dev/null | jq -e '.elements["home-manager-path"]' &>/dev/null; then
    nix profile remove home-manager-path 2>/dev/null || true
  fi
  # remove HM generations
  rm -f "$HOME/.local/state/nix/profiles"/home-manager* 2>/dev/null || true
  rm -rf "$HOME/.local/state/home-manager" 2>/dev/null || true
  ok "cleaned up home-manager artifacts"
fi

# If the user previously used imperative nix profile, clean automated packages
# so the buildEnv flake takes over. Custom user packages are preserved.
if nix profile list --json 2>/dev/null | jq -e '.elements | length > 0' &>/dev/null; then
  # collect automated package names from scope .nix files
  automated_pkgs=()
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && automated_pkgs+=("$pkg")
  done < <(grep -hE '^\s+[a-z][a-z0-9_-]+;?$' "$NIX_SRC/scopes"/*.nix 2>/dev/null | sed 's/^[[:space:]]*//;s/;$//' | sort -u)
  # get currently installed profile element names
  installed_elements="$(nix profile list --json 2>/dev/null | jq -r '.elements | keys[]')"
  # remove automated packages + bootstrapped tools from default profile
  migrated=false
  for pkg in "${automated_pkgs[@]}" jq home-manager; do
    if grep -qx "$pkg" <<< "$installed_elements"; then
      nix profile remove "$pkg" 2>/dev/null || true
      migrated=true
    fi
  done
  if [[ "$migrated" == "true" ]]; then
    ok "migrated automated packages to buildEnv flake (custom packages preserved)"
  fi
fi

# -- Ensure minimal config.nix exists for first bootstrap ------------------
if [[ ! -f "$CONFIG_NIX" ]]; then
  cat > "$CONFIG_NIX" <<MINCFG
{
  isInit = false;
  scopes = [];
}
MINCFG
fi

# -- Source shared scope library ----------------------------------------------
# shellcheck source=../.assets/lib/scopes.sh
source "$SCRIPT_ROOT/.assets/lib/scopes.sh"

declare -A scope_set
any_scope=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --az|--bun|--conda|--docker|--gcloud|--k8s-base|--k8s-dev|--k8s-ext|\
    --nodejs|--oh-my-posh|--pwsh|--python|--rice|--shell|--terraform|--zsh)
      scope_set[${1#--}]=true; any_scope=true
      ;;
    --all)
      for s in "${VALID_SCOPES[@]}"; do scope_set[$s]=true; done
      any_scope=true
      ;;
    --omp-theme)
      omp_theme="${2:-}"
      shift
      ;;
    --skip-gh-auth)
      skip_gh_auth="${2:-false}"
      shift
      ;;
    --skip-gh-ssh-key)
      skip_gh_ssh_key="${2:-false}"
      shift
      ;;
    --skip-git-config)
      skip_git_config="${2:-false}"
      shift
      ;;
    --update-modules)
      update_modules="true"
      ;;
    --quiet-summary)
      quiet_summary="true"
      ;;
    *)
      err "Unknown option: $1"
      usage
      exit 2
      ;;
  esac
  shift
done

# normalize hyphenated flag names to underscored scope names
for key in "${!scope_set[@]}"; do
  norm="${key//-/_}"
  if [[ "$key" != "$norm" ]]; then
    scope_set[$norm]="${scope_set[$key]}"
    unset "scope_set[$key]"
  fi
done

# -- Detect platform ---------------------------------------------------------
OS="$(uname -s)"
case "$OS" in
  Darwin) platform="macOS" ;;
  Linux)  platform="Linux" ;;
  *)      platform="$OS" ;;
esac

# ============================================================================
# 1. Detect existing scopes from config.nix (upgrade mode)
# ============================================================================
if [[ "$any_scope" == "false" ]]; then
  if [[ -f "$CONFIG_NIX" ]]; then
    info "no scope flags provided - loading scopes from config.nix..."
    # read existing scopes from the config.nix file
    while IFS= read -r sc; do
      [[ -n "$sc" ]] && scope_set[$sc]=true
    done < <(nix eval --raw --expr '
      let cfg = import '"$CONFIG_NIX"';
      in builtins.concatStringsSep "\n" cfg.scopes
    ' 2>&1) || warn "failed to read config.nix, falling back to system detection"
  else
    info "no scope flags provided and no config.nix found - detecting from system..."
    # fallback: detect tools installed outside nix that need configure scripts
    command -v oh-my-posh &>/dev/null && scope_set[oh_my_posh]=true || true
    command -v docker &>/dev/null && scope_set[docker]=true || true
    [[ -x "$HOME/.local/bin/uv" ]] && scope_set[python]=true || true
    command -v conda &>/dev/null && scope_set[conda]=true || true
    [[ -x "$HOME/.pixi/bin/pixi" ]] && scope_set[conda]=true || true
  fi
fi

# -- Resolve scope dependencies and build ordered list -----------------------
resolve_scope_deps
sort_scopes

printf "\n\e[95;1m>> Dev Environment Setup via Nix (%s)\e[0m" "$platform"
# shellcheck disable=SC2154  # sorted_scopes is populated by sort_scopes
if (( ${#sorted_scopes[@]} > 0 )); then
  printf " : \e[3;90m%s\e[0m" "${sorted_scopes[*]}"
fi
printf "\n\n"

# ============================================================================
# 2. Generate config.nix from resolved scopes
# ============================================================================
# determine init mode (macOS or Coder -- no system-installed curl/jq)
is_init=false
has_system_cmd() {
  local cmd_path
  cmd_path="$(command -v "$1" 2>/dev/null)" || return 1
  [[ "$cmd_path" != /nix/* && "$cmd_path" != */.nix-profile/* ]]
}
if ! has_system_cmd jq || ! has_system_cmd curl; then
  is_init=true
fi

# build the scopes list as a nix expression
nix_scopes=""
for sc in "${sorted_scopes[@]}"; do
  nix_scopes+="    \"$sc\""$'\n'
done

cat > "$CONFIG_NIX" <<EOF
# Generated by setup.sh -- do not edit manually.
# Re-run setup.sh with scope flags to change, or edit and run:
#   nix profile upgrade nix-env
{
  isInit = $is_init;

  scopes = [
$nix_scopes  ];
}
EOF

info "generated config.nix with ${#sorted_scopes[@]} scopes"

# ============================================================================
# 3. Apply configuration via nix profile
# ============================================================================
if [[ "$any_scope" == "false" ]]; then
  info "upgrading all packages to latest (nix flake update + profile upgrade)..."
else
  info "applying nix configuration..."
fi

SECONDS=0
# update flake.lock to get latest nixpkgs
nix flake update --flake "$ENV_DIR" 2>/dev/null || true
# check if nix-env is already installed in the profile
if nix profile list --json 2>/dev/null | jq -e '.elements["nix-env"]' &>/dev/null; then
  # upgrade the existing nix-env package (picks up scope changes + new nixpkgs)
  nix profile upgrade nix-env \
    || { err "nix profile upgrade failed"; exit 1; }
else
  # first install -- add the buildEnv flake to the profile
  nix profile add "path:$ENV_DIR" \
    || { err "nix profile add failed"; exit 1; }
fi
ok "nix profile updated in ${SECONDS}s"

# -- Detect and intercept MITM proxy certificates ---------------------------
if ! curl -sS https://www.google.com >/dev/null 2>&1 && command -v openssl &>/dev/null; then
  warn "SSL verification failed - MITM proxy detected, intercepting certificates..."
  # shellcheck source=../.assets/config/bash_cfg/functions.sh
  source "$SCRIPT_ROOT/.assets/config/bash_cfg/functions.sh"
  cert_intercept
fi

# ============================================================================
# 4. GitHub CLI + authentication
# ============================================================================
"$CONFIGURE_DIR/gh.sh" "$skip_gh_auth" "$skip_gh_ssh_key"
# export token for downstream scripts (copilot, etc.) to avoid API rate limits
if [[ -z "${GITHUB_TOKEN:-}" ]] && command -v gh &>/dev/null && gh auth token &>/dev/null; then
  export GITHUB_TOKEN="$(gh auth token 2>/dev/null)"
fi

# ============================================================================
# 5. Git configuration
# ============================================================================
if [[ "$skip_git_config" != "true" ]]; then
  "$CONFIGURE_DIR/git.sh"
fi

# ============================================================================
# 6. Scope-based post-install configuration
# ============================================================================
for sc in "${sorted_scopes[@]}"; do
  case $sc in
    docker)
      "$CONFIGURE_DIR/docker.sh"
      ;;
    conda)
      "$CONFIGURE_DIR/conda.sh"
      ;;
    az)
      "$CONFIGURE_DIR/az.sh"
      ;;
    oh_my_posh)
      "$CONFIGURE_DIR/omp.sh" "$omp_theme"
      ;;
  esac
done

# ============================================================================
# 7. Shell profile setup (always runs last)
# ============================================================================
"$CONFIGURE_DIR/profiles.sh"

# PowerShell profile setup (nix-specific PATH additions)
if command -v pwsh &>/dev/null; then
  "$CONFIGURE_DIR/profiles.ps1"
fi

# ============================================================================
# 8. Common post-install setup (copilot, zsh plugins, ps-modules, pixi)
# ============================================================================
common_args=()
[[ "$update_modules" == "true" ]] && common_args+=(--update-modules)
"$SCRIPT_ROOT/.assets/setup/setup_common.sh" "${common_args[@]}" "${sorted_scopes[@]}"

# ============================================================================
# 9. Summary
# ============================================================================
if [[ "$quiet_summary" != "true" ]]; then
  printf "\n\e[95;1m<< Setup completed successfully >>\e[0m\n"
  if [[ "$any_scope" == "false" ]]; then
    printf "\e[90mPlatform: %s | Mode: upgrade | Scopes: %s\e[0m\n" "$platform" "${sorted_scopes[*]}"
  else
    printf "\e[90mPlatform: %s | Mode: install | Scopes: %s\e[0m\n" "$platform" "${sorted_scopes[*]}"
  fi
  current_shell="$(basename "$SHELL")"
  case "$current_shell" in
    zsh)  printf "\e[97mRestart your terminal or run \e[4msource ~/.zshrc\e[24m to apply changes.\e[0m\n\n" ;;
    bash) printf "\e[97mRestart your terminal or run \e[4msource ~/.bashrc\e[24m to apply changes.\e[0m\n\n" ;;
    *)    printf "\e[97mRestart your terminal to apply changes.\e[0m\n\n" ;;
  esac
fi
