#!/usr/bin/env bash
: '
.assets/scripts/profile_setup.sh --theme powerline --ps_modules "do-common do-linux" --scope k8s_basic
.assets/scripts/profile_setup.sh --sys_upgrade true --theme powerline --ps_modules "do-common do-linux" --scope k8s_basic
'
if [[ $EUID -eq 0 ]]; then
  echo -e '\e[91mDo not run the script as root!\e[0m'
  exit 1
fi

# parse named parameters
theme=${theme:-base}
scope=${scope:-base}
sys_upgrade=${sys_upgrade:-false}
ps_modules=${ps_modules}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# set script working directory to workspace folder
SCRIPT_ROOT=$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd )
pushd "$( cd "${SCRIPT_ROOT}/../../" && pwd )" >/dev/null

# *Install packages and setup profiles
if $sys_upgrade; then
  echo -e "\e[96mupgrading system...\e[0m"
  sudo .assets/provision/upgrade_system.sh
fi
sudo .assets/provision/install_base.sh

if [[ "$scope" = @(k8s_basic|k8s_full) ]]; then
  echo -e "\e[96minstalling kubernetes base packages...\e[0m"
  sudo .assets/provision/install_kubectl.sh >/dev/null
  sudo .assets/provision/install_kubelogin.sh >/dev/null
  sudo .assets/provision/install_helm.sh >/dev/null
  sudo .assets/provision/install_minikube.sh >/dev/null
  sudo .assets/provision/install_k3d.sh >/dev/null
  sudo .assets/provision/install_k9s.sh >/dev/null
  sudo .assets/provision/install_yq.sh >/dev/null
fi
if [[ "$scope" = 'k8s_full' ]]; then
  echo -e "\e[96minstalling kubernetes additional packages...\e[0m"
  sudo .assets/provision/install_flux.sh
  sudo .assets/provision/install_kustomize.sh
  sudo .assets/provision/install_kubeseal.sh >/dev/null
  sudo .assets/provision/install_argorolloutscli.sh >/dev/null
fi
if [[ "$scope" = @(base|k8s_basic|k8s_full) ]]; then
  echo -e "\e[96minstalling base packages...\e[0m"
  sudo .assets/provision/install_omp.sh >/dev/null
  sudo .assets/provision/install_pwsh.sh >/dev/null
  sudo .assets/provision/install_bat.sh >/dev/null
  sudo .assets/provision/install_exa.sh >/dev/null
  sudo .assets/provision/install_ripgrep.sh >/dev/null
  .assets/provision/install_miniconda.sh
  echo -e "\e[96msetting up profile for all users...\e[0m"
  sudo .assets/provision/setup_omp.sh --theme $theme
  sudo .assets/provision/setup_profile_allusers.sh
  sudo .assets/provision/setup_profile_allusers.ps1
  echo -e "\e[96msetting up profile for current user...\e[0m"
  .assets/provision/setup_profile_user.sh
  .assets/provision/setup_profile_user.ps1
  if [[ -n "$ps_modules" ]]; then
    if [ ! -d ../ps-modules ]; then
      remote=$(git config --get remote.origin.url)
      git clone ${remote/vagrant-scripts/ps-modules} ../ps-modules
    fi
    echo -e "\e[96minstalling PowerShell modules...\e[0m"
    modules=($ps_modules)
    for mod in ${modules[@]}; do
      if [ "$mod" = 'do-common' ]; then
        sudo ../ps-modules/module_manage.ps1 "$mod" -CleanUp
      else
        ../ps-modules/module_manage.ps1 "$mod" -CleanUp
      fi
    done
  fi
fi

# restore working directory
popd >/dev/null
