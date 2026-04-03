#!/usr/bin/env bash
: '
Universal dev environment setup - works on macOS, WSL/Linux, and Coder.
Uses Nix as the cross-platform package manager and scope-based nixfiles.
No root/sudo required - Nix must be pre-installed (see prerequisites below).

Idempotent: when run without scope flags, detects already installed packages,
upgrades them, and re-runs configuration. New packages are only added when
explicitly requested via scope flags.

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
NIX_DIR="$SCRIPT_ROOT/nix/nixfiles"
CONFIGURE_DIR="$SCRIPT_ROOT/nix/configure"

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
# 1. Detect Nix package manager (must be pre-installed)
# ============================================================================
if ! command -v nix &>/dev/null; then
  # try common install paths before giving up
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
else
  ok "Nix is already installed"
fi

# ============================================================================
# 2. Detect installed scopes from nix profile
# ============================================================================
# Build a set of currently installed package names from nix profile
installed_pkgs="$(nix profile list 2>/dev/null || true)"

# helper: check if any package from a nixfile is already installed
scope_is_installed() {
  local file="$1"
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [[ -z "$line" ]] && continue
    if echo "$installed_pkgs" | grep -qw "$line"; then
      return 0
    fi
  done < "$file"
  return 1
}

# Detect installed scopes and add them to scope_set
if [[ "$any_scope" == "false" ]]; then
  info "no scope flags provided - detecting installed packages..."
  for sc in "${VALID_SCOPES[@]}"; do
    nixfile="$NIX_DIR/$sc"
    if [[ -f "$nixfile" ]] && scope_is_installed "$nixfile"; then
      scope_set[$sc]=true
    fi
  done
  # detect tools installed outside nix that need configure scripts
  command -v oh-my-posh &>/dev/null && scope_set[oh_my_posh]=true || true
  command -v docker &>/dev/null && scope_set[docker]=true || true
  [[ -x "$HOME/.local/bin/uv" ]] && scope_set[python]=true || true
  command -v conda &>/dev/null && scope_set[conda]=true || true
  [[ -x "$HOME/.pixi/bin/pixi" ]] && scope_set[conda]=true || true
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
# 3. Upgrade existing or install new packages
# ============================================================================
if [[ "$any_scope" == "false" ]]; then
  # -- Upgrade mode: update all existing nix packages -----------------------
  info "upgrading all installed nix packages..."
  SECONDS=0
  nix profile upgrade --all || warn "nix profile upgrade completed with errors"
  ok "nix upgrade completed in ${SECONDS}s"
else
  # -- Install mode: collect and add new packages from nixfiles -------------
  info "assembling package list from selected scopes..."
  declare -a nix_packages=()

  # helper: read packages from a nixfile (skip comments and blank lines)
  read_nixfile() {
    local file="$1"
    while IFS= read -r line; do
      line="${line%%#*}"
      line="$(echo "$line" | xargs)"
      [[ -z "$line" ]] && continue
      nix_packages+=("nixpkgs#$line")
    done < "$file"
  }

  # always include base
  read_nixfile "$NIX_DIR/base"

  for sc in "${sorted_scopes[@]}"; do
    nixfile="$NIX_DIR/$sc"
    if [[ -f "$nixfile" ]]; then
      read_nixfile "$nixfile"
    else
      warn "no nixfile found for scope: $sc"
    fi
  done

  if (( ${#nix_packages[@]} > 0 )); then
    # filter out already-installed packages
    installed="$(nix profile list --json 2>/dev/null | jq -r '.elements | keys[]')"
    declare -a new_packages=()
    for pkg in "${nix_packages[@]}"; do
      pkg_name="${pkg#nixpkgs#}"
      if ! grep -qx "$pkg_name" <<< "$installed"; then
        new_packages+=("$pkg")
      fi
    done

    if (( ${#new_packages[@]} > 0 )); then
      info "installing ${#new_packages[@]} new packages via nix profile add (${#nix_packages[@]} total, $((${#nix_packages[@]} - ${#new_packages[@]})) already installed)..."
      SECONDS=0
      nix profile add "${new_packages[@]}" || warn "nix profile add completed with errors - re-run to retry failed packages"
      ok "nix install completed in ${SECONDS}s"
    else
      ok "all ${#nix_packages[@]} packages already installed, upgrading..."
      SECONDS=0
      nix profile upgrade --all || warn "nix profile upgrade completed with errors"
      ok "nix upgrade completed in ${SECONDS}s"
    fi
  else
    warn "no packages to install"
  fi
fi

# ============================================================================
# 4. GitHub CLI + authentication
# ============================================================================
"$CONFIGURE_DIR/gh.sh" "$skip_gh_auth" "$skip_gh_ssh_key"

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
