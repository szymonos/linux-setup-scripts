#!/usr/bin/env bash
: '
.assets/setup/setup_profile_user.sh
'
set -euo pipefail

# path variables
PROFILE_PATH='/etc/profile.d'
OMP_PATH='/usr/local/share/oh-my-posh'

# *deploy functions.sh to user-scope if system-wide not available
if [ ! -f "$PROFILE_PATH/functions.sh" ] && [ -f .assets/config/bash_cfg/functions.sh ]; then
  mkdir -p "$HOME/.config/bash"
  install -m 0644 .assets/config/bash_cfg/functions.sh "$HOME/.config/bash/"
fi

# *add custom functions
grep -qw 'd/functions.sh' $HOME/.bashrc 2>/dev/null || cat <<EOF >>$HOME/.bashrc
# custom functions
if [ -f "$PROFILE_PATH/functions.sh" ]; then
  source "$PROFILE_PATH/functions.sh"
elif [ -f "\$HOME/.config/bash/functions.sh" ]; then
  source "\$HOME/.config/bash/functions.sh"
fi
EOF

# *aliases
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

# *add conda initialization
if ! grep -qw '__conda_setup' $HOME/.bashrc 2>/dev/null && [ -f $HOME/miniforge3/bin/conda ]; then
  $HOME/miniforge3/bin/conda init bash >/dev/null
fi

# *set up uv
COMPLETION_CMD='uv generate-shell-completion bash'
UV_PATH=".local/bin"
if ! grep -qw "$COMPLETION_CMD" $HOME/.bashrc 2>/dev/null && [ -x "$HOME/$UV_PATH/uv" ]; then
  cat <<EOF >>$HOME/.bashrc

# initialize uv autocompletion
if [ -x "\$HOME/$UV_PATH/uv" ]; then
  export UV_SYSTEM_CERTS=true
  eval "\$(\$HOME/$UV_PATH/$COMPLETION_CMD)"
fi
EOF
fi

# *set Makefile completer
if ! grep -qw "Makefile" $HOME/.bashrc 2>/dev/null; then
  cat <<'EOF' >>$HOME/.bashrc

# initialize make autocompletion
complete -W "\`if [ -f Makefile ]; then grep -oE '^[a-zA-Z0-9_-]+:([^=]|$)' Makefile | sed 's/[^a-zA-Z0-9_-]*$//'; elif [ -f makefile ]; then grep -oE '^[a-zA-Z0-9_-]+:([^=]|$)' makefile | sed 's/[^a-zA-Z0-9_-]*$//'; fi \`" make
EOF
fi

# *set up managed env block (local path + MITM proxy cert env vars)
_setup_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
ok() { printf "\e[32m%s\e[0m\n" "$*"; }
# shellcheck source=../lib/profile_block.sh
source "$_setup_lib/profile_block.sh"
# shellcheck source=../lib/env_block.sh
source "$_setup_lib/env_block.sh"
# shellcheck source=../lib/certs.sh
source "$_setup_lib/certs.sh"
build_ca_bundle
setup_vscode_certs
_env_tmp="$(mktemp)"
render_env_block >"$_env_tmp"
manage_block "$HOME/.bashrc" "$ENV_BLOCK_MARKER" upsert "$_env_tmp"
rm -f "$_env_tmp"

# *add oh-my-posh invocation
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
