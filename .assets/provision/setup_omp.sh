#!/bin/bash
: '
sudo .assets/provision/setup_omp.sh
'
# path varaibles
OMP_PATH='/usr/local/share/oh-my-posh'

# *Copy oh-my-posh theme
if [ -d /tmp/config/omp_cfg ]; then
  # oh-my-posh profile
  [ -d $OMP_PATH ] || \mkdir -p $OMP_PATH
  \mv -f /tmp/config/omp_cfg/theme.omp.json $OMP_PATH
  # clean config folder
  \rm -fr /tmp/config/omp_cfg
fi

# *add oh-my-posh invocation
if ! grep -qw 'oh-my-posh' ~/.bashrc 2>/dev/null && type oh-my-posh &>/dev/null; then
  cat <<EOF >>~/.bashrc
# initialize oh-my-posh prompt
if [ -f $OMP_PATH/theme.omp.json ] && type oh-my-posh &>/dev/null; then
  eval "\$(oh-my-posh --init --shell bash --config $OMP_PATH/theme.omp.json)"
fi
EOF
fi
