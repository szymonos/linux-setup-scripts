#!/bin/bash
: '
sudo .assets/provision/setup_omp.sh
sudo .assets/provision/setup_omp.sh --theme "powerline"
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script with sudo!\e[0m'
  exit 1
fi

# parse named parameters
theme=${1:-base}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# path variables
CFG_PATH='/tmp/config/omp_cfg'
OH_MY_POSH_PATH='/usr/local/share/oh-my-posh'
# copy profile for WSL setup
if [[ -f .assets/config/omp_cfg/${theme}.omp.json ]]; then
  mkdir -p $CFG_PATH
  cp -f .assets/config/omp_cfg/${theme}.omp.json $CFG_PATH/theme.omp.json
fi

if [[ ! -f $CFG_PATH/theme.omp.json ]]; then
  curl -fsSk -o $CFG_PATH/theme.omp.json "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/${theme}.omp.json" 2>/dev/null
fi

# *Copy oh-my-posh theme
if [[ -f $CFG_PATH/theme.omp.json ]]; then
  mkdir -p $OH_MY_POSH_PATH
  mv -f $CFG_PATH/theme.omp.json $OH_MY_POSH_PATH
fi

# clean config folder
rm -fr $CFG_PATH
