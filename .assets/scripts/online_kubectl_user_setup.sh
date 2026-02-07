: '
Add kubecolor and kubectl aliases to the user environment
source <(curl -s https://raw.githubusercontent.com/szymonos/linux-setup-scripts/main/.assets/scripts/online_kubectl_user_setup.sh)
'

# *GitHub user content assets URL
GH_CONTENT_ASSETS="https://raw.githubusercontent.com/szymonos/linux-setup-scripts/main/.assets"

# *Install kubecolor
printf "\e[95minstalling kubecolor...\e[0m\n"
curl -s "$GH_CONTENT_ASSETS/provision/install_kubecolor_user.sh" | bash

# *Add kubecolor alias
# ensure ~/.local/bin is in the current $PATH; if not, append it to .bashrc for future sessions
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  printf "\e[96madding \e[4m~/.local/bin\e[24m to PATH in .bashrc\e[0m\n"
  echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >>"$HOME/.bashrc"
else
  printf "\e[4;32m$HOME/.local/bin\e[24m is already in PATH\e[0m\n"
fi
# add kubecolor alias for kubectl if not present
if ! alias | grep -qF "alias kubectl='kubecolor'"; then
  printf '\e[96madding "kubectl" alias for kubecolor to .bashrc\e[0m\n'
  echo "alias kubectl='kubecolor'" >>"$HOME/.bashrc"
else
  printf '\e[32malias \e[4mkubectl\e[24m for kubecolor already exists in .bashrc\e[0m\n'
fi

# *Add kubectl aliases
if ! grep -qF ".d/aliases_kubectl.sh" "$HOME/.bashrc"; then
  printf "\e[95madding kubectl aliases...\e[0m\n"
  mkdir -p "$HOME/.bashrc.d" >/dev/null \
  && curl --fail -s "$GH_CONTENT_ASSETS/config/bash_cfg/aliases_kubectl.sh" -o "$HOME/.bashrc.d/aliases_kubectl.sh" \
  && echo "source '$HOME/.bashrc.d/aliases_kubectl.sh'" >>"$HOME/.bashrc"
else
  printf "\e[32mkubectl aliases already added to .bashrc\e[0m\n"
fi

source $HOME/.bashrc
