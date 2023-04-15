#!/usr/bin/env bash
: '
# :set up the system using default values
.assets/scripts/profile_setup.sh
# :set up the system using specified values
.assets/scripts/profile_setup.sh --scope "az docker k8s_base k8s_ext python shell" --omp_theme nerd
# :upgrade system first and then set up the system
.assets/scripts/profile_setup.sh --sys_upgrade true --scope "az docker k8s_base k8s_ext python shell" --omp_theme nerd
'
if [ $EUID -eq 0 ]; then
  echo -e '\e[91mDo not run the script as root!\e[0m'
  exit 1
fi

# parse named parameters
scope=${scope:-'shell'}
omp_theme=${omp_theme}
ps_modules=${ps_modules:-'do-common do-linux'}
sys_upgrade=${sys_upgrade:-false}
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

# *Install packages and setup profiles
if $sys_upgrade; then
  echo -e "\e[96mupgrading system...\e[0m"
  sudo .assets/provision/upgrade_system.sh
fi
sudo .assets/provision/install_base.sh

# convert scope string to array
array=($scope)
# sort array
IFS=$'\n' scope_arr=($(sort <<<"${array[*]}"))
unset IFS
for sc in "${scope_arr[@]}"; do
  case $sc in
  docker)
    echo -e "\e[96minstalling docker...\e[0m"
    sudo .assets/provision/install_docker.sh
    ;;
  k8s_base)
    echo -e "\e[96minstalling kubernetes base packages...\e[0m"
    sudo .assets/provision/install_kubectl.sh >/dev/null
    sudo .assets/provision/install_kubelogin.sh >/dev/null
    sudo .assets/provision/install_helm.sh >/dev/null
    sudo .assets/provision/install_minikube.sh >/dev/null
    sudo .assets/provision/install_k3d.sh >/dev/null
    sudo .assets/provision/install_k9s.sh >/dev/null
    sudo .assets/provision/install_yq.sh >/dev/null
    ;;
  k8s_ext)
    echo -e "\e[96minstalling kubernetes additional packages...\e[0m"
    sudo .assets/provision/install_flux.sh
    sudo .assets/provision/install_kustomize.sh
    sudo .assets/provision/install_kubeseal.sh >/dev/null
    sudo .assets/provision/install_argorolloutscli.sh >/dev/null
    ;;
  python)
    echo -e "\e[96minstalling python packages...\e[0m"
    .assets/provision/install_miniconda.sh
    sudo .assets/provision/setup_python.sh
    grep -qw 'az' <<<$scope && .assets/provision/install_azurecli.sh --fix_certify true || true
    ;;
  shell)
    echo -e "\e[96minstalling shell packages...\e[0m"
    sudo .assets/provision/install_pwsh.sh >/dev/null
    sudo .assets/provision/install_exa.sh >/dev/null
    sudo .assets/provision/install_bat.sh >/dev/null
    sudo .assets/provision/install_ripgrep.sh >/dev/null
    echo -e "\e[96msetting up profile for all users...\e[0m"
    if [ -n "$omp_theme" ]; then
      sudo .assets/provision/install_omp.sh >/dev/null
      sudo .assets/provision/setup_omp.sh --theme $omp_theme
    fi
    sudo .assets/provision/setup_profile_allusers.sh
    sudo .assets/provision/setup_profile_allusers.ps1
    echo -e "\e[96msetting up profile for current user...\e[0m"
    .assets/provision/setup_profile_user.sh
    .assets/provision/setup_profile_user.ps1
    ;;
  esac
done
# install powershell modules
if [ -f /usr/bin/pwsh ]; then
  modules=($ps_modules)
  grep -qw 'az' <<<$scope && modules+=(do-az) || true
  [ -f /usr/bin/git ] && modules+=(aliases-git) || true
  [ -f /usr/bin/kubectl ] && modules+=(aliases-kubectl) || true
  if [ -n "$modules" ]; then
    echo -e "\e[96minstalling ps-modules...\e[0m"
    # determine if ps-modules repository exist and clone if necessary
    get_origin="git config --get remote.origin.url"
    origin=$(eval $get_origin)
    remote=${origin/vagrant-scripts/ps-modules}
    if [ -d ../ps-modules ]; then
      pushd ../ps-modules >/dev/null
      if [ "$(eval $get_origin)" = "$remote" ]; then
        git reset --hard --quiet && git clean --force -d && git pull --quiet
      else
        modules=()
      fi
      popd >/dev/null
    else
      git clone $remote ../ps-modules
    fi
    # install do-common module for all users
    if grep -qw 'do-common' <<<$ps_modules; then
      sudo ../ps-modules/module_manage.ps1 'do-common' -CleanUp
    fi
    # install rest of the modules for the current user
    modules=(${modules[@]/do-common/})
    if [ -n "$modules" ]; then
      # Convert the modules array to a comma-separated string with quoted elements
      mods=''
      for element in "${modules[@]}"; do
        mods="$mods'$element',"
      done
      pwsh -nop -c "@(${mods%,}) | ../ps-modules/module_manage.ps1 -CleanUp"
    fi
  fi
fi

# restore working directory
popd >/dev/null
