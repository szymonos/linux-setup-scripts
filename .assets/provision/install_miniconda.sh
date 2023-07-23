#!/usr/bin/env bash
: '
.assets/provision/install_miniconda.sh
.assets/provision/install_miniconda.sh --fix_certify true
'
if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n'
  exit 1
fi

# set script working directory to workspace folder
SCRIPT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)
pushd "$(cd "${SCRIPT_ROOT}/../../" && pwd)" >/dev/null

# parse named parameters
fix_certify=${fix_certify:-false}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# conda init function
function conda_init {
  __conda_setup="$("$HOME/miniconda3/bin/conda" 'shell.bash' 'hook' 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
      . "$HOME/miniconda3/etc/profile.d/conda.sh"
    else
      export PATH="$HOME/miniconda3/bin:$PATH"
    fi
  fi
  unset __conda_setup
}

if [ -d "$HOME/miniconda3" ]; then
  conda_init
  conda update -n base -c defaults conda --yes
  conda clean --yes --all
else
  printf "\e[92minstalling \e[1mminiconda\e[0m\n"

  retry_count=0
  while [[ ! -f miniconda.sh && $retry_count -lt 10 ]]; do
    curl -fsSLk -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    ((retry_count++))
  done
  bash ./miniconda.sh -b -p "$HOME/miniconda3" >/dev/null && rm ./miniconda.sh

  # disable auto activation of the base conda environment
  "$HOME/miniconda3/bin/conda" config --set auto_activate_base false
  # disable conda env prompt if oh-my-posh is installed
  if [ -f /usr/bin/oh-my-posh ]; then
    "$HOME/miniconda3/bin/conda" config --set changeps1 false
  fi
fi

#region fix conda certifi certs
# add self-signed certificates to conda base certify
if $fix_certify; then
  conda_init
  conda activate base
  .assets/provision/fix_certifi_certs.sh
  conda deactivate
fi
#endregion
