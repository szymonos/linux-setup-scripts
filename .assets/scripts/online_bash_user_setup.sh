: '
Set up a bash user environment by installing useful cli tools and adding aliases to your .bashrc.
The script is designed to be run on a fresh Linux system to quickly get a user environment configured with tools like bat, eza, and kubecolor, along with helpful bash aliases.

# :install dependencies on Alpine distro
apk add --no-cache curl bash && bash
# :install dependencies on Debian based distro
apt update && apt install -y curl
# :add GITHUB_TOKEN to environment for authenticated API requests (optional, but recommended to avoid rate limits)
gh auth token
export GITHUB_TOKEN=""

# :source the script to perform the setup
source <(curl -s --fail https://raw.githubusercontent.com/szymonos/linux-setup-scripts/refs/tags/online/.assets/scripts/online_bash_user_setup.sh)
'

# *Initialize state
# source script with helper functions for provisioning
GH_CONTENT_ASSETS="https://raw.githubusercontent.com/szymonos/linux-setup-scripts/refs/tags/online/.assets"
source <(curl -s --fail $GH_CONTENT_ASSETS/provision/source.sh)
# determine if the system uses GNU or musl libc
getconf GNU_LIBC_VERSION >/dev/null 2>&1 && LIB='gnu' || LIB='musl'
# ensure ~/.bashrc.d directory exists for storing bash configuration snippets
[ -d "$HOME/.bashrc.d" ] || mkdir -p "$HOME/.bashrc.d" 2>/dev/null

# *Install bat
type bat >/dev/null 2>&1 && VER=$(bat --version | sed -En 's/.*\s([0-9\.]+).*/\1/p') || VER=""
install_github_release_user \
  --gh_owner "sharkdp" \
  --gh_repo "bat" \
  --file_name "bat-v{VERSION}-x86_64-unknown-linux-${LIB}.tar.gz" \
  --current_version "$VER"

# *Install eza
type eza >/dev/null 2>&1 && VER=$(eza --version | sed -En 's/v([0-9\.]+).*/\1/p') || VER=""
install_github_release_user \
  --gh_owner "eza-community" \
  --gh_repo "eza" \
  --file_name "eza_x86_64-unknown-linux-${LIB}.tar.gz" \
  --current_version "$VER"

# *Install kubecolor
if type kubectl >/dev/null 2>&1; then
  type kubecolor >/dev/null 2>&1 && VER=$(kubecolor --kubecolor-version) || VER=""
  install_github_release_user \
    --gh_owner "kubecolor" \
    --gh_repo "kubecolor" \
    --file_name "kubecolor_{VERSION}_linux_amd64.tar.gz" \
    --current_version "$VER"

  type kubectx >/dev/null 2>&1 && VER=$(kubectx --version) || VER=""
  install_github_release_user \
    --gh_owner "ahmetb" \
    --gh_repo "kubectx" \
    --file_name "kubectx_v{VERSION}_linux_x86_64.tar.gz" \
    --current_version "$VER"
  install_github_release_user \
    --gh_owner "ahmetb" \
    --gh_repo "kubectx" \
    --file_name "kubens_v{VERSION}_linux_x86_64.tar.gz" \
    --binary_name "kubens" \
    --current_version "$VER"

  if ! grep -qF ".d/aliases_kubectl.sh" "$HOME/.bashrc" >/dev/null 2>&1; then
    printf "\e[96madding kubectl aliases...\e[0m\n"
    URL="$GH_CONTENT_ASSETS/config/bash_cfg/aliases_kubectl.sh"
    if curl -fsSL "$URL" -o "$HOME/.bashrc.d/aliases_kubectl.sh" 2>/dev/null; then
      echo "source '$HOME/.bashrc.d/aliases_kubectl.sh'" >>"$HOME/.bashrc"
    fi
  else
    printf "\e[32mkubectl aliases already added to .bashrc\e[0m\n"
  fi
fi

# *Add bash aliases
if ! grep -qF ".d/aliases.sh" "$HOME/.bashrc" >/dev/null 2>&1; then
  printf "\e[96madding bash aliases...\e[0m\n"
  URL="$GH_CONTENT_ASSETS/config/bash_cfg/aliases.sh"
  if curl -fsSL "$URL" -o "$HOME/.bashrc.d/aliases.sh" 2>/dev/null; then
    sed -i 's/\/usr\/bin\//\$HOME\/.local\/bin\//' "$HOME/.bashrc.d/aliases.sh"
    echo "source '$HOME/.bashrc.d/aliases.sh'" >>"$HOME/.bashrc"
  fi
else
  printf "\e[32mbash aliases already added to .bashrc\e[0m\n"
fi

# *Cleanup variables used during setup
unset GH_CONTENT_ASSETS LIB VER URL

# *Add ~/.local/bin to PATH
case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >>"$HOME/.bashrc" ;;
esac

# *Enable color prompt
if grep -qF "force_color_prompt" "$HOME/.bashrc" >/dev/null 2>&1; then
  sed -i 's/^#force_color_prompt/force_color_prompt/' "$HOME/.bashrc"
else
  echo 'PS1="\e[32m\u\e[96m@\e[32m\h\e[m:\e[94m\w\e[m\\$ "' >>"$HOME/.bashrc"
fi

# *Source .bashrc to apply changes to the current session
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
