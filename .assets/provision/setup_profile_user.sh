#!/usr/bin/env bash
: '
.assets/provision/setup_profile_user.sh
'
# path variables
PROFILE_PATH='/etc/profile.d'
OMP_PATH='/usr/local/share/oh-my-posh'

# add common bash aliases
grep -qw 'd/aliases.sh' ~/.bashrc 2>/dev/null || cat <<EOF >>~/.bashrc
# common aliases
if [ -f "$PROFILE_PATH/aliases.sh" ]; then
  source "$PROFILE_PATH/aliases.sh"
fi
EOF

# add git aliases
if ! grep -qw 'd/aliases_git.sh' ~/.bashrc 2>/dev/null && type git &>/dev/null; then
  cat <<EOF >>~/.bashrc
# git aliases
if [ -f "$PROFILE_PATH/aliases_git.sh" ] && type git &>/dev/null; then
  source "$PROFILE_PATH/aliases_git.sh"
fi
EOF
fi

# add custom functions
grep -qw 'd/functions.sh' ~/.bashrc 2>/dev/null || cat <<EOF >>~/.bashrc
# custom functions
if [ -f "$PROFILE_PATH/functions.sh" ]; then
  source "$PROFILE_PATH/functions.sh"
fi
EOF

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
  if [ -f "$PROFILE_PATH/aliases_kubectl.sh" ]; then
    source "$PROFILE_PATH/aliases_kubectl.sh"
  fi
fi
EOF
fi

# add conda initialization
if ! grep -qw '__conda_setup' ~/.bashrc 2>/dev/null && [ -f $HOME/miniconda3/bin/conda ]; then
  $HOME/miniconda3/bin/conda init bash >/dev/null
fi

# add oh-my-posh invocation
if ! grep -qw 'oh-my-posh' ~/.bashrc 2>/dev/null && type oh-my-posh &>/dev/null; then
  cat <<EOF >>~/.bashrc
# initialize oh-my-posh prompt
if [ -f "$OMP_PATH/theme.omp.json" ] && type oh-my-posh &>/dev/null; then
  eval "\$(oh-my-posh --init --shell bash --config "$OMP_PATH/theme.omp.json")"
fi
EOF
fi
