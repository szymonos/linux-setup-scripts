#!/bin/bash
: '
.assets/scripts/profile_setup.sh --theme_font powerline --scope k8s_basic
.assets/scripts/profile_setup.sh --sys_upgrade true --theme_font powerline --scope k8s_basic
'
if [[ $EUID -eq 0 ]]; then
  echo -e '\e[91mDo not run the script with sudo!\e[0m'
  exit 1
fi

# parse named parameters
theme_font=${theme_font:-base}
scope=${scope:-base}
sys_upgrade=${sys_upgrade:-false}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# correct script working directory if needed
WORKSPACE_FOLDER=$(dirname "$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")")
[[ "$PWD" = "$WORKSPACE_FOLDER" ]] || cd "$WORKSPACE_FOLDER"

# *Install packages and setup profiles
if $sys_upgrade; then
  echo -e "\e[32mupgrading system...\e[0m"
  sudo .assets/provision/upgrade_system.sh
fi
sudo .assets/provision/install_base.sh

if [[ "$scope" = @(k8s_basic|k8s_full) ]]; then
  echo -e "\e[32minstalling kubernetes base packages...\e[0m"
  sudo .assets/provision/install_kubectl.sh
  sudo .assets/provision/install_helm.sh
  sudo .assets/provision/install_minikube.sh
  sudo .assets/provision/install_k3d.sh
  sudo .assets/provision/install_k9s.sh
  sudo .assets/provision/install_yq.sh
fi
if [[ "$scope" = 'k8s_full' ]]; then
  echo -e "\e[32minstalling kubernetes additional packages...\e[0m"
  sudo .assets/provision/install_flux.sh
  sudo .assets/provision/install_kubeseal.sh
  sudo .assets/provision/install_kustomize.sh
  sudo .assets/provision/install_argorolloutscli.sh
fi
if [[ "$scope" = @(base|k8s_basic|k8s_full) ]]; then
  echo -e "\e[32minstalling base packages...\e[0m"
  sudo .assets/provision/install_omp.sh
  sudo .assets/provision/install_pwsh.sh
  sudo .assets/provision/install_bat.sh
  sudo .assets/provision/install_exa.sh
  sudo .assets/provision/install_ripgrep.sh
  echo -e "\e[32msetting up profile for all users...\e[0m"
  sudo .assets/provision/setup_omp.sh --theme_font $theme_font
  sudo .assets/provision/setup_profiles_allusers.sh
  sudo .assets/provision/setup_profiles_allusers.ps1
  echo -e "\e[32msetting up profile for current user...\e[0m"
  .assets/provision/setup_profiles_user.sh
  .assets/provision/setup_profiles_user.ps1
fi
