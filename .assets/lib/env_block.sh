# Generic managed-env block for shell rc files.
# Contains user-scope PATH and cert env vars that are not nix-specific.
# Shared by nix and legacy setup paths.
# Compatible with bash 3.2 and zsh (sourced by both).
#
# Usage:
#   source .assets/lib/env_block.sh
#   render_env_block   # prints block content to stdout
#
# Requires: profile_block.sh must be sourced first (for manage_block).

# shellcheck disable=SC2034  # used by sourcing scripts
ENV_BLOCK_MARKER="managed env"

# render_env_block
# Prints the managed env block content to stdout.
# Two sections: local path and cert env vars.
# Caller writes output to a temp file and passes to manage_block.
render_env_block() {
  # :local path
  printf '# :local path\n'
  printf 'if [ -d "$HOME/.local/bin" ]; then\n'
  printf '  export PATH="$HOME/.local/bin:$PATH"\n'
  printf 'fi\n'

  # :aliases (generic - nix-installed tools have their aliases in the nix block)
  if [ -f "$HOME/.config/bash/functions.sh" ]; then
    printf '\n# :aliases\n'
    printf '[ -f "$HOME/.config/bash/functions.sh" ] && . "$HOME/.config/bash/functions.sh"\n'
  fi
  if [ -f "$HOME/.config/bash/aliases_git.sh" ] && command -v git &>/dev/null && [ ! -x "$HOME/.nix-profile/bin/git" ]; then
    printf '[ -f "$HOME/.config/bash/aliases_git.sh" ] && . "$HOME/.config/bash/aliases_git.sh"\n'
  fi
  if [ -f "$HOME/.config/bash/aliases_kubectl.sh" ] && command -v kubectl &>/dev/null && [ ! -x "$HOME/.nix-profile/bin/kubectl" ]; then
    printf '[ -f "$HOME/.config/bash/aliases_kubectl.sh" ] && . "$HOME/.config/bash/aliases_kubectl.sh"\n'
  fi

  # :certs
  local cert_dir="$HOME/.config/certs"
  if [ -f "$cert_dir/ca-custom.crt" ] || [ -e "$cert_dir/ca-bundle.crt" ]; then
    printf '\n# :certs\n'
  fi
  if [ -f "$cert_dir/ca-custom.crt" ]; then
    printf 'if [ -f "$HOME/.config/certs/ca-custom.crt" ]; then\n'
    printf '  export NODE_EXTRA_CA_CERTS="$HOME/.config/certs/ca-custom.crt"\n'
    printf 'fi\n'
  fi
  if [ -e "$cert_dir/ca-bundle.crt" ]; then
    printf 'if [ -f "$HOME/.config/certs/ca-bundle.crt" ]; then\n'
    printf '  export REQUESTS_CA_BUNDLE="$HOME/.config/certs/ca-bundle.crt"\n'
    printf '  export SSL_CERT_FILE="$HOME/.config/certs/ca-bundle.crt"\n'
    printf 'fi\n'
    if command -v gcloud &>/dev/null; then
      printf 'if [ -f "$HOME/.config/certs/ca-bundle.crt" ]; then\n'
      printf '  export CLOUDSDK_CORE_CUSTOM_CA_CERTS_FILE="$HOME/.config/certs/ca-bundle.crt"\n'
      printf 'fi\n'
    fi
  fi
}
