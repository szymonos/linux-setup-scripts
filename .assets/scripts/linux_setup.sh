#!/usr/bin/env bash
: '
# :set up the system using default values
.assets/scripts/linux_setup.sh
# :set up the system using specified values
scope="pwsh"
scope="k8s_base pwsh python"
scope="az docker k8s_base pwsh terraform bun"
scope="az distrobox k8s_ext rice pwsh"
# :set up the system using the specified scope
.assets/scripts/linux_setup.sh --scope "$scope"
# :set up the system using the specified scope and omp theme
omp_theme="base"
omp_theme="nerd"
.assets/scripts/linux_setup.sh --omp_theme "$omp_theme"
.assets/scripts/linux_setup.sh --omp_theme "$omp_theme" --scope "$scope"
# :upgrade system first and then set up the system
.assets/scripts/linux_setup.sh --sys_upgrade true --scope "$scope" --omp_theme "$omp_theme"
# :skip GitHub authentication setup
.assets/scripts/linux_setup.sh --skip_gh_auth true --scope "$scope" --omp_theme "$omp_theme"
'
set -e

if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n'
  exit 1
else
  user=$(id -un)
fi

# parse named parameters
scope=${scope}
omp_theme=${omp_theme}
sys_upgrade=${sys_upgrade:-false}
skip_gh_auth=${skip_gh_auth:-false}
update_modules="${update_modules:-false}"
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# set script working directory to workspace folder
SCRIPT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)
pushd "$(cd "${SCRIPT_ROOT}/../../" && pwd)" >/dev/null

# -- Source shared scope library ----------------------------------------------
# shellcheck source=../../.assets/lib/scopes.sh
source .assets/lib/scopes.sh

# *Calculate and show installation scopes
# run the check_distro.sh script and capture the output
distro_check=$(.assets/check/check_distro.sh array)

# build scope_set from CLI parameter and distro check
declare -A scope_set
read -ra cli_scopes <<<"$scope"
for s in "${cli_scopes[@]}"; do
  [[ -n "$s" ]] && scope_set[$s]=true
done
while IFS= read -r line; do
  [[ -n "$line" ]] && scope_set[$line]=true
done <<<"$distro_check"
# detect oh_my_posh from existing install
# shellcheck disable=SC2034  # scope_set is used by resolve_scope_deps
[[ -f /usr/bin/oh-my-posh ]] && scope_set[oh_my_posh]=true

# resolve dependencies and sort
resolve_scope_deps
sort_scopes
# shellcheck disable=SC2154  # sorted_scopes is populated by sort_scopes
scope_arr=("${sorted_scopes[@]}")

