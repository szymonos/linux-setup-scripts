# phase: bootstrap
# Root guard, path resolution, nix/jq detection, ENV_DIR sync, arg parsing.
# shellcheck disable=SC2034  # variables used by other phases
#
# Reads:  BASH_SOURCE (for path resolution)
# Writes: SCRIPT_ROOT, NIX_ENV_VERSION, NIX_SRC, CONFIGURE_DIR, ENV_DIR,
#         CONFIG_NIX, omp_theme, starship_theme, unattended, update_modules,
#         upgrade_packages, quiet_summary, remove_scopes, any_scope, _scope_set

phase_bootstrap_check_root() {
  if [[ $EUID -eq 0 ]]; then
    err "Do not run the script as root (sudo)."
    exit 1
  fi
}

phase_bootstrap_resolve_paths() {
  SCRIPT_ROOT="${1:?phase_bootstrap_resolve_paths requires repo root}"
  NIX_ENV_VERSION="$(git -C "$SCRIPT_ROOT" describe --tags --dirty 2>/dev/null \
    || cat "$SCRIPT_ROOT/VERSION" 2>/dev/null \
    || echo "unknown")"
  export NIX_ENV_VERSION
  NIX_SRC="$SCRIPT_ROOT/nix"
  CONFIGURE_DIR="$SCRIPT_ROOT/nix/configure"
  ENV_DIR="$HOME/.config/nix-env"
  CONFIG_NIX="$ENV_DIR/config.nix"
}

_source_nix_profile() {
  for nix_profile in \
    "$HOME/.nix-profile/etc/profile.d/nix.sh" \
    /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; do
    if [ -f "$nix_profile" ]; then
      # shellcheck source=/dev/null
      . "$nix_profile"
      return 0
    fi
  done
  return 1
}

# Check whether a GID and UID range [base, base+32) are all unassigned on macOS.
_darwin_id_range_free() {
  local base=$1
  local end=$((base + 31))
  dscl . -list /Groups PrimaryGroupID 2>/dev/null \
    | awk -v id="$base" '$NF == id {exit 1}' || return 1
  dscl . -list /Users UniqueID 2>/dev/null \
    | awk -v lo="$base" -v hi="$end" '$NF >= lo && $NF <= hi {exit 1}' || return 1
  return 0
}

_install_nix_darwin() {
  info "Nix is not installed. Attempting automatic installation on macOS..."

  local id_base=""
  local candidate
  # prefer < 500 (macOS system band - hidden from login screen by default)
  for candidate in 350 300 400 450 4000; do
    if _darwin_id_range_free "$candidate"; then
      id_base=$candidate
      break
    fi
    warn "GID/UID range $candidate is already in use, trying next..."
  done

  if [ -z "$id_base" ]; then
    _ir_error="Nix install failed: no free GID/UID range found"
    err "Could not find a free GID/UID range for Nix build users."
    err "Install Nix manually with a free range, e.g.:"
    err "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \\"
    err "    sh -s -- install --nix-build-group-id <GID> --nix-build-user-id-base <UID_BASE>"
    exit 1
  fi

  local install_args=(install --no-confirm)
  if [ "$id_base" -ne 350 ]; then
    install_args+=(--nix-build-group-id "$id_base" --nix-build-user-id-base "$id_base")
    info "using custom GID $id_base and UID base $id_base"
  fi

  _io_run curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- "${install_args[@]}"

  _source_nix_profile
  if ! command -v nix &>/dev/null && [ -x "$HOME/.nix-profile/bin/nix" ]; then
    export PATH="$HOME/.nix-profile/bin:$PATH"
  fi

  if ! command -v nix &>/dev/null; then
    _ir_error="Nix installation completed but nix command not found"
    err "Nix installation completed but 'nix' command is not available."
    err "Open a new terminal and run setup.sh again."
    exit 1
  fi
  ok "Nix installed successfully"
}

phase_bootstrap_detect_nix() {
  if ! command -v nix &>/dev/null; then
    _source_nix_profile || true
  fi
  if ! command -v nix &>/dev/null && [ -x "$HOME/.nix-profile/bin/nix" ]; then
    export PATH="$HOME/.nix-profile/bin:$PATH"
  fi
  if ! command -v nix &>/dev/null; then
    if [ "$(uname -s)" = "Darwin" ]; then
      _install_nix_darwin
    else
      _ir_error="Nix is not installed"
      err "Nix is not installed. Install it first (requires root, one-time):"
      err "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
      exit 1
    fi
  fi
}

