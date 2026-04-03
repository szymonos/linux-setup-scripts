#!/usr/bin/env bash
: '
Common post-install setup - runs after package installation and configure steps.
Called by nix/setup.sh, brew/setup.sh, and linux_setup.sh.
All operations are user-level (no root/sudo required).

Usage: .assets/setup/setup_common.sh [--update-modules] [scopes...]
Example: .assets/setup/setup_common.sh shell zsh az k8s_base pwsh
Example: .assets/setup/setup_common.sh --update-modules shell zsh pwsh
'
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }
warn()  { printf "\e[33m%s\e[0m\n" "$*" >&2; }

update_modules="false"
if [[ "${1:-}" == "--update-modules" ]]; then
  update_modules="true"
  shift
fi
scopes=("$@")

has_scope() {
  local s="$1"
  for sc in "${scopes[@]}"; do
    [[ "$sc" == "$s" ]] && return 0
  done
  return 1
}

# -- Copilot CLI (shell scope) ------------------------------------------------
if has_scope shell; then
  "$SCRIPT_ROOT/.assets/provision/install_copilot.sh"
fi

# -- Zsh plugins (zsh scope) --------------------------------------------------
if has_scope zsh && command -v zsh &>/dev/null; then
  info "setting up zsh profile for current user..."
  "$SCRIPT_ROOT/.assets/setup/setup_profile_user.zsh"
fi

# -- PowerShell user profile + modules (pwsh scope) ---------------------------
if has_scope pwsh && command -v pwsh &>/dev/null; then
  # setup PowerShell user profile
  info "setting up PowerShell profile for current user..."
  if [[ "$update_modules" == "true" ]]; then
    "$SCRIPT_ROOT/.assets/setup/setup_profile_user.ps1" -UpdateModules
  else
    "$SCRIPT_ROOT/.assets/setup/setup_profile_user.ps1"
  fi

  # clone/refresh ps-modules and install user-scope modules
  pushd "$SCRIPT_ROOT" >/dev/null
  cmnd="Import-Module (Resolve-Path './modules/InstallUtils'); Invoke-GhRepoClone -OrgRepo 'szymonos/ps-modules'"
  cloned=$(pwsh -nop -c "$cmnd")
  if [[ $cloned -gt 0 ]]; then
    info "installing ps-modules..."
    # determine current user scope modules to install
    modules=('do-linux')
    has_scope az && modules+=(do-az) || true
    command -v git &>/dev/null && modules+=(aliases-git) || true
    command -v kubectl &>/dev/null && modules+=(aliases-kubectl) || true
    printf "\e[3;32mCurrentUser\e[23m : %s\e[0m\n" "${modules[*]}"
    mods=''
    for element in "${modules[@]}"; do
      mods="$mods'$element',"
    done
    pwsh -nop -c "@(${mods%,}) | ../ps-modules/module_manage.ps1 -CleanUp"
  else
    warn "ps-modules repository cloning failed"
  fi
  popd >/dev/null
fi

# -- Pixi global update -------------------------------------------------------
if [[ -x "$HOME/.pixi/bin/pixi" ]]; then
  info "updating pixi packages..."
  "$HOME/.pixi/bin/pixi" global update
fi
