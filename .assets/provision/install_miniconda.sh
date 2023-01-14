#!/usr/bin/env bash
: '
.assets/provision/install_miniconda.sh
'
APP='conda'
if [[ -f $HOME/miniconda3/bin/conda ]]; then
  echo -e "\e[36m$APP already installed\e[0m"
  exit 0
fi

echo -e "\e[96minstalling $APP\e[0m"

while [[ ! -f miniconda.sh ]]; do
  curl -fsSLk -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
done
bash ./miniconda.sh -b -p $HOME/miniconda3 >/dev/null && rm ./miniconda.sh
$HOME/miniconda3/bin/conda config --set auto_activate_base false
$HOME/miniconda3/bin/conda config --set changeps1 false
