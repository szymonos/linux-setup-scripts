#!/bin/bash
: '
.assets/scripts/install_profile.sh      #* install basic profile
.assets/scripts/install_profile.sh pl   #* install powerline profile
'
if [[ $EUID -eq 0 ]]; then
  echo -e '\e[91mDo not run the script with sudo!\e[0m'
  exit 1
fi

# *Install packages and setup profiles
sudo .assets/provision/install_base.sh
sudo .assets/provision/install_omp.sh
sudo .assets/provision/install_pwsh.sh
sudo .assets/provision/install_bat.sh
sudo .assets/provision/install_exa.sh
sudo .assets/provision/install_ripgrep.sh
sudo .assets/provision/setup_profiles_allusers.sh
.assets/provision/setup_profiles_user.sh

# *Copy config files
# calculate variables
if [[ "$1" = 'pl' ]]; then
  OMP_THEME='.assets/config/theme-pl.omp.json'
else
  OMP_THEME='.assets/config/theme.omp.json'
fi
SH_PROFILE_PATH='/etc/profile.d'
PS_PROFILE_PATH=$(pwsh -nop -c '[IO.Path]::GetDirectoryName($PROFILE.AllUsersAllHosts)')
PS_SCRIPTS_PATH='/usr/local/share/powershell/Scripts'
OH_MY_POSH_PATH='/usr/local/share/oh-my-posh'

# bash aliases
sudo \cp -f .assets/config/bash_aliases $SH_PROFILE_PATH
# oh-my-posh theme
sudo \mkdir -p $OH_MY_POSH_PATH
sudo \cp -f $OMP_THEME "$OH_MY_POSH_PATH/theme.omp.json"
# PowerShell profile
sudo \cp -f .assets/config/profile.ps1 $PS_PROFILE_PATH
# PowerShell functions
sudo \mkdir -p $PS_SCRIPTS_PATH
sudo \cp -f .assets/config/ps_aliases_common.ps1 $PS_SCRIPTS_PATH
# git functions
if type git &>/dev/null; then
  sudo \cp -f .assets/config/bash_aliases_git $SH_PROFILE_PATH
  sudo \cp -f .assets/config/ps_aliases_git.ps1 $PS_SCRIPTS_PATH
fi
# kubectl functions
if type -f kubectl &>/dev/null; then
  sudo \cp -f .assets/config/bash_aliases_kubectl $SH_PROFILE_PATH
  sudo \cp -f .assets/config/ps_aliases_kubectl.ps1 $PS_SCRIPTS_PATH
fi
