#!/usr/bin/env bash
: '
Universal dev environment setup - works on macOS, WSL/Linux, and Coder.
Uses Homebrew as the cross-platform package manager and scope-based Brewfiles.

# :run with default scope (az, conda, docker, k8s-base, terraform)
brew/setup.sh
# :run with selected scopes
brew/setup.sh --pwsh
brew/setup.sh --k8s-base --pwsh --python --oh-my-posh --omp-theme "base"
brew/setup.sh --az --conda --docker --k8s-base --pwsh --terraform --nodejs
brew/setup.sh --az --docker --k8s-ext --rice --pwsh
# :run with oh-my-posh theme
brew/setup.sh --shell --oh-my-posh --omp-theme "base"
# :skip GitHub authentication
brew/setup.sh --az --skip-gh-auth true
# :skip GitHub SSH key registration
brew/setup.sh --az --skip-gh-ssh-key true
# :install everything
brew/setup.sh --all
# :show help
brew/setup.sh --help
'
set -euo pipefail

# -- Guard: no root ----------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
  printf '\e[31;1mDo not run the script as root (sudo).\e[0m\n'
  exit 1
fi

# -- Resolve script root -----------------------------------------------------
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREW_DIR="$SCRIPT_ROOT/brew/Brewfiles"
CONFIGURE_DIR="$SCRIPT_ROOT/brew/configure"

# -- Helper functions --------------------------------------------------------
info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }
warn()  { printf "\e[33m%s\e[0m\n" "$*" >&2; }
err()   { printf "\e[31;1m%s\e[0m\n" "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: brew/setup.sh [options]

Scope flags:
  --az          Azure CLI + azcopy
  --conda       Miniforge + Pixi
  --docker      Docker Desktop (macOS) / Docker CE (Linux)
  --gcloud      Google Cloud CLI
  --k8s-base    kubectl, kubelogin, k9s, kubecolor, kubectx/kubens
  --k8s-dev     argo rollouts, cilium, flux, helm, hubble, kustomize, trivy
  --k8s-ext     minikube, k3d, kind
  --nodejs      Node.js
  --oh-my-posh  oh-my-posh prompt
  --pwsh        PowerShell
  --python      python@3.13 + uv + prek
  --rice        btop, cmatrix, cowsay, fastfetch
  --shell       fzf, eza, bat, ripgrep, yq
  --terraform   terraform, tflint
  --zsh         zsh plugins (autosuggestions, syntax-highlighting, completions)
  --all         Enable all scopes above

Options:
  --omp-theme <name>        Set oh-my-posh theme (implies --oh-my-posh)
  --skip-gh-auth <bool>     Skip GitHub auth setup (default: false)
  --skip-gh-ssh-key <bool>  Skip adding SSH key to GitHub (default: false)
  --update-modules          Update installed PowerShell modules
  -h, --help                Show this help

Defaults:
  If no scope flags are provided, defaults to: --az --conda --docker --k8s-base --terraform
EOF
}

# -- Parse parameters --------------------------------------------------------
omp_theme=""
skip_gh_auth="false"
skip_gh_ssh_key="false"
update_modules="false"

# -- Bootstrap Homebrew + jq (needed before scopes.sh) -----------------------
if ! command -v brew &>/dev/null; then
  for brew_path in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew" /usr/local/bin/brew; do
    if [[ -x "$brew_path" ]]; then
      eval "$("$brew_path" shellenv)"
      break
    fi
  done
fi
if command -v brew &>/dev/null && ! command -v jq &>/dev/null; then
  info "bootstrapping jq via brew..."
  brew install jq
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
    --az|--conda|--docker|--gcloud|--k8s-base|--k8s-dev|--k8s-ext|\
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
    --update-modules)
      update_modules="true"
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

# default scope if none selected
if [[ "$any_scope" == "false" ]]; then
  scope_set[az]=true
  scope_set[conda]=true
  scope_set[docker]=true
  scope_set[k8s_base]=true
  scope_set[terraform]=true
fi

# shell is always included in the brew path
scope_set[shell]=true

# -- Resolve scope dependencies and build ordered list -----------------------
resolve_scope_deps
sort_scopes

