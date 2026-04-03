#!/usr/bin/env bash
# Post-install shell profile setup (cross-platform, Nix variant)
# Sets up: ~/.local/bin in PATH, aliases, fzf integration, nix PATH,
#           uv/pixi completions, make completions, kubectl completions
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_ROOT/../.." && pwd)"

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }

info "configuring shell profiles..."

# create rc files if missing
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [[ -f "$rc" ]] || touch "$rc"
done

# -- Nix profile PATH -------------------------------------------------------
# The Determinate Systems installer handles this, but ensure it's present
for nix_profile in "$HOME/.nix-profile/etc/profile.d/nix.sh" /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; do
  if [[ -f "$nix_profile" ]]; then
    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.zprofile"; do
      if [[ -f "$rc" ]] && ! grep -q 'nix-daemon\|nix\.sh\|nix-profile' "$rc"; then
        {
          echo ""
          echo "# Nix"
          echo ". $nix_profile"
        } >> "$rc"
        ok "added nix to PATH in $(basename "$rc")"
      fi
    done
    break
  fi
done

# -- ~/.local/bin in PATH ----------------------------------------------------
LOCAL_BIN_LINE='export PATH="$HOME/.local/bin:$PATH"'
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [[ -f "$rc" ]] && ! grep -q '.local/bin' "$rc"; then
    {
      echo ""
      echo "# local bin"
      echo "$LOCAL_BIN_LINE"
    } >> "$rc"
  fi
done

# -- Aliases -----------------------------------------------------------------
# source repo-provided aliases if they exist, otherwise add inline defaults
BASH_CFG="$REPO_ROOT/.assets/config/bash_cfg"
if [[ -d "$BASH_CFG" ]]; then
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]] && ! grep -q 'aliases (setup)' "$rc"; then
      {
        echo ""
        echo "# -- aliases (setup) --"
        # determine eza flags based on capabilities
        eza_param=''
        command -v eza &>/dev/null && eza --version 2>/dev/null | grep -Fqw '+git' && eza_param+='--git ' || true
        command -v oh-my-posh &>/dev/null && eza_param+='--icons ' || true

        echo 'alias ll="eza -lah '"$eza_param"'--group-directories-first"'
        echo 'alias ls="eza '"$eza_param"'--group-directories-first"'
        echo 'alias la="eza -a '"$eza_param"'--group-directories-first"'
        echo 'alias lt="eza --tree '"$eza_param"'--group-directories-first"'
        echo 'alias cat="bat --paging=never"'
      } >> "$rc"
      ok "added aliases to $(basename "$rc")"
    fi
  done
else
  # fallback: minimal aliases without config dir
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]] && ! grep -q 'aliases (setup)' "$rc"; then
      {
        echo ""
        echo "# -- aliases (setup) --"
        echo 'command -v eza &>/dev/null && alias ls="eza --group-directories-first" && alias ll="eza -lah --group-directories-first"'
        echo 'command -v bat &>/dev/null && alias cat="bat --paging=never"'
      } >> "$rc"
    fi
  done
fi

# -- nix aliases (npkg wrapper) ----------------------------------------------
NIX_ALIASES_SRC="$BASH_CFG/aliases_nix.sh"
NIX_ALIASES_DST="$HOME/.config/bash/aliases_nix.sh"
if [[ -f "$NIX_ALIASES_SRC" ]] && command -v nix &>/dev/null; then
  if ! cmp -s "$NIX_ALIASES_SRC" "$NIX_ALIASES_DST" 2>/dev/null; then
    mkdir -p "$(dirname "$NIX_ALIASES_DST")"
    cp -f "$NIX_ALIASES_SRC" "$NIX_ALIASES_DST"
    ok "installed nix aliases for bash/zsh"
  fi
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]] && ! grep -q 'aliases_nix' "$rc"; then
      {
        echo ""
        echo "# nix aliases"
        echo ". \"$NIX_ALIASES_DST\""
      } >> "$rc"
      ok "added nix aliases to $(basename "$rc")"
    fi
  done
fi

