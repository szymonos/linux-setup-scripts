#!/usr/bin/env zsh
: '
.assets/setup/setup_profile_user.zsh
'
# path variables
PROFILE_PATH='/etc/profile.d'
OMP_PATH='/usr/local/share/oh-my-posh'

# -- zsh plugins -------------------------------------------------------------
ZSH_PLUGIN_DIR="$HOME/.zsh"
mkdir -p "$ZSH_PLUGIN_DIR"

for plugin url file in \
  'zsh-autocomplete'        'https://github.com/marlonrichert/zsh-autocomplete.git'     'zsh-autocomplete.plugin.zsh' \
  'zsh-make-complete'       'https://github.com/22peacemaker/zsh-make-complete.git'     'zsh-make-complete.plugin.zsh' \
  'zsh-autosuggestions'     'https://github.com/zsh-users/zsh-autosuggestions.git'      'zsh-autosuggestions.zsh' \
  'zsh-syntax-highlighting' 'https://github.com/zsh-users/zsh-syntax-highlighting.git' 'zsh-syntax-highlighting.zsh'
do
  if [[ -d "$ZSH_PLUGIN_DIR/$plugin" ]]; then
    git -C "$ZSH_PLUGIN_DIR/$plugin" pull --quiet 2>/dev/null || true
  else
    git clone --depth 1 "$url" "$ZSH_PLUGIN_DIR/$plugin"
  fi
  if ! grep -q "$file" "$HOME/.zshrc" 2>/dev/null; then
    [[ -s "$HOME/.zshrc" ]] && echo "" >>"$HOME/.zshrc"
    if [[ "$plugin" == 'zsh-autocomplete' ]]; then
      echo '# *plugins' >>"$HOME/.zshrc"
    fi
    echo "source \"\$HOME/.zsh/$plugin/$file\"" >>"$HOME/.zshrc"
  fi
done

if ! grep -q '^bindkey .* autosuggest-accept' "$HOME/.zshrc"; then
  echo "bindkey '^ ' autosuggest-accept" >>"$HOME/.zshrc"
fi

# -- deploy functions.sh to user-scope if system-wide not available ----------
if [[ ! -f "$PROFILE_PATH/functions.sh" ]] && [[ -f .assets/config/bash_cfg/functions.sh ]]; then
  mkdir -p "$HOME/.config/bash"
  install -m 0644 .assets/config/bash_cfg/functions.sh "$HOME/.config/bash/"
fi

# -- custom functions --------------------------------------------------------
if ! grep -qw 'd/functions.sh' "$HOME/.zshrc" 2>/dev/null; then
  cat <<EOF >>"$HOME/.zshrc"
# custom functions
if [ -f "$PROFILE_PATH/functions.sh" ]; then
  source "$PROFILE_PATH/functions.sh"
elif [ -f "\$HOME/.config/bash/functions.sh" ]; then
  source "\$HOME/.config/bash/functions.sh"
fi
EOF
fi

# -- aliases -----------------------------------------------------------------
for guard grep_key source_file label in \
  'true'              'd/aliases.sh'      "$PROFILE_PATH/aliases.sh"      'common aliases' \
  'type git'          'd/aliases_git.sh'  "$PROFILE_PATH/aliases_git.sh"  'git aliases' \
  'type -f kubectl'   'kubectl'           "$PROFILE_PATH/aliases_kubectl.sh" 'kubectl aliases'
do
  eval "$guard" &>/dev/null 2>&1 || continue
  grep -qw "$grep_key" "$HOME/.zshrc" 2>/dev/null && continue
  if [[ "$label" == 'kubectl aliases' ]]; then
    cat <<EOF >>"$HOME/.zshrc"
# kubectl autocompletion and aliases
if type -f kubectl &>/dev/null; then
  if [ -f "$source_file" ]; then
    source "$source_file"
  fi
fi
EOF
  else
    cat <<EOF >>"$HOME/.zshrc"
# $label
if [ -f "$source_file" ]; then
  source "$source_file"
fi
EOF
  fi
done

# -- conda initialization ---------------------------------------------------
if ! grep -qw '__conda_setup' "$HOME/.zshrc" 2>/dev/null && [[ -f $HOME/miniforge3/bin/conda ]]; then
  $HOME/miniforge3/bin/conda init zsh >/dev/null
fi

# -- uv completion -----------------------------------------------------------
COMPLETION_CMD='uv generate-shell-completion zsh'
UV_PATH=".local/bin"
if ! grep -qw "$COMPLETION_CMD" "$HOME/.zshrc" 2>/dev/null && [[ -x "$HOME/$UV_PATH/uv" ]]; then
  cat <<EOF >>"$HOME/.zshrc"

# initialize uv autocompletion
if [ -x "\$HOME/$UV_PATH/uv" ]; then
  export UV_SYSTEM_CERTS=true
  eval "\$(\$HOME/$UV_PATH/$COMPLETION_CMD)"
fi
EOF
fi

# -- managed env block (local path + MITM proxy cert env vars) --------------
source "${0:A:h}/../lib/profile_block.sh"
source "${0:A:h}/../lib/env_block.sh"
_env_tmp="$(mktemp)"
render_env_block >"$_env_tmp"
manage_block "$HOME/.zshrc" "$ENV_BLOCK_MARKER" upsert "$_env_tmp"
rm -f "$_env_tmp"

# -- oh-my-posh prompt -------------------------------------------------------
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