# get distro name from os-release
. /etc/os-release
# display distro name and scopes to install
printf "\e[95m$NAME$([ "${#scope_arr[@]}" -gt 0 ] && echo " : \e[3m${scope_arr[*]}" || true)\e[0m\n"

# *Install packages and setup profiles
if [ "$sys_upgrade" = true ]; then
  printf "\e[96mupdating system...\e[0m\n"
  sudo .assets/provision/upgrade_system.sh
fi
printf "\e[96minstalling base packages...\e[0m\n"
sudo .assets/provision/install_base.sh $user
# update pixi packages if pixi is installed
if grep -qw 'pixi' <<<"$distro_check"; then
  printf "\e[96mupdating pixi packages...\e[0m\n"
  "$HOME/.pixi/bin/pixi" global update
fi

# *setup GitHub CLI
if [ "$skip_gh_auth" = true ]; then
  printf "\e[32mSkipping gh installation and authentication setup.\e[0m\n" >&2
else
  sudo .assets/provision/install_gh.sh
  sudo .assets/setup/setup_gh_https.sh -u $user -k >/dev/null
  # generate SSH key if not exists
  if ! ([ -f "$HOME/.ssh/id_ed25519" ] && [ -f "$HOME/.ssh/id_ed25519.pub" ]); then
    # prepare clean $HOME/.ssh directory
    if [ -d "$HOME/.ssh" ]; then
      rm -f "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub"
    else
      mkdir "$HOME/.ssh" >/dev/null
    fi
    # generate new SSH key
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -q
  fi
  # add SSH key to GitHub
  .assets/setup/setup_gh_ssh.sh >/dev/null
fi

for sc in "${scope_arr[@]}"; do
  case $sc in
  az)
    printf "\e[96minstalling azure cli...\e[0m\n"
    .assets/provision/install_azurecli_uv.sh --fix_certify true
    sudo .assets/provision/install_azcopy.sh >/dev/null
    ;;
  bun)
    printf "\e[96minstalling bun...\e[0m\n"
    .assets/provision/install_bun.sh
    ;;
  conda)
    printf "\e[96minstalling python packages...\e[0m\n"
    .assets/provision/install_miniforge.sh --fix_certify true
    .assets/provision/install_pixi.sh
    ;;
  distrobox)
    printf "\e[96minstalling distrobox...\e[0m\n"
    sudo .assets/provision/install_podman.sh
    sudo .assets/provision/install_distrobox.sh $user
    ;;
  docker)
    printf "\e[96minstalling docker...\e[0m\n"
    sudo .assets/provision/install_docker.sh $user
    ;;
  gcloud)
    printf "\e[96minstalling google-cloud-cli...\e[0m\n"
    sudo .assets/provision/install_gcloud.sh >/dev/null
    sudo .assets/fix/fix_gcloud_certs.sh
    ;;
  k8s_base)
    printf "\e[96minstalling kubernetes base packages...\e[0m\n"
    sudo .assets/provision/install_kubectl.sh >/dev/null
    sudo .assets/provision/install_kubelogin.sh >/dev/null
    sudo .assets/provision/install_k9s.sh >/dev/null
    sudo .assets/provision/install_kubecolor.sh >/dev/null
    sudo .assets/provision/install_kubectx.sh >/dev/null
    ;;
  k8s_dev)
    printf "\e[96minstalling kubernetes dev packages...\e[0m\n"
    sudo .assets/provision/install_argorolloutscli.sh >/dev/null
    sudo .assets/provision/install_cilium.sh >/dev/null
    sudo .assets/provision/install_flux.sh >/dev/null
    sudo .assets/provision/install_helm.sh >/dev/null
    sudo .assets/provision/install_hubble.sh >/dev/null
    sudo .assets/provision/install_kustomize.sh >/dev/null
    sudo .assets/provision/install_trivy.sh >/dev/null
    ;;
  k8s_ext)
    printf "\e[96minstalling local kubernetes tools...\e[0m\n"
    sudo .assets/provision/install_minikube.sh >/dev/null
    sudo .assets/provision/install_k3d.sh >/dev/null
    sudo .assets/provision/install_kind.sh >/dev/null
    ;;
  nodejs)
    printf "\e[96minstalling Node.js...\e[0m\n"
    sudo .assets/provision/install_nodejs.sh
    ;;
  oh_my_posh)
    printf "\e[96minstalling oh-my-posh...\e[0m\n"
    sudo .assets/provision/install_omp.sh >/dev/null
    if [ -n "$omp_theme" ]; then
      sudo .assets/setup/setup_omp.sh --theme $omp_theme --user $user
    fi
    ;;
  pwsh)
    printf "\e[96minstalling pwsh...\e[0m\n"
    sudo .assets/provision/install_pwsh.sh >/dev/null
    printf "\e[96msetting up profile for all users...\e[0m\n"
    update_flag=""
    [ "$update_modules" = true ] && update_flag="-UpdateModules"
    sudo .assets/setup/setup_profile_allusers.ps1 -UserName $user $update_flag
    ;;
  python)
    printf "\e[96minstalling python tools...\e[0m\n"
    sudo .assets/setup/setup_python.sh
    .assets/provision/install_uv.sh >/dev/null
    .assets/provision/install_prek.sh >/dev/null
    ;;
  rice)
    printf "\e[96mricing distro...\e[0m\n"
    sudo .assets/provision/install_btop.sh
    sudo .assets/provision/install_cmatrix.sh
    sudo .assets/provision/install_cowsay.sh
    sudo .assets/provision/install_fastfetch.sh >/dev/null
    ;;
  shell)
    printf "\e[96minstalling shell packages...\e[0m\n"
    sudo .assets/provision/install_fzf.sh
    sudo .assets/provision/install_eza.sh >/dev/null
    sudo .assets/provision/install_bat.sh >/dev/null
    sudo .assets/provision/install_ripgrep.sh >/dev/null
    sudo .assets/provision/install_yq.sh >/dev/null
    ;;
  terraform)
    printf "\e[96minstalling terraform utils...\e[0m\n"
    sudo .assets/provision/install_terraform.sh >/dev/null
    sudo .assets/provision/install_terrascan.sh >/dev/null
    sudo .assets/provision/install_tflint.sh >/dev/null
    sudo .assets/provision/install_tfswitch.sh >/dev/null
    ;;
  zsh)
    printf "\e[96minstalling zsh...\e[0m\n"
    sudo .assets/provision/install_zsh.sh
    ;;
  esac
done
# setup bash profiles
printf "\e[96msetting up profile for all users...\e[0m\n"
sudo .assets/setup/setup_profile_allusers.sh $user
printf "\e[96msetting up profile for current user...\e[0m\n"
.assets/setup/setup_profile_user.sh
# install do-common module for all users (requires root)
if [ -f /usr/bin/pwsh ]; then
  cmnd="Import-Module (Resolve-Path './modules/InstallUtils'); Invoke-GhRepoClone -OrgRepo 'szymonos/ps-modules'"
  cloned=$(pwsh -nop -c "$cmnd")
  if [ $cloned -gt 0 ]; then
    printf "\e[3;32mAllUsers\e[23m    : do-common\e[0m\n"
    sudo ../ps-modules/module_manage.ps1 'do-common' -CleanUp
  else
    printf '\e[33mps-modules repository cloning failed\e[0m.\n'
  fi
fi
# common post-install setup (copilot, zsh plugins, ps-modules, pixi)
common_args=()
[ "$update_modules" = true ] && common_args+=(--update-modules)
.assets/setup/setup_common.sh "${common_args[@]}" "${scope_arr[@]}"

# restore working directory
popd >/dev/null
