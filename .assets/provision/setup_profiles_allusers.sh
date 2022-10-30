#!/bin/bash
: '
sudo .assets/provision/setup_profiles_allusers.sh
'
# path varaibles
PROFILE_PATH='/etc/profile.d'
OMP_PATH='/usr/local/share/oh-my-posh'

# *Copy global profiles
if [ -d /tmp/bash_cfg ]; then
  # bash aliases
  \mv -f /tmp/bash_cfg/bash_aliases $PROFILE_PATH
  # git aliases
  if type git &>/dev/null; then
    \mv -f /tmp/bash_cfg/bash_aliases_git $PROFILE_PATH
  fi
  # kubectl aliases
  if type -f kubectl &>/dev/null; then
    \mv -f /tmp/bash_cfg/bash_aliases_kubectl $PROFILE_PATH
  fi
  # clean config folder
  \rm -fr /tmp/bash_cfg
fi

# *bash profile
# add common bash aliases
grep -qw 'd/bash_aliases' ~/.bashrc || cat <<EOF >>~/.bashrc
# common aliases
if [ -f $PROFILE_PATH/bash_aliases ]; then
  source $PROFILE_PATH/bash_aliases
fi
EOF

# add oh-my-posh invocation
if ! grep -qw 'oh-my-posh' ~/.bashrc && type oh-my-posh &>/dev/null; then
  cat <<EOF >>~/.bashrc
# initialize oh-my-posh prompt
if [ -f $OMP_PATH/theme.omp.json ] && type oh-my-posh &>/dev/null; then
  eval "\$(oh-my-posh --init --shell bash --config $OMP_PATH/theme.omp.json)"
fi
EOF
fi

# make path autocompletion case insensitive
grep -qw 'completion-ignore-case' /etc/inputrc || echo 'set completion-ignore-case on' >>/etc/inputrc

# *set localtime to UTC
[ -f /etc/localtime ] || ln -s /usr/share/zoneinfo/UTC /etc/localtime
