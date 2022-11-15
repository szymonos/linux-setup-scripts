#!/bin/bash
: '
.assets/scripts/install_profile.sh #* base install
.assets/scripts/install_profile.sh --theme_font powerline --scope k8s_basic
'
if [[ $EUID -eq 0 ]]; then
  echo -e '\e[91mDo not run the script with sudo!\e[0m'
  exit 1
fi

# parse named parameters
theme_font=${theme_font:-base}
scope=${scope:-base}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# *Install packages and setup profiles
if [[ "$scope" = @(base|k8s_basic|k8s_full) ]]; then
  echo -e "\e[32minstalling base packages...\e[0m"
  sudo .assets/provision/install_base.sh
  sudo .assets/provision/install_omp.sh
  sudo .assets/provision/install_pwsh.sh
  sudo .assets/provision/install_bat.sh
  sudo .assets/provision/install_exa.sh
  sudo .assets/provision/install_ripgrep.sh
fi
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

# *Copy config files
echo -e "\e[32mcopying files...\e[0m"
# calculate variables
case $theme_font in
base)
  OMP_THEME='.assets/config/omp_cfg/theme.omp.json'
  ;;
powerline)
  OMP_THEME='.assets/config/omp_cfg/theme-pl.omp.json'
  ;;
esac
SH_PROFILE_PATH='/etc/profile.d'
PS_PROFILE_PATH=$(pwsh -nop -c '[IO.Path]::GetDirectoryName($PROFILE.AllUsersAllHosts)')
PS_SCRIPTS_PATH='/usr/local/share/powershell/Scripts'
OH_MY_POSH_PATH='/usr/local/share/oh-my-posh'

# bash aliases
sudo \cp -f .assets/config/bash_cfg/bash_aliases $SH_PROFILE_PATH
# oh-my-posh theme
sudo \mkdir -p $OH_MY_POSH_PATH
sudo \cp -f $OMP_THEME "$OH_MY_POSH_PATH/theme.omp.json"
# PowerShell profile
sudo \cp -f .assets/config/pwsh_cfg/profile.ps1 $PS_PROFILE_PATH
# PowerShell functions
sudo \mkdir -p $PS_SCRIPTS_PATH
sudo \cp -f .assets/config/pwsh_cfg/ps_aliases_common.ps1 $PS_SCRIPTS_PATH
# git functions
if type git &>/dev/null; then
  sudo \cp -f .assets/config/bash_cfg/bash_aliases_git $SH_PROFILE_PATH
  sudo \cp -f .assets/config/pwsh_cfg/ps_aliases_git.ps1 $PS_SCRIPTS_PATH
fi
# kubectl functions
if type -f kubectl &>/dev/null; then
  sudo \cp -f .assets/config/bash_cfg/bash_aliases_kubectl $SH_PROFILE_PATH
  sudo \cp -f .assets/config/pwsh_cfg/ps_aliases_kubectl.ps1 $PS_SCRIPTS_PATH
fi

# *setup profiles
echo -e "\e[32msetting up profile for all users...\e[0m"
sudo .assets/provision/setup_profiles_allusers.sh
sudo .assets/provision/setup_profiles_allusers.ps1
sudo .assets/provision/setup_omp.sh
echo -e "\e[32msetting up profile for current user...\e[0m"
.assets/provision/setup_profiles_user.sh
.assets/provision/setup_profiles_user.ps1
