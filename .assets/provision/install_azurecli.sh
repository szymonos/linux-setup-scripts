#!/usr/bin/env bash
: '
.assets/provision/install_azurecli.sh
.assets/provision/install_azurecli.sh --fix_certify true
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

# check if conda installed
[ -f "$HOME/miniconda3/bin/conda" ] || exit 0

# >>> conda initialize >>>
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
# <<< conda initialize <<<

# install azure-cli in dedicated environment
if ! conda env list | grep -qw '^azurecli'; then
  conda create --name azurecli --yes python=3.10
fi
conda activate azurecli
pip install -U azure-cli
conda clean --yes --all

# add self-signed certificates to azurecli certify
if $fix_certify; then
  .assets/provision/fix_azcli_certs.sh
fi

# deactivate azurecli conda environment
conda deactivate

# make symbolic link to az cli
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/miniconda3/envs/azurecli/bin/az" "$HOME/.local/bin/"

# restore working directory
popd >/dev/null
