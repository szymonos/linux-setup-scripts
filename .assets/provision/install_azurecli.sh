#!/usr/bin/env bash
: '
.assets/provision/install_azurecli.sh
.assets/provision/install_azurecli.sh --fix_certify true
'
set -euo pipefail

if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

# parse named parameters
fix_certify=${fix_certify:-false}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="${2:-}"
  fi
  shift
done

# check if conda installed
[ -f "$HOME/miniforge3/bin/conda" ] || exit 0

# >>> conda initialize >>>
if __conda_setup="$("$HOME/miniforge3/bin/conda" 'shell.bash' 'hook' 2>/dev/null)"; then
  eval "$__conda_setup"
else
  if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniforge3/etc/profile.d/conda.sh"
  else
    export PATH="$HOME/miniforge3/bin:$PATH"
  fi
fi
unset __conda_setup
# <<< conda initialize <<<

# install azure-cli in dedicated environment
if ! conda env list | grep -qw '^azurecli'; then
  if uname -r 2>&1 | grep -qw 'WSL2'; then
    conda create --name azurecli --yes python=3.13 pip
  else
    # https://github.com/conda/conda/issues/12051
    conda create --name azurecli --yes python=3.13 pip numpy==1.26.4 fonttools==4.53.0
  fi
fi
conda activate azurecli
pip install --upgrade azure-cli pip
conda clean --yes --all

# add certificates to azurecli certify
if $fix_certify; then
  .assets/provision/fix_azcli_certs.sh
fi

# deactivate azurecli conda environment
conda deactivate

# make symbolic link to az cli
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/miniforge3/envs/azurecli/bin/az" "$HOME/.local/bin/"
