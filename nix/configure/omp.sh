#!/usr/bin/env bash
# Post-install oh-my-posh theme configuration (cross-platform, Nix variant)
set -euo pipefail

omp_theme="${1:-}"

info()  { printf "\e[96m%s\e[0m\n" "$*"; }
ok()    { printf "\e[32m%s\e[0m\n" "$*"; }

if [[ -z "$omp_theme" ]]; then
  exit 0
fi

if ! command -v oh-my-posh &>/dev/null; then
  exit 0
fi

info "setting oh-my-posh theme to '$omp_theme'..."

# resolve theme directory - nix stores themes inside the package's share dir
OMP_BIN="$(command -v oh-my-posh)"
# nix profile links: ~/.nix-profile/bin/oh-my-posh -> /nix/store/<hash>-oh-my-posh-<ver>/bin/oh-my-posh
# themes are at: /nix/store/<hash>-oh-my-posh-<ver>/share/oh-my-posh/themes
OMP_STORE_PATH="$(dirname "$(dirname "$(readlink -f "$OMP_BIN")")")"
THEME_DIR="$OMP_STORE_PATH/share/oh-my-posh/themes"

if [[ ! -d "$THEME_DIR" ]]; then
  # fallback: try the common system path
  THEME_DIR="/usr/local/share/oh-my-posh/themes"
fi

if [[ ! -d "$THEME_DIR" ]]; then
  printf "\e[33mTheme directory not found: %s\e[0m\n" "$THEME_DIR" >&2
  exit 1
fi

# determine current shell's init command
current_shell="$(basename "$SHELL")"
OMP_INIT="eval \"\$(oh-my-posh init $current_shell --config \$THEME_DIR/${omp_theme}.omp.json)\""

# add to shell rc files
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [[ -f "$rc" ]] && ! grep -q 'oh-my-posh init' "$rc"; then
    {
      echo ""
      echo "# oh-my-posh prompt"
      echo "THEME_DIR=\"$THEME_DIR\""
      echo "$OMP_INIT"
    } >> "$rc"
    ok "added oh-my-posh init to $(basename "$rc")"
  fi
done
