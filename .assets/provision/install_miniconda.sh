#!/usr/bin/env bash
: '
.assets/provision/install_miniconda.sh
'
if type conda >/dev/null; then
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
