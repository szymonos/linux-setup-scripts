#!/usr/bin/env bash
: '
sudo .assets/provision/setup_omp.sh
sudo .assets/provision/setup_omp.sh --theme nerd --user $(id -un)
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

# parse named parameters
theme=${theme:-base}
user=${user:-$(id -un 1000 2>/dev/null)}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# check if specified user exists
if ! grep -qw "^$user" /etc/passwd; then
  if [ -n "$user" ]; then
    printf "\e[31;1mUser does not exist ($user).\e[0m\n"
  else
    printf "\e[31;1mUser ID 1000 not found.\e[0m\n"
  fi
  exit 1
fi

# path variables
CFG_PATH="$(sudo -u $user sh -c 'echo $HOME/tmp/config/omp_cfg')"
OH_MY_POSH_PATH='/usr/local/share/oh-my-posh'
# create CFG folder
sudo -u $user mkdir -p $CFG_PATH
# copy profile for WSL setup
if [ -f .assets/config/omp_cfg/${theme}.omp.json ]; then
  cp -f .assets/config/omp_cfg/${theme}.omp.json $CFG_PATH
else
  curl -fsSk -o $CFG_PATH/${theme}.omp.json "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/${theme}.omp.json" 2>/dev/null
fi

# *Copy oh-my-posh theme
if [ -f $CFG_PATH/${theme}.omp.json ]; then
  mkdir -p $OH_MY_POSH_PATH
  install -m 0644 $CFG_PATH/${theme}.omp.json $OH_MY_POSH_PATH/theme.omp.json
fi

# clean config folder
rm -fr $CFG_PATH
