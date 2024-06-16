#!/usr/bin/env bash
: '
.assets/provision/install_miniforge.sh
.assets/provision/install_miniforge.sh --fix_certify true
'
if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

# parse named parameters
fix_certify=${fix_certify:-false}
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

# *conda init function.
function conda_init {
  __conda_setup="$("$HOME/miniforge3/bin/conda" 'shell.bash' 'hook' 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
      . "$HOME/miniforge3/etc/profile.d/conda.sh"
    else
      export PATH="$HOME/miniforge3/bin:$PATH"
    fi
  fi
  unset __conda_setup
}

# *Install conda.
if [ -d "$HOME/miniforge3" ]; then
  conda_init
else
  printf "\e[92minstalling \e[1mminiforge\e[0m\n"
  TMP_DIR=$(mktemp -dp "$PWD")
  retry_count=0
  while [[ ! -f "$TMP_DIR/miniforge.sh" && $retry_count -lt 10 ]]; do
    curl -#Lko "$TMP_DIR/miniforge.sh" "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
    ((retry_count++))
  done
  bash $TMP_DIR/miniforge.sh -b -p "$HOME/miniforge3" >/dev/null
  rm -fr "$TMP_DIR"
  # disable auto activation of the base conda environment
  conda_init
  conda config --set auto_activate_base false
fi

# *Add certificates to conda base certifi.
if $fix_certify; then
  conda activate base
  .assets/provision/fix_certifi_certs.sh
  conda deactivate
fi

# *Update conda.
conda update --name base --channel conda-forge conda --yes --update-all
conda clean --yes --all

# *Fix certificates after update.
if $fix_certify; then
  conda activate base
  .assets/provision/fix_certifi_certs.sh
  conda deactivate
fi
