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

# -- Dev environment aliases -------------------------------------------------
BASH_CFG="$REPO_ROOT/.assets/config/bash_cfg"
DEVENV_ALIASES_SRC="$BASH_CFG/aliases_devenv.sh"
DEVENV_ALIASES_DST="$HOME/.config/bash/aliases_devenv.sh"
if [[ -f "$DEVENV_ALIASES_SRC" ]]; then
  if ! cmp -s "$DEVENV_ALIASES_SRC" "$DEVENV_ALIASES_DST" 2>/dev/null; then
    mkdir -p "$(dirname "$DEVENV_ALIASES_DST")"
    cp -f "$DEVENV_ALIASES_SRC" "$DEVENV_ALIASES_DST"
    ok "installed dev environment aliases for bash/zsh"
  fi
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]] && ! grep -q 'aliases_devenv' "$rc"; then
      {
        echo ""
        echo "# dev environment aliases"
        echo ". \"$DEVENV_ALIASES_DST\""
      } >> "$rc"
      ok "added dev environment aliases to $(basename "$rc")"
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

# -- PowerShell alias files --------------------------------------------------
PWSH_CFG="$REPO_ROOT/.assets/config/pwsh_cfg"
PWSH_SCRIPTS="$HOME/.config/powershell/Scripts"
if command -v pwsh &>/dev/null; then
  mkdir -p "$PWSH_SCRIPTS"
  for ps1 in _aliases_nix.ps1 _aliases_devenv.ps1; do
    src="$PWSH_CFG/$ps1"
    dst="$PWSH_SCRIPTS/$ps1"
    if [[ -f "$src" ]] && ! cmp -s "$src" "$dst" 2>/dev/null; then
      cp -f "$src" "$dst"
      ok "installed $ps1 for PowerShell"
    fi
  done
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

# -- CA bundle for tools that need a full trust store (e.g. gcloud) ----------
# On Linux, symlink to the system bundle (which already includes custom certs).
# On macOS, merge the nix CA bundle with custom MITM certs.
CERT_DIR="$HOME/.config/certs"
CUSTOM_CERTS="$CERT_DIR/ca-custom.crt"
BUNDLE_LINK="$CERT_DIR/ca-bundle.crt"
if [[ -f "$CUSTOM_CERTS" ]] && [[ ! -e "$BUNDLE_LINK" ]]; then
  mkdir -p "$CERT_DIR"
  case "$(uname -s)" in
    Linux)
      for sys_bundle in /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt; do
        if [[ -f "$sys_bundle" ]]; then
          ln -sf "$sys_bundle" "$BUNDLE_LINK"
          ok "symlinked ca-bundle.crt -> $sys_bundle"
          break
        fi
      done
      ;;
    Darwin)
      nix_bundle="$HOME/.nix-profile/etc/ssl/certs/ca-bundle.crt"
      if [[ -f "$nix_bundle" ]]; then
        cat "$nix_bundle" "$CUSTOM_CERTS" > "$BUNDLE_LINK"
        ok "created merged ca-bundle.crt (nix CAs + custom certs)"
      fi
      ;;
  esac
fi

ok "shell profiles configured"
