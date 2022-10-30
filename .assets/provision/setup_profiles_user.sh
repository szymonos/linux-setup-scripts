#!/bin/bash
: '
.assets/provision/setup_profiles_user.sh
'
# path varaibles
PROFILE_PATH='/etc/profile.d'
OMP_PATH='/usr/local/share/oh-my-posh'

# add common bash aliases
grep -qw 'd/bash_aliases' ~/.bashrc 2>/dev/null || cat <<EOF >>~/.bashrc
# common aliases
if [ -f $PROFILE_PATH/bash_aliases ]; then
  source $PROFILE_PATH/bash_aliases
fi
EOF

# add git aliases
if ! grep -qw 'd/bash_aliases_git' ~/.bashrc 2>/dev/null && type git &>/dev/null; then
  cat <<EOF >>~/.bashrc
# git aliases
if [ -f $PROFILE_PATH/bash_aliases_git ] && type git &>/dev/null; then
  source $PROFILE_PATH/bash_aliases_git
fi
EOF
fi

# add kubectl autocompletion and aliases
if ! grep -qw 'kubectl' ~/.bashrc 2>/dev/null && type -f kubectl &>/dev/null; then
  cat <<EOF >>~/.bashrc
# kubectl autocompletion and aliases
if type -f kubectl &>/dev/null; then
  source <(kubectl completion bash)
  complete -o default -F __start_kubectl k
  function kubectl() {
    echo "\$(tput setaf 5)\$(tput bold)kubectl \@\$(tput sgr0)" >&2
    command kubectl \$@
  }
  if [ -f $PROFILE_PATH/bash_aliases_kubectl ]; then
    source $PROFILE_PATH/bash_aliases_kubectl
  fi
fi
EOF
fi

# add oh-my-posh invocation
if ! grep -qw 'oh-my-posh' ~/.bashrc 2>/dev/null && type oh-my-posh &>/dev/null; then
  cat <<EOF >>~/.bashrc
# initialize oh-my-posh prompt
if [ -f $OMP_PATH/theme.omp.json ] && type oh-my-posh &>/dev/null; then
  eval "\$(oh-my-posh --init --shell bash --config $OMP_PATH/theme.omp.json)"
fi
EOF
fi
