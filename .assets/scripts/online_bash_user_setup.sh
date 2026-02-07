: '
Install eza, bat and add bash aliases to the user environment
# install dependencies, then source the script to perform the setup
apt update && apt install -y curl
# source the script to perform the setup
source <(curl -s --fail https://raw.githubusercontent.com/szymonos/linux-setup-scripts/main/.assets/scripts/online_bash_user_setup.sh)
'

# *Set initial state
# create temporary directory for downloads and cleanup on exit
TMP_DIR=$(mktemp -d -p "$HOME")
trap "rm -rf \"$TMP_DIR\" >/dev/null 2>&1; trap - RETURN" RETURN
# determine if the system uses GNU or musl libc
getconf GNU_LIBC_VERSION >/dev/null 2>&1 && lib='gnu' || lib='musl'
# create ~/.local/bin if it doesn't exist
[ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin"

# *Install bat
REL=$(curl -sk https://api.github.com/repos/sharkdp/bat/releases/latest | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
if [ -n "$REL" ]; then
  if type bat &>/dev/null; then
    VER=$(bat --version | sed -En 's/.*\s([0-9\.]+)/\1/p')
    if [ "$REL" = "$VER" ]; then
      printf "\e[32mbat v$VER is already latest\e[0m\n" >&2
    fi
  else
    printf "\e[96mdownloading bat v$REL...\e[0m\n"
    URL="https://github.com/sharkdp/bat/releases/download/v${REL}/bat-v${REL}-x86_64-unknown-linux-${lib}.tar.gz"
    retry_count=0
    while [[ $retry_count -lt 5 ]]; do
      curl -fsSL "$URL" -o "$TMP_DIR/bat.tar.gz" && break || true
      ((retry_count++))
    done
    if [ -f "$TMP_DIR/bat.tar.gz" ]; then
      tar -zxf "$TMP_DIR/bat.tar.gz" --strip-components=1 -C "$TMP_DIR" &&
        install -m 0755 "$TMP_DIR/bat" "$HOME/.local/bin/" &&
        printf "\e[32mbat installed successfully\e[0m\n" >&2
    else
      printf "\e[31mFailed to download bat v$REL\e[0m\n" >&2
    fi
  fi
fi

# *Install eza
REL=$(curl -sk https://api.github.com/repos/eza-community/eza/releases/latest | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
if [ -n "$REL" ]; then
  if type eza &>/dev/null; then
    VER=$(eza --version | sed -En 's/v([0-9\.]+).*/\1/p')
    if [ "$REL" = "$VER" ]; then
      printf "\e[32meza v$VER is already latest\e[0m\n" >&2
    fi
  else
    printf "\e[96mdownloading eza v$REL...\e[0m\n"
    URL="https://github.com/eza-community/eza/releases/download/v${REL}/eza_x86_64-unknown-linux-${lib}.tar.gz"
    retry_count=0
    while [[ $retry_count -lt 5 ]]; do
      curl -fsSL "$URL" -o "$TMP_DIR/eza.tar.gz" && break || true
      ((retry_count++))
    done
    if [ -f "$TMP_DIR/eza.tar.gz" ]; then
      tar -zxf "$TMP_DIR/eza.tar.gz" -C "$TMP_DIR" &&
        install -m 0755 "$TMP_DIR/eza" "$HOME/.local/bin/" &&
        printf "\e[32meza installed successfully\e[0m\n" >&2
    else
      printf "\e[31mFailed to download eza v$REL\e[0m\n" >&2
    fi
  fi
fi

# *Add ~/.local/bin to PATH
case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >>"$HOME/.bashrc" ;;
esac

# *Add bash aliases
if ! grep -qF ".d/aliases.sh" "$HOME/.bashrc" >/dev/null 2>&1; then
  printf "\e[95madding bash aliases...\e[0m\n"
  URL='https://raw.githubusercontent.com/szymonos/linux-setup-scripts/main/.assets/config/bash_cfg/aliases.sh'
  mkdir -p "$HOME/.bashrc.d" >/dev/null &&
    curl -fsSL "$URL" -o "$HOME/.bashrc.d/aliases.sh" &&
    echo "source '$HOME/.bashrc.d/aliases.sh'" >>"$HOME/.bashrc"
  sed -i 's/\/usr\/bin\/eza/\"\$HOME\/.local\/bin\/eza\"/' "$HOME/.bashrc.d/aliases.sh"
  sed -i 's/\/usr\/bin\/bat/\"\$HOME\/.local\/bin\/bat\"/' "$HOME/.bashrc.d/aliases.sh"
else
  printf "\e[32mbash aliases already added to .bashrc\e[0m\n"
fi

# *Enable color prompt
if grep -qF "force_color_prompt" "$HOME/.bashrc" >/dev/null 2>&1; then
  sed -i 's/^#force_color_prompt/force_color_prompt/' "$HOME/.bashrc"
else
  echo 'PS1="\e[32m\u\e[96m@\e[32m\h\e[m:\e[94m\w\e[m\\$ "' >>"$HOME/.bashrc"
fi

# *Source .bashrc to apply changes to current session
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