phase_bootstrap_verify_store() {
  if ! _io_nix store info &>/dev/null; then
    _ir_error="nix store is unreachable"
    err "nix store is unreachable. Possible causes:"
    err "  - nix daemon is not running (check: systemctl status nix-daemon)"
    err "  - nix was installed without --no-daemon and systemd is missing"
    err "Reinstall nix if needed: https://install.determinate.systems/nix"
    exit 1
  fi
}

phase_bootstrap_sync_env_dir() {
  mkdir -p "$ENV_DIR"
  cp "$NIX_SRC/flake.nix" "$ENV_DIR/"
  cp -r "$NIX_SRC/scopes" "$ENV_DIR/"
  cp "$SCRIPT_ROOT/.assets/lib/nx_doctor.sh" "$ENV_DIR/"
  ok "synced nix declarations to $ENV_DIR"
}

phase_bootstrap_install_jq() {
  if ! command -v jq &>/dev/null; then
    info "first run - installing base packages via nix..."
    cat >"$CONFIG_NIX" <<BOOTSTRAP
{
  isInit = true;
  scopes = [];
}
BOOTSTRAP
    _io_nix profile add "path:$ENV_DIR" 2>/dev/null || true
    _io_nix profile upgrade nix-env ||
      { _ir_error="nix bootstrap failed"; err "$_ir_error"; exit 1; }
  fi
}

usage() {
  cat <<'EOF'
Usage: nix/setup.sh [options]

Additive: scope flags add to the existing config. Without scope flags,
re-applies configuration using existing package versions (idempotent).
Use --upgrade to pull latest packages from nixpkgs.

Scope flags (add new packages - merged with existing config):
  --az          Azure CLI + azcopy
  --bun         Bun JavaScript/TypeScript runtime
  --conda       Miniforge (conda-forge)
  --docker      Docker post-install check (Docker itself installed separately)
  --gcloud      Google Cloud CLI
  --k8s-base    kubectl, kubelogin, k9s, kubecolor, kubectx/kubens
  --k8s-dev     argo rollouts, cilium, flux, helm, hubble, kustomize, trivy
  --k8s-ext     minikube, k3d, kind
  --nodejs      Node.js
  --pwsh        PowerShell
  --python      uv + prek (python managed by uv/conda, not nix)
  --rice        btop, cmatrix, cowsay, fastfetch
  --shell       fzf, eza, bat, ripgrep, yq
  --terraform   terraform, tflint
  --zsh         zsh plugins (autosuggestions, syntax-highlighting, completions)
  --all         Enable all scopes above

Options:
  --remove <scope> [...]    Remove one or more scopes (space-separated)
  --upgrade                 Update flake.lock to latest nixpkgs and upgrade all packages
  --omp-theme <name>        Install oh-my-posh with theme (base, nerd, powerline, ...)
  --starship-theme <name>   Install starship with theme (base, nerd)
  --unattended              Skip all interactive steps (gh auth, SSH key, git config)
  --update-modules          Update installed PowerShell modules
  -h, --help                Show this help
EOF
}

phase_bootstrap_parse_args() {
  omp_theme=""
  starship_theme=""
  unattended="false"
  update_modules="false"
  quiet_summary="false"
  upgrade_packages="false"
  remove_scopes=()
  _scope_set=" "
  any_scope=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      _ir_skip=true
      usage
      exit 0
      ;;
    --az | --bun | --conda | --docker | --gcloud | --k8s-base | --k8s-dev | --k8s-ext | \
      --nodejs | --pwsh | --python | --rice | --shell | --terraform | --zsh)
      scope_add "${1#--}"
      any_scope=true
      ;;
    --all)
      for s in "${VALID_SCOPES[@]}"; do
        [[ "$s" == "oh_my_posh" || "$s" == "starship" ]] && continue
        scope_add "$s"
      done
      any_scope=true
      ;;
    --omp-theme)
      omp_theme="${2:-}"
      scope_add oh_my_posh
      any_scope=true
      shift
      ;;
    --starship-theme)
      starship_theme="${2:-}"
      scope_add starship
      any_scope=true
      shift
      ;;
    --remove)
      shift
      while [[ $# -gt 0 && "$1" != --* ]]; do
        remove_scopes+=("${1//-/_}")
        shift
      done
      if [[ ${#remove_scopes[@]} -eq 0 ]]; then
        err "--remove requires at least one scope name"
        usage
        exit 2
      fi
      continue
      ;;
    --unattended)
      unattended="true"
      ;;
    --update-modules)
      update_modules="true"
      ;;
    --upgrade)
      upgrade_packages="true"
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
  _scope_set="${_scope_set//-/_}"
}
