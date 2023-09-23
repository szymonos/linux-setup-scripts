#!/usr/bin/env bash
: '
# :set up the system using default values
.assets/scripts/linux_setup.sh
# :set up the system using specified values
scope="shell"
scope="k8s_base python shell"
scope="az distrobox docker k8s_base k8s_ext python rice shell"
# :set up the system using the specified scope
.assets/scripts/linux_setup.sh --scope "$scope"
# :set up the system using the specified scope and omp theme
omp_theme="nerd"
.assets/scripts/linux_setup.sh --omp_theme "$omp_theme"
.assets/scripts/linux_setup.sh --omp_theme "$omp_theme" --scope "$scope"
# :upgrade system first and then set up the system
.assets/scripts/linux_setup.sh --sys_upgrade true --scope "$scope" --omp_theme "$omp_theme"
'
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

# *Calculate and show installation scopes
# convert scope string to array
array=($scope)
# determine scope for update if not provided
if [ -z "$array" ]; then
  [ -f /usr/bin/kubectl ] && array+=(k8s_base) || true
  [ -f /usr/bin/kustomize ] && array+=(k8s_ext) || true
  [ -f /usr/bin/pwsh ] && array+=(shell) || true
  [ -d "$HOME/miniconda3" ] && array+=(python) || true
fi
# add oh_my_posh scope if necessary
if [[ -n "$omp_theme" || -f /usr/bin/oh-my-posh ]]; then
  array+=(oh_my_posh)
  grep -qw 'shell' <<<${array[@]} || array+=(shell)
fi
# sort array
IFS=$'\n' scope_arr=($(sort <<<${array[*]})) && unset IFS
# get distro name from os-release
. /etc/os-release
# display distro name and scopes to install
printf "\e[95m$NAME$([ -n "$scope_arr" ] && echo " : \e[3m${scope_arr[*]}" || true)\e[0m\n"

# *Install packages and setup profiles
printf "\e[96mupdating system...\e[0m\n"
if $sys_upgrade; then
  sudo .assets/provision/upgrade_system.sh
fi
sudo .assets/provision/install_base.sh $user

for sc in ${scope_arr[@]}; do
  case $sc in
  distrobox)
    printf "\e[96minstalling distrobox...\e[0m\n"
    sudo .assets/provision/install_podman.sh
    sudo .assets/provision/install_distrobox.sh $user
    ;;
  docker)
    printf "\e[96minstalling docker...\e[0m\n"
    sudo .assets/provision/install_docker.sh $user
    ;;
  k8s_base)
    printf "\e[96minstalling kubernetes base packages...\e[0m\n"
    sudo .assets/provision/install_kubectl.sh >/dev/null
    sudo .assets/provision/install_kubelogin.sh >/dev/null
    sudo .assets/provision/install_helm.sh >/dev/null
    sudo .assets/provision/install_minikube.sh >/dev/null
    sudo .assets/provision/install_k3d.sh >/dev/null
    sudo .assets/provision/install_k9s.sh >/dev/null
    sudo .assets/provision/install_yq.sh >/dev/null
    ;;
  k8s_ext)
    printf "\e[96minstalling kubernetes additional packages...\e[0m\n"
    sudo .assets/provision/install_flux.sh
    sudo .assets/provision/install_kustomize.sh
    sudo .assets/provision/install_kubeseal.sh >/dev/null
    sudo .assets/provision/install_argorolloutscli.sh >/dev/null
    ;;
  oh_my_posh)
    printf "\e[96minstalling oh-my-posh...\e[0m\n"
    sudo .assets/provision/install_omp.sh >/dev/null
    if [ -n "$omp_theme" ]; then
      sudo .assets/provision/setup_omp.sh --theme $omp_theme --user $user
    fi
    ;;
  python)
    printf "\e[96minstalling python packages...\e[0m\n"
    .assets/provision/install_miniconda.sh --fix_certify true
    sudo .assets/provision/setup_python.sh
    grep -qw 'az' <<<$scope && .assets/provision/install_azurecli.sh --fix_certify true || true
    ;;
  rice)
    printf "\e[96mricing distro...\e[0m\n"
    sudo .assets/provision/install_btop.sh
    sudo .assets/provision/install_cmatrix.sh
    sudo .assets/provision/install_cowsay.sh
    sudo .assets/provision/install_fastfetch.sh
    ;;
  shell)
    printf "\e[96minstalling shell packages...\e[0m\n"
    sudo .assets/provision/install_pwsh.sh >/dev/null
    sudo .assets/provision/install_eza.sh >/dev/null
    sudo .assets/provision/install_bat.sh >/dev/null
    sudo .assets/provision/install_ripgrep.sh >/dev/null
    printf "\e[96msetting up profile for all users...\e[0m\n"
    sudo .assets/provision/setup_profile_allusers.sh $user
    sudo .assets/provision/setup_profile_allusers.ps1 -UserName $user
    printf "\e[96msetting up profile for current user...\e[0m\n"
    .assets/provision/setup_profile_user.sh
    .assets/provision/setup_profile_user.ps1
    ;;
  esac
done
# install powershell modules
if [ -f /usr/bin/pwsh ]; then
  cloned=$(.assets/tools/gh_repo_clone.ps1 -OrgRepo 'szymonos/ps-modules')
  if [ "$cloned" = "True" ]; then
    printf "\e[96minstalling ps-modules...\e[0m\n"
    # install do-common module for all users
    printf "\e[3;32mAllUsers\e[23m    : do-common\e[0m\n"
    sudo ../ps-modules/module_manage.ps1 'do-common' -CleanUp

    # determine current user scope modules to install
    modules=('do-linux')
    grep -qw 'az' <<<$scope && modules+=(do-az) || true
    [ -f /usr/bin/git ] && modules+=(aliases-git) || true
    [ -f /usr/bin/kubectl ] && modules+=(aliases-kubectl) || true
    # Convert the modules array to a comma-separated string with quoted elements
    printf "\e[3;32mCurrentUser\e[23m : ${modules[*]}\e[0m\n"
    mods=''
    for element in "${modules[@]}"; do
      mods="$mods'$element',"
    done
    pwsh -nop -c "@(${mods%,}) | ../ps-modules/module_manage.ps1 -CleanUp"
  else
    printf '\e[33mps-modules repository cloning failed\e[0m.\n'
  fi
fi

# restore working directory
popd >/dev/null