# -- Detect platform ---------------------------------------------------------
OS="$(uname -s)"
case "$OS" in
  Darwin) platform="macOS" ;;
  Linux)  platform="Linux" ;;
  *)      platform="$OS" ;;
esac

printf "\n\e[95;1m>> Dev Environment Setup (%s)\e[0m" "$platform"
# shellcheck disable=SC2154  # sorted_scopes is populated by sort_scopes
if (( ${#sorted_scopes[@]} > 0 )); then
  printf " : \e[3;90m%s\e[0m" "${sorted_scopes[*]}"
fi
printf "\n\n"

# ============================================================================
# 1. Install Homebrew
# ============================================================================
if ! command -v brew &>/dev/null; then
  # try common install paths before downloading
  for brew_path in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew" /usr/local/bin/brew; do
    if [[ -x "$brew_path" ]]; then
      eval "$("$brew_path" shellenv)"
      break
    fi
  done
fi

if ! command -v brew &>/dev/null; then
  info "installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # add to current session
  for brew_path in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [[ -x "$brew_path" ]]; then
      eval "$("$brew_path" shellenv)"
      break
    fi
  done
else
  ok "Homebrew is already installed"
  brew update
fi

# ensure brew paths are available for this session
if command -v brew &>/dev/null; then
  BREW_PREFIX="$(brew --prefix)"
  export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"
  hash -r 2>/dev/null || true
fi

# configure brew retry for flaky networks
export HOMEBREW_CURL_RETRIES="${HOMEBREW_CURL_RETRIES:-5}"

# ============================================================================
# 2. Merge and install Brewfiles
# ============================================================================
info "assembling Brewfile from selected scopes..."
MERGED_BREWFILE="$(mktemp)"
trap 'rm -f "$MERGED_BREWFILE"' EXIT

# always include base
cat "$BREW_DIR/base" >> "$MERGED_BREWFILE"
echo "" >> "$MERGED_BREWFILE"

for sc in "${sorted_scopes[@]}"; do
  brewfile="$BREW_DIR/$sc"
  if [[ -f "$brewfile" ]]; then
    echo "# -- scope: $sc --" >> "$MERGED_BREWFILE"
    cat "$brewfile" >> "$MERGED_BREWFILE"
    echo "" >> "$MERGED_BREWFILE"
  else
    warn "no Brewfile found for scope: $sc"
  fi
done

info "installing packages via brew bundle..."
brew bundle --file="$MERGED_BREWFILE" || warn "brew bundle completed with errors - re-run to retry failed packages"

# ============================================================================
# 3. GitHub CLI + authentication
# ============================================================================
"$CONFIGURE_DIR/gh.sh" "$skip_gh_auth" "$skip_gh_ssh_key"

# ============================================================================
# 4. Git configuration
# ============================================================================
"$CONFIGURE_DIR/git.sh"

# ============================================================================
# 5. Scope-based post-install configuration
# ============================================================================
for sc in "${sorted_scopes[@]}"; do
  case $sc in
    docker)
      "$CONFIGURE_DIR/docker.sh"
      ;;
    python)
      "$CONFIGURE_DIR/python.sh"
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
# 6. Shell profile setup (always runs last)
# ============================================================================
"$CONFIGURE_DIR/profiles.sh"

# ============================================================================
# 7. Common post-install setup (copilot, zsh plugins, ps-modules, pixi)
# ============================================================================
common_args=()
[[ "$update_modules" == "true" ]] && common_args+=(--update-modules)
"$SCRIPT_ROOT/.assets/setup/setup_common.sh" "${common_args[@]}" "${sorted_scopes[@]}"

# ============================================================================
# 8. Summary
# ============================================================================
printf "\n\e[95;1m<< Setup completed successfully >>\e[0m\n"
printf "\e[90mPlatform: %s | Scopes: %s\e[0m\n" "$platform" "${sorted_scopes[*]}"
current_shell="$(basename "$SHELL")"
case "$current_shell" in
  zsh)  printf "\e[97mRestart your terminal or run \e[4msource ~/.zshrc\e[24m to apply changes.\e[0m\n\n" ;;
  bash) printf "\e[97mRestart your terminal or run \e[4msource ~/.bashrc\e[24m to apply changes.\e[0m\n\n" ;;
  *)    printf "\e[97mRestart your terminal to apply changes.\e[0m\n\n" ;;
esac
