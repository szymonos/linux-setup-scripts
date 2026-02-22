#!/usr/bin/env zsh
: '
.assets/provision/setup_profile_user.zsh
'
# path variables
PROFILE_PATH='/etc/profile.d'
OMP_PATH='/usr/local/share/oh-my-posh'

# *install plugins
# ~zsh-autocomplete
# https://github.com/marlonrichert/zsh-autocomplete
zsh_plugin='zsh-autocomplete'
if [ -d "$HOME/.zsh/$zsh_plugin" ]; then
  git -C "$HOME/.zsh/$zsh_plugin" pull --quiet
else
  git clone https://github.com/marlonrichert/$zsh_plugin.git "$HOME/.zsh/$zsh_plugin"
fi
if ! grep -w "$zsh_plugin.plugin.zsh" "$HOME/.zshrc" 2>/dev/null; then
  cat <<EOF >>"$HOME/.zshrc"
# *plugins
source "\$HOME/.zsh/$zsh_plugin/$zsh_plugin.plugin.zsh"
EOF
fi
# ~zsh-make-complete
# https://github.com/22peacemaker/zsh-make-complete
zsh_plugin='zsh-make-complete'
if [ -d "$HOME/.zsh/$zsh_plugin" ]; then
  git -C "$HOME/.zsh/$zsh_plugin" pull --quiet
else
  git clone https://github.com/22peacemaker/$zsh_plugin.git "$HOME/.zsh/$zsh_plugin"
fi
if ! grep -Fqw "$zsh_plugin.plugin.zsh" "$HOME/.zshrc" 2>/dev/null; then
  echo "source \"\$HOME/.zsh/$zsh_plugin/$zsh_plugin.plugin.zsh\"" >>"$HOME/.zshrc"
fi
# ~zsh-autosuggestions
# https://github.com/zsh-users/zsh-autosuggestions
zsh_plugin='zsh-autosuggestions'
if [ -d "$HOME/.zsh/$zsh_plugin" ]; then
  git -C "$HOME/.zsh/$zsh_plugin" pull --quiet
else
  git clone https://github.com/zsh-users/$zsh_plugin.git "$HOME/.zsh/$zsh_plugin"
fi
if ! grep -w '$zsh_plugin.zsh' "$HOME/.zshrc" 2>/dev/null; then
  echo "source \"\$HOME/.zsh/$zsh_plugin/$zsh_plugin.zsh\"" >>"$HOME/.zshrc"
fi
# ~zsh-syntax-highlighting
# https://github.com/zsh-users/zsh-syntax-highlighting
zsh_plugin='zsh-syntax-highlighting'
if [ -d "$HOME/.zsh/$zsh_plugin" ]; then
  git -C "$HOME/.zsh/$zsh_plugin" pull --quiet
else
  git clone https://github.com/zsh-users/$zsh_plugin.git "$HOME/.zsh/$zsh_plugin"
fi
if ! grep -w "$zsh_plugin.zsh" "$HOME/.zshrc" 2>/dev/null; then
  echo "source \"\$HOME/.zsh/$zsh_plugin/$zsh_plugin.zsh\"" >>"$HOME/.zshrc"
fi
if ! grep -q '^bindkey .* autosuggest-accept' "$HOME/.zshrc"; then
  echo "bindkey '^ ' autosuggest-accept\n" >>"$HOME/.zshrc"
fi

# *aliases
# add common zsh aliases
grep -qw 'd/aliases.sh' "$HOME/.zshrc" 2>/dev/null || cat <<EOF >>"$HOME/.zshrc"
# common aliases
if [ -f "$PROFILE_PATH/aliases.sh" ]; then
  source "$PROFILE_PATH/aliases.sh"
fi
EOF

# add git aliases
if ! grep -qw 'd/aliases_git.sh' "$HOME/.zshrc" 2>/dev/null && type git &>/dev/null; then
  cat <<EOF >>"$HOME/.zshrc"
# git aliases
if [ -f "$PROFILE_PATH/aliases_git.sh" ] && type git &>/dev/null; then
  source "$PROFILE_PATH/aliases_git.sh"
fi
EOF
fi

# add kubectl autocompletion and aliases
if ! grep -qw 'kubectl' "$HOME/.zshrc" 2>/dev/null && type -f kubectl &>/dev/null; then
  cat <<EOF >>"$HOME/.zshrc"
# kubectl autocompletion and aliases
if type -f kubectl &>/dev/null; then
  if [ -f "$PROFILE_PATH/aliases_kubectl.sh" ]; then
    source "$PROFILE_PATH/aliases_kubectl.sh"
  fi
fi
EOF
fi

# *add conda initialization
if ! grep -qw '__conda_setup' "$HOME/.zshrc" 2>/dev/null && [ -f $HOME/miniforge3/bin/conda ]; then
  $HOME/miniforge3/bin/conda init zsh >/dev/null
fi

# *set up uv
COMPLETION_CMD='uv generate-shell-completion zsh'
UV_PATH=".local/bin"
if ! grep -qw "$COMPLETION_CMD" "$HOME/.zshrc" 2>/dev/null && [ -x "$HOME/$UV_PATH/uv" ]; then
  cat <<EOF >>"$HOME/.zshrc"

# initialize uv autocompletion
if [ -x "\$HOME/$UV_PATH/uv" ]; then
  export UV_NATIVE_TLS=true
  eval "\$(\$HOME/$UV_PATH/$COMPLETION_CMD)"
fi
EOF
fi

# *set up pixi
COMPLETION_CMD='pixi completion --shell zsh'
PIXI_PATH=".pixi/bin"
if ! grep -qw "$COMPLETION_CMD" "$HOME/.zshrc" 2>/dev/null && [ -x "$HOME/$PIXI_PATH/pixi" ]; then
  cat <<EOF >>"$HOME/.zshrc"

# initialize pixi autocompletion
if [ -x "\$HOME/$PIXI_PATH/pixi" ]; then
  autoload -Uz compinit && compinit
  eval "\$(\$HOME/$PIXI_PATH/$COMPLETION_CMD)"
fi
EOF
fi

# *add oh-my-posh invocation
if ! grep -qw 'oh-my-posh' "$HOME/.zshrc" 2>/dev/null && type oh-my-posh &>/dev/null; then
  cat <<EOF >>"$HOME/.zshrc"
# initialize oh-my-posh prompt
if [ -f "$OMP_PATH/theme.omp.json" ] && type oh-my-posh &>/dev/null; then
  eval "\$(oh-my-posh init zsh --config "$OMP_PATH/theme.omp.json")"
fi
EOF
elif grep -qw 'oh-my-posh --init' "$HOME/.zshrc" 2>/dev/null; then
  # convert oh-my-posh initialization to the new API
  sed -i 's/oh-my-posh --init --shell zsh/oh-my-posh init zsh/' "$HOME/.zshrc"
fi
