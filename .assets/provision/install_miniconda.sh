#!/usr/bin/env bash
: '
.assets/provision/install_miniconda.sh
'
APP='conda'
if [ -d $HOME/miniconda3 ]; then
  printf "\e[32mDirectory already exists: '$HOME/miniconda3'\e[0m\n"
  exit 0
fi

printf "\e[92minstalling \e[1m$APP\e[0m\n"

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
