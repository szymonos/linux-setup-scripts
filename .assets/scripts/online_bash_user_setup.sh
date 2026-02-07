#!/usr/bin/env bash
: '
Install eza, bat and add bash aliases to the user environment
# install dependencies, then source the script to perform the setup
apt update && apt install -y curl
# source the script to perform the setup
source <(curl -s https://raw.githubusercontent.com/szymonos/linux-setup-scripts/main/.assets/scripts/online_bash_user_setup.sh)
'

# *GitHub user content assets URL
GH_CONTENT_ASSETS="https://raw.githubusercontent.com/szymonos/linux-setup-scripts/main/.assets"

# Use a single assets dir variable and ensure cleanup on RETURN/EXIT
ASSETS_DIR="${PWD}/.assets"
trap 'rm -rf "$ASSETS_DIR" >/dev/null 2>&1' RETURN EXIT
mkdir -p "$ASSETS_DIR/provision" >/dev/null

# *Download the provisioning source script (fail on error)
curl --fail -s "$GH_CONTENT_ASSETS/provision/source.sh" -o "$ASSETS_DIR/provision/source.sh"

# *Install required dependencies for the provisioning scripts
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
case $SYS_ID in
alpine)
  exit 0
  ;;
arch)
  pacman -Qqe jq &>/dev/null || pacman -Sy --needed --noconfirm jq
  ;;
fedora)
  rpm -q jq &>/dev/null || dnf install -y jq
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update &>/dev/null && apt-get install -y apt-utils
  dpkg -s gnupg &>/dev/null || apt-get install -y gnupg
  dpkg -s jq &>/dev/null || apt-get install -y jq
  ;;
opensuse)
  rpm -q jq &>/dev/null || zypper --non-interactive in -y jq
  ;;
*)
  printf "\e[31mUnsupported system.\e[0m\n"
  exit 1
  ;;
esac

# *Install bat
curl --fail -s "$GH_CONTENT_ASSETS/provision/install_bat.sh" | bash >/dev/null

# *Install eza
curl --fail -s "$GH_CONTENT_ASSETS/provision/install_eza.sh" | bash >/dev/null

# *Add bash aliases
if ! grep -qF ".d/aliases.sh" "$HOME/.bashrc"; then
  printf "\e[95madding bash aliases...\e[0m\n"
  mkdir -p "$HOME/.bashrc.d" >/dev/null &&
    curl --fail -s "$GH_CONTENT_ASSETS/config/bash_cfg/aliases.sh" -o "$HOME/.bashrc.d/aliases.sh" &&
    echo "source '$HOME/.bashrc.d/aliases.sh'" >>"$HOME/.bashrc"
else
  printf "\e[32mbash aliases already added to .bashrc\e[0m\n"
fi

# *Enable color prompt
if grep -qF "force_color_prompt" "$HOME/.bashrc"; then
  sed -i 's/^#force_color_prompt/force_color_prompt/' "$HOME/.bashrc"
else
  echo 'PS1="\e[32m\u\e[96m@\e[32m\h\e[m:\e[94m\w\e[m\\$ "' >>"$HOME/.bashrc"
fi

source "$HOME/.bashrc"
