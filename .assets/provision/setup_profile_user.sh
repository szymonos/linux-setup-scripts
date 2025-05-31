#!/usr/bin/env bash
: '
.assets/provision/setup_profile_user.sh
'
# path variables
PROFILE_PATH='/etc/profile.d'
OMP_PATH='/usr/local/share/oh-my-posh'

# add common bash aliases
grep -qw 'd/aliases.sh' $HOME/.bashrc 2>/dev/null || cat <<EOF >>$HOME/.bashrc
# common aliases
if [ -f "$PROFILE_PATH/aliases.sh" ]; then
  source "$PROFILE_PATH/aliases.sh"
fi
EOF

# add git aliases
if ! grep -qw 'd/aliases_git.sh' $HOME/.bashrc 2>/dev/null && type git &>/dev/null; then
  cat <<EOF >>$HOME/.bashrc
# git aliases
if [ -f "$PROFILE_PATH/aliases_git.sh" ] && type git &>/dev/null; then
  source "$PROFILE_PATH/aliases_git.sh"
fi
EOF
fi

# add custom functions
grep -qw 'd/functions.sh' $HOME/.bashrc 2>/dev/null || cat <<EOF >>$HOME/.bashrc
# custom functions
if [ -f "$PROFILE_PATH/functions.sh" ]; then
  source "$PROFILE_PATH/functions.sh"
fi
EOF

# add kubectl autocompletion and aliases
if ! grep -qw 'kubectl' $HOME/.bashrc 2>/dev/null && type -f kubectl &>/dev/null; then
  cat <<EOF >>$HOME/.bashrc
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

# add gh copilot aliases
if gh extension list 2>/dev/null | grep -qF 'github/gh-copilot'; then
  mkdir -p "$HOME/.bashrc.d" >/dev/null
  gh copilot alias -- bash >"$HOME/.bashrc.d/aliases_gh_copilot.sh"
  if ! grep -qF 'd/aliases_gh_copilot.sh' $HOME/.bashrc 2>/dev/null; then
    cat <<EOF >>$HOME/.bashrc
# gh copilot aliases
if [ -f "$HOME/.bashrc.d/aliases_gh_copilot.sh" ]; then
  source "$HOME/.bashrc.d/aliases_gh_copilot.sh"
fi
EOF
  fi
fi

# add conda initialization
if ! grep -qw '__conda_setup' $HOME/.bashrc 2>/dev/null && [ -f $HOME/miniconda3/bin/conda ]; then
  $HOME/miniconda3/bin/conda init bash >/dev/null
fi

# add uv autocompletion
if ! grep -qw 'uv generate-shell-completion' $HOME/.bashrc 2>/dev/null && [ -x $HOME/.local/bin/uv ]; then
  cat <<EOF >>$HOME/.bashrc

# initialize uv autocompletion
if [ -x "$HOME/.local/bin/uv" ]; then
  eval "\$(uv generate-shell-completion bash)"
fi
EOF
fi

# add oh-my-posh invocation
if ! grep -qw 'oh-my-posh' $HOME/.bashrc 2>/dev/null && type oh-my-posh &>/dev/null; then
  cat <<EOF >>$HOME/.bashrc
# initialize oh-my-posh prompt
if [ -f "$OMP_PATH/theme.omp.json" ] && type oh-my-posh &>/dev/null; then
  eval "\$(oh-my-posh init bash --config "$OMP_PATH/theme.omp.json")"
fi
EOF
elif grep -qw 'oh-my-posh --init' $HOME/.bashrc 2>/dev/null; then
  # convert oh-my-posh initialization to the new API
  sed -i 's/oh-my-posh --init --shell bash/oh-my-posh init bash/' $HOME/.bashrc
fi