# -- nix aliases for PowerShell ----------------------------------------------
PWSH_CFG="$REPO_ROOT/.assets/config/pwsh_cfg"
NIX_ALIASES_PS1_SRC="$PWSH_CFG/_aliases_nix.ps1"
NIX_ALIASES_PS1_DST="$HOME/.config/powershell/Scripts/_aliases_nix.ps1"
if [[ -f "$NIX_ALIASES_PS1_SRC" ]] && command -v nix &>/dev/null; then
  if ! cmp -s "$NIX_ALIASES_PS1_SRC" "$NIX_ALIASES_PS1_DST" 2>/dev/null; then
    mkdir -p "$(dirname "$NIX_ALIASES_PS1_DST")"
    cp -f "$NIX_ALIASES_PS1_SRC" "$NIX_ALIASES_PS1_DST"
    ok "installed nix aliases for PowerShell"
  fi
fi

# -- fzf shell integration --------------------------------------------------
if command -v fzf &>/dev/null; then
  if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'fzf --bash' "$HOME/.bashrc"; then
    {
      echo ""
      echo '# fzf integration'
      echo 'eval "$(fzf --bash)"'
    } >> "$HOME/.bashrc"
  fi
  if [[ -f "$HOME/.zshrc" ]] && ! grep -q 'fzf --zsh' "$HOME/.zshrc"; then
    {
      echo ""
      echo '# fzf integration'
      echo 'eval "$(fzf --zsh)"'
    } >> "$HOME/.zshrc"
  fi
fi

# -- uv completion -----------------------------------------------------------
if [[ -x "$HOME/.local/bin/uv" ]]; then
  for rc_info in "$HOME/.bashrc:bash" "$HOME/.zshrc:zsh"; do
    rc="${rc_info%%:*}"
    sh="${rc_info##*:}"
    if [[ -f "$rc" ]] && ! grep -q 'uv generate-shell-completion' "$rc"; then
      {
        echo ""
        echo "# uv completion"
        echo "export UV_NATIVE_TLS=true"
        echo "eval \"\$(uv generate-shell-completion $sh)\""
      } >> "$rc"
    fi
  done
fi

# -- pixi completion ---------------------------------------------------------
if [[ -x "$HOME/.pixi/bin/pixi" ]]; then
  for rc_info in "$HOME/.bashrc:bash" "$HOME/.zshrc:zsh"; do
    rc="${rc_info%%:*}"
    sh="${rc_info##*:}"
    if [[ -f "$rc" ]] && ! grep -q 'pixi completion' "$rc"; then
      {
        echo ""
        echo "# pixi completion"
        echo "eval \"\$($HOME/.pixi/bin/pixi completion --shell $sh)\""
      } >> "$rc"
    fi
  done
fi

# -- kubectl completion + aliases --------------------------------------------
if command -v kubectl &>/dev/null; then
  if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'kubectl completion' "$HOME/.bashrc"; then
    {
      echo ""
      echo "# kubectl completion and aliases"
      echo 'source <(kubectl completion bash)'
      echo 'complete -o default -F __start_kubectl k'
      echo 'alias k=kubectl'
      command -v kubecolor &>/dev/null && echo 'alias kubectl=kubecolor' || true
      command -v kubectx &>/dev/null && echo 'alias kc=kubectx' || true
      command -v kubens &>/dev/null && echo 'alias kn=kubens' || true
    } >> "$HOME/.bashrc"
  fi
  if [[ -f "$HOME/.zshrc" ]] && ! grep -q 'kubectl completion' "$HOME/.zshrc"; then
    {
      echo ""
      echo "# kubectl completion and aliases"
      echo 'source <(kubectl completion zsh)'
      echo 'alias k=kubectl'
      command -v kubecolor &>/dev/null && echo 'alias kubectl=kubecolor' || true
      command -v kubectx &>/dev/null && echo 'alias kc=kubectx' || true
      command -v kubens &>/dev/null && echo 'alias kn=kubens' || true
    } >> "$HOME/.zshrc"
  fi
fi

# -- make completion ---------------------------------------------------------
if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'Makefile' "$HOME/.bashrc"; then
  cat <<'EOF' >> "$HOME/.bashrc"

# make completion
complete -W "\`if [ -f Makefile ]; then grep -oE '^[a-zA-Z0-9_-]+:([^=]|$)' Makefile | sed 's/[^a-zA-Z0-9_-]*$//'; elif [ -f makefile ]; then grep -oE '^[a-zA-Z0-9_-]+:([^=]|$)' makefile | sed 's/[^a-zA-Z0-9_-]*$//'; fi \`" make
EOF
fi

ok "shell profiles configured"
