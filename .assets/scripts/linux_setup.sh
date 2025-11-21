#!/usr/bin/env bash
: '
# :set up the system using default values
.assets/scripts/linux_setup.sh
# :set up the system using specified values
scope="pwsh"
scope="k8s_base pwsh python"
scope="az docker k8s_base pwsh terraform nodejs"
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
# run the distro_check.sh script and capture the output
distro_check=$(.assets/provision/distro_check.sh array)

# initialize the scopes array
array=($scope)
# populate the scopes array based on the output of distro_check.sh
while IFS= read -r line; do
  array+=("$line")
done <<<"$distro_check"
# add corresponding scopes
grep -qw 'az' <<<${array[@]} && array+=(python) || true
grep -qw 'k8s_ext' <<<${array[@]} && array+=(docker) && array+=(k8s_base) || true
grep -qw 'pwsh' <<<${array[@]} && array+=(shell) || true
grep -qw 'zsh' <<<${array[@]} && array+=(shell) || true
# add oh_my_posh scope if necessary
if [[ -n "$omp_theme" || -f /usr/bin/oh-my-posh ]]; then
  array+=(oh_my_posh)
  array+=(shell)
fi
# remove duplicated and sort array
order=(
  docker
  k8s_base
  k8s_ext
  python
  conda
  az
  nodejs
  terraform
  oh_my_posh
  shell
  zsh
  pwsh
  distrobox
  rice
)
scope_arr=()
declare -A seen
for item in "${order[@]}"; do
  for val in "${array[@]}"; do
    if [[ "$item" == "$val" && -z "${seen[$item]}" ]]; then
      scope_arr+=("$item")
      seen[$item]=1
    fi
  done
done

# get distro name from os-release
. /etc/os-release
# display distro name and scopes to install
printf "\e[95m$NAME$([ -n "$scope_arr" ] && echo " : \e[3m${scope_arr[*]}" || true)\e[0m\n"

# *Install packages and setup profiles
if [ "$sys_upgrade" = true ]; then
  printf "\e[96mupdating system...\e[0m\n"
  sudo .assets/provision/upgrade_system.sh
fi
printf "\e[96minstalling base packages...\e[0m\n"
sudo .assets/provision/install_base.sh $user

# *setup GitHub CLI
if [ "$skip_gh_auth" = true ]; then
  printf "\e[32mSkipping gh installation and authentication setup.\e[0m\n" >&2
else
  sudo .assets/provision/install_gh.sh
  sudo .assets/provision/setup_gh_https.sh -u $user -k
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
  .assets/provision/setup_gh_ssh.sh 1>/dev/null
fi

for sc in ${scope_arr[@]}; do
  case $sc in
  az)
    printf "\e[96minstalling azure cli...\e[0m\n"
    .assets/provision/install_azurecli_uv.sh --fix_certify true
    sudo .assets/provision/install_azcopy.sh
    ;;
  conda)
    printf "\e[96minstalling python packages...\e[0m\n"
    .assets/provision/install_miniforge.sh --fix_certify true
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
  k8s_base)
    printf "\e[96minstalling kubernetes base packages...\e[0m\n"
    sudo .assets/provision/install_kubectl.sh >/dev/null
    sudo .assets/provision/install_kubelogin.sh >/dev/null
    sudo .assets/provision/install_cilium.sh >/dev/null
    sudo .assets/provision/install_helm.sh >/dev/null
    sudo .assets/provision/install_k9s.sh >/dev/null
    sudo .assets/provision/install_kubecolor.sh >/dev/null
    sudo .assets/provision/install_kubectx.sh >/dev/null
    sudo .assets/provision/install_flux.sh
    sudo .assets/provision/install_kustomize.sh
    ;;
  k8s_ext)
    printf "\e[96minstalling kubernetes additional packages...\e[0m\n"
    sudo .assets/provision/install_minikube.sh >/dev/null
    sudo .assets/provision/install_k3d.sh >/dev/null
    sudo .assets/provision/install_argorolloutscli.sh >/dev/null
    ;;
  nodejs)
    printf "\e[96minstalling Node.js...\e[0m\n"
    sudo .assets/provision/install_nodejs.sh >/dev/null
    ;;
  oh_my_posh)
    printf "\e[96minstalling oh-my-posh...\e[0m\n"
    sudo .assets/provision/install_omp.sh >/dev/null
    if [ -n "$omp_theme" ]; then
      sudo .assets/provision/setup_omp.sh --theme $omp_theme --user $user
    fi
    ;;
  pwsh)
    printf "\e[96minstalling pwsh...\e[0m\n"
    sudo .assets/provision/install_pwsh.sh >/dev/null
    printf "\e[96msetting up profile for all users...\e[0m\n"
    sudo .assets/provision/setup_profile_allusers.ps1 -UserName $user
    printf "\e[96msetting up profile for current user...\e[0m\n"
    .assets/provision/setup_profile_user.ps1
    ;;
  python)
    printf "\e[96minstalling python tools...\e[0m\n"
    sudo .assets/provision/setup_python.sh
    .assets/provision/install_uv.sh
    .assets/provision/install_prek.sh
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
    sudo .assets/provision/install_eza.sh >/dev/null
    sudo .assets/provision/install_bat.sh >/dev/null
    sudo .assets/provision/install_ripgrep.sh >/dev/null
    sudo .assets/provision/install_yq.sh >/dev/null
    ;;
  terraform)
    printf "\e[96minstalling terraform utils...\e[0m\n"
    sudo .assets/provision/install_terraform.sh
    sudo .assets/provision/install_tfswitch.sh
    sudo .assets/provision/install_terrascan.sh
    ;;
  zsh)
    printf "\e[96minstalling zsh...\e[0m\n"
    sudo .assets/provision/install_zsh.sh
    printf "\e[96msetting up zsh profile for current user...\e[0m\n"
    .assets/provision/setup_profile_user_zsh.sh
    ;;
  esac
done
# setup bash profiles
printf "\e[96msetting up profile for all users...\e[0m\n"
sudo .assets/provision/setup_profile_allusers.sh $user
printf "\e[96msetting up profile for current user...\e[0m\n"
.assets/provision/setup_profile_user.sh
# install powershell modules
if [ -f /usr/bin/pwsh ]; then
  cmnd="Import-Module (Resolve-Path './modules/InstallUtils'); Invoke-GhRepoClone -OrgRepo 'szymonos/ps-modules'"
  cloned=$(pwsh -nop -c $cmnd)
  if [ $cloned -gt 0 ]; then
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
