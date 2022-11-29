#!/bin/bash
: '
sudo .assets/provision/setup_omp.sh --assets ".assets" --theme_font "powerline"
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script with sudo!\e[0m'
  exit 1
fi

# parse named parameters
assets=${scope:-/tmp}
theme_font=${theme_font:-base}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# path varaibles
case $theme_font in
base)
  OMP_THEME="$assets/config/omp_cfg/theme.omp.json"
  ;;
powerline)
  OMP_THEME="$assets/config/omp_cfg/theme-pl.omp.json"
  ;;
esac
OH_MY_POSH_PATH='/usr/local/share/oh-my-posh'

# *Copy oh-my-posh theme
if [ -d $assets/config/omp_cfg ]; then
  # oh-my-posh profile
  \mkdir -p $OH_MY_POSH_PATH
  \cp -f $OMP_THEME "$OH_MY_POSH_PATH/theme.omp.json"
  if [ -d /tmp/config/bash_cfg ]; then
    # clean config folder
    \rm -fr /tmp/config/omp_cfg
  fi
fi
