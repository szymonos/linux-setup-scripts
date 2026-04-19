# guard: skip when sourced by non-bash shells (e.g. dash via /etc/profile.d/)
[ -z "$BASH_VERSION" ] && return 0

#region common aliases
# navigation
alias ..='cd ../'
alias ...='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias .6='cd ../../../../../../'
alias cd..='cd ../'

# saved working directory
export SWD=$(pwd)
alias swd="echo $SWD"
alias cds="cd $SWD"

# sudo
alias sudo='sudo '
alias _='sudo'
alias please='sudo'

# file operations
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias md='mkdir -p'
alias rd='rmdir'

# tools
alias c='clear'
alias grep='grep -i --color=auto'
alias less='less -FRX'
alias nano='nano -W'
alias tree='tree -C'
alias vi='vim'
alias wget='wget -c'

# info / shell
alias path='printf "${PATH//:/\\n}\n"'
alias src='source ~/.bashrc'
alias fix_stty='stty sane'
alias fix_term='printf "\ec"'

# linux-specific
if [ -f /etc/os-release ]; then
  alias osr='cat /etc/os-release'
  alias systemctl='systemctl --no-pager'
  if grep -qEw 'ID="?alpine' /etc/os-release 2>/dev/null; then
    alias bsh='/usr/bin/env -i ash --noprofile --norc'
    alias ls='ls -h --color=auto --group-directories-first'
  else
    alias bsh='/usr/bin/env -i bash --noprofile --norc'
    alias ip='ip --color=auto'
    alias ls='ls -h --color=auto --group-directories-first --time-style=long-iso'
  fi
else
  alias bsh='/usr/bin/env -i bash --noprofile --norc'
fi
#endregion

#region dev tool aliases
_nb="$HOME/.nix-profile/bin"

if [ -x "$_nb/eza" ]; then
  alias eza='eza -g --color=auto --time-style=long-iso --group-directories-first --color-scale=all --git-repos'
  alias l='eza -1'
  alias lsa='eza -a'
  alias ll='eza -lah'
  alias lt='eza -Th'
  alias lta='eza -aTh --git-ignore'
  alias ltd='eza -DTh'
  alias ltad='eza -aDTh --git-ignore'
  alias llt='eza -lTh'
  alias llta='eza -laTh --git-ignore'
else
  alias l='ls -1'
  alias lsa='ls -a'
  alias ll='ls -lah'
fi

[ -x "$_nb/bat" ] && alias batp='bat -pP' || true
[ -x "$_nb/rg" ] && alias rg='rg --ignore-case' || true
[ -x "$_nb/fastfetch" ] && alias ff='fastfetch' || true
[ -x "$_nb/pwsh" ] && alias pwsh='pwsh -NoProfileLoadTime' && alias p='pwsh -NoProfileLoadTime' || true
[ -x "$_nb/kubectx" ] && alias kc='kubectx' || true
[ -x "$_nb/kubens" ] && alias kn='kubens' || true
[ -x "$_nb/kubecolor" ] && alias kubectl='kubecolor' || true

unset _nb
#endregion

#region nix package management wrapper (apt/brew-like UX)
if command -v nix &>/dev/null; then
  # packages.nix location (user state, not managed by setup.sh)
  _NX_ENV_DIR="$HOME/.config/nix-env"
  _NX_PKG_FILE="$_NX_ENV_DIR/packages.nix"

  # helper: read packages.nix into a newline-separated list on stdout
  _nx_read_pkgs() {
    [ -f "$_NX_PKG_FILE" ] && sed -n 's/^[[:space:]]*"\([^"]*\)".*/\1/p' "$_NX_PKG_FILE"
  }

  # helper: write a sorted package list (one name per line on stdin) to packages.nix
  _nx_write_pkgs() {
    local tmp
    tmp="$(mktemp)"
    printf '[\n' >"$tmp"
    sort -u | while IFS= read -r name; do
      [ -n "$name" ] && printf '  "%s"\n' "$name" >>"$tmp"
    done
    printf ']\n' >>"$tmp"
    mv "$tmp" "$_NX_PKG_FILE"
  }

  # helper: apply changes by upgrading the nix profile
  _nx_apply() {
    printf "\e[96mapplying changes...\e[0m\n"
    nix profile upgrade nix-env || {
      printf "\e[31mnix profile upgrade failed\e[0m\n" >&2
      return 1
    }
    printf "\e[32mdone.\e[0m\n"
  }

  # helper: validate that a package name exists in nixpkgs (returns 0/1)
  _nx_validate_pkg() {
    nix eval "nixpkgs#${1}.name" &>/dev/null
  }

  # helper: add packages to a scope .nix file, preserving the { pkgs }: with pkgs; [...] format
  _nx_scope_file_add() {
    local file="$1"
    shift
    local existing
    existing="$(_nx_scope_pkgs "$file")"
    local all_pkgs=()
    if [ -n "$existing" ]; then
      while IFS= read -r p; do
        all_pkgs+=("$p")
      done <<<"$existing"
    fi
    local p added=false
    for p in "$@"; do
      if printf '%s\n' "${all_pkgs[@]}" | grep -qx "$p" 2>/dev/null; then
        printf "\e[33m%s is already in scope\e[0m\n" "$p" >&2
      else
        all_pkgs+=("$p")
        printf "\e[32madded %s\e[0m\n" "$p" >&2
        added=true
      fi
    done
    [ "$added" = false ] && return 1
    local sorted
    sorted="$(printf '%s\n' "${all_pkgs[@]}" | sort -u)"
    local content="{ pkgs }: with pkgs; ["
    while IFS= read -r p; do
      [ -n "$p" ] && content+=$'\n'"  $p"
    done <<<"$sorted"
    content+=$'\n'"]"$'\n'
    printf '%s' "$content" >"$file"
    return 0
  }

  # helper: extract package names from a scope .nix file (sed-based, instant)
  # Scope files follow: { pkgs }: with pkgs; [ name1 name2 ... ]
  _nx_scope_pkgs() {
    local file="$1"
    [ -f "$file" ] || return 0
    sed -n '/\[/,/\]/{
      s/^[[:space:]]*\([a-zA-Z][a-zA-Z0-9_-]*\).*/\1/p
    }' "$file"
  }

  # helper: read enabled scopes from config.nix (newline-separated on stdout)
  # Parses the generated config.nix with sed (instant) instead of nix eval (~1-2s).
  _nx_scopes() {
    local config_nix="$_NX_ENV_DIR/config.nix"
    [ -f "$config_nix" ] || return 0
    sed -n '/scopes[[:space:]]*=[[:space:]]*\[/,/\]/{
      s/^[[:space:]]*"\([^"]*\)".*/\1/p
    }' "$config_nix"
  }

  # helper: read isInit from config.nix
  _nx_is_init() {
    local config_nix="$_NX_ENV_DIR/config.nix"
    [ -f "$config_nix" ] || { echo "false"; return; }
    sed -n -E 's/^[[:space:]]*isInit[[:space:]]*=[[:space:]]*(true|false).*/\1/p' "$config_nix"
  }

  # helper: list all scope packages as "pkg\tscope" lines (base + configured scopes)
  _nx_all_scope_pkgs() {
    local scopes_dir="$_NX_ENV_DIR/scopes"
    [ -d "$scopes_dir" ] || return 0
    local pkg
    while IFS= read -r pkg; do
      [ -n "$pkg" ] && printf '%s\t%s\n' "$pkg" "base"
    done < <(_nx_scope_pkgs "$scopes_dir/base.nix")
    if [ "$(_nx_is_init)" = "true" ]; then
      while IFS= read -r pkg; do
        [ -n "$pkg" ] && printf '%s\t%s\n' "$pkg" "base_init"
      done < <(_nx_scope_pkgs "$scopes_dir/base_init.nix")
    fi
    local scopes s
    scopes="$(_nx_scopes)"
    if [ -n "$scopes" ]; then
      while IFS= read -r s; do
        while IFS= read -r pkg; do
          [ -n "$pkg" ] && printf '%s\t%s\n' "$pkg" "$s"
        done < <(_nx_scope_pkgs "$scopes_dir/$s.nix")
      done <<<"$scopes"
    fi
  }

  nx() {
    case "${1:-help}" in
    search)
      shift
      [ $# -eq 0 ] && {
        echo "Usage: nx search <query>" >&2
        return 1
      }
      local query="$*"
      # search against the locked nixpkgs in ENV_DIR (offline-capable, stable interface)
      nix search nixpkgs "$query" --json 2>/dev/null |
        jq -r 'to_entries[] | "\u001b[1m* \(.key | split(".")[-1])\u001b[0m (\(.value.version))\n  \(.value.description // "")\n"'
      ;;
    install | add)
      shift
      [ $# -eq 0 ] && {
        echo "Usage: nx install <pkg> [pkg...]" >&2
        return 1
      }
      # validate packages exist in nixpkgs
      local validated=() p
      for p in "$@"; do
        printf "\e[90mvalidating %s...\e[0m\r" "$p"
        if _nx_validate_pkg "$p"; then
          validated+=("$p")
        else
          printf "\e[31m%s not found in nixpkgs\e[0m\n" "$p" >&2
        fi
      done
      [ ${#validated[@]} -eq 0 ] && return 1
      # build scope package lookup (pkg\tscope lines)
      local scope_pkgs
      scope_pkgs="$(_nx_all_scope_pkgs)"
      local current added=false
      current="$(_nx_read_pkgs)"
      {
        [ -n "$current" ] && printf '%s\n' "$current"
        for p in "${validated[@]}"; do
          # check if already in a scope
          local in_scope
          in_scope="$(printf '%s\n' "$scope_pkgs" | grep -m1 "^${p}	" 2>/dev/null | cut -f2)"
          if [ -n "$in_scope" ]; then
            printf "\e[33m%s is already installed in scope '%s'\e[0m\n" "$p" "$in_scope" >&2
          elif printf '%s\n' "$current" | grep -qx "$p" 2>/dev/null; then
            printf "\e[33m%s is already installed (extra)\e[0m\n" "$p" >&2
          else
            printf '%s\n' "$p"
            printf "\e[32madded %s\e[0m\n" "$p" >&2
            added=true
          fi
        done
      } | _nx_write_pkgs
      [ "$added" = true ] && _nx_apply
      ;;
    remove | uninstall)
      shift
      [ $# -eq 0 ] && {
        echo "Usage: nx remove <pkg> [pkg...]" >&2
        return 1
      }
      # check for scope-managed packages first
      local scope_pkgs
      scope_pkgs="$(_nx_all_scope_pkgs)"
      local filtered_args=()
      local p
      for p in "$@"; do
        local in_scope
        in_scope="$(printf '%s\n' "$scope_pkgs" | grep -m1 "^${p}	" 2>/dev/null | cut -f2)"
        if [ -n "$in_scope" ]; then
          printf "\e[33m%s is managed by scope '%s' - use: nx scope remove %s\e[0m\n" "$p" "$in_scope" "$in_scope" >&2
        else
          filtered_args+=("$p")
        fi
      done
      [ ${#filtered_args[@]} -eq 0 ] && return 0
      local current removed=false
      current="$(_nx_read_pkgs)"
      if [ -z "$current" ]; then
        printf "\e[33mNo user packages installed.\e[0m\n"
        return 0
      fi
      local remove_pattern=" ${filtered_args[*]} "
      {
        while IFS= read -r p; do
          if [[ " $remove_pattern " == *" $p "* ]]; then
            printf "\e[32mremoved %s\e[0m\n" "$p" >&2
            removed=true
          else
            printf '%s\n' "$p"
          fi
        done <<<"$current"
      } | _nx_write_pkgs
      # warn about packages not found in extra
      for p in "${filtered_args[@]}"; do
        if ! printf '%s\n' "$current" | grep -qx "$p" 2>/dev/null; then
          printf "\e[33m%s is not installed - skipping\e[0m\n" "$p" >&2
        fi
      done
      [ "$removed" = true ] && _nx_apply
      ;;
    upgrade | update)
      shift
      printf "\e[96mupgrading packages...\e[0m\n"
      local _pinned_rev=""
      [ -f "$_NX_ENV_DIR/pinned_rev" ] && _pinned_rev="$(tr -d '[:space:]' <"$_NX_ENV_DIR/pinned_rev")"
      if [ -n "$_pinned_rev" ]; then
        printf "\e[96mpinning nixpkgs to %s\e[0m\n" "$_pinned_rev"
        nix flake lock --override-input nixpkgs "github:nixos/nixpkgs/$_pinned_rev" --flake "$_NX_ENV_DIR" 2>/dev/null ||
          printf "\e[33mflake lock failed - using existing lock\e[0m\n" >&2
      else
        nix flake update --flake "$_NX_ENV_DIR" 2>/dev/null ||
          printf "\e[33mflake update failed (network issue?) - using existing lock\e[0m\n" >&2
      fi
      nix profile upgrade nix-env || {
        printf "\e[31mnix profile upgrade failed\e[0m\n" >&2
        return 1
      }
      printf "\e[32mdone.\e[0m\n"
      ;;
    list | ls)
      local env_dir="$_NX_ENV_DIR"
      local scopes_dir="$env_dir/scopes"
      # collect all packages with scope annotations, then sort
      local all_pkgs
      all_pkgs="$({
        # base packages (always present)
        if [ -d "$scopes_dir" ]; then
          local pkg
          while IFS= read -r pkg; do
            [ -n "$pkg" ] && printf '%s\t(base)\n' "$pkg"
          done < <(_nx_scope_pkgs "$scopes_dir/base.nix")
          # base_init packages (when isInit is true)
          if [ "$(_nx_is_init)" = "true" ]; then
            while IFS= read -r pkg; do
              [ -n "$pkg" ] && printf '%s\t(base_init)\n' "$pkg"
            done < <(_nx_scope_pkgs "$scopes_dir/base_init.nix")
          fi
        fi
        # configured scopes
        local scopes s
        scopes="$(_nx_scopes)"
        if [ -n "$scopes" ]; then
          while IFS= read -r s; do
            while IFS= read -r pkg; do
              [ -n "$pkg" ] && printf '%s\t(%s)\n' "$pkg" "$s"
            done < <(_nx_scope_pkgs "$scopes_dir/$s.nix")
          done <<<"$scopes"
        fi
        # user packages (extra)
        local pkgs
        pkgs="$(_nx_read_pkgs)"
        if [ -n "$pkgs" ]; then
          while IFS= read -r pkg; do
            [ -n "$pkg" ] && printf '%s\t(extra)\n' "$pkg"
          done <<<"$pkgs"
        fi
      } | sort -t$'\t' -k1,1 -u)"
      if [ -n "$all_pkgs" ]; then
        while IFS=$'\t' read -r name scope; do
          printf "  \e[1m*\e[0m %-24s \e[90m%s\e[0m\n" "$name" "$scope"
        done <<<"$all_pkgs"
      else
        printf "\e[33mNo packages installed.\e[0m Use \e[1mnx install <pkg>\e[0m or run \e[1mnix/setup.sh\e[0m.\n"
      fi
      ;;
    scope)
      shift
      local env_dir="$_NX_ENV_DIR"
      local config_nix="$env_dir/config.nix"
      local scopes_dir="$env_dir/scopes"
      case "${1:-help}" in
      list | ls)
        local scopes
        scopes="$(_nx_scopes)"
        if [ -n "$scopes" ]; then
          printf "\e[96mInstalled scopes:\e[0m\n"
          while IFS= read -r s; do
            printf "  \e[1m*\e[0m %s\n" "$s"
          done <<<"$scopes"
        else
          printf "\e[33mNo scopes configured.\e[0m Run \e[1mnix/setup.sh\e[0m to initialize.\n"
        fi
        ;;
      show)
        shift
        [ $# -eq 0 ] && {
          echo "Usage: nx scope show <scope>" >&2
          return 1
        }
        local scope_file="$scopes_dir/$1.nix"
        if [ ! -f "$scope_file" ]; then
          printf "\e[31mScope '%s' not found.\e[0m\n" "$1" >&2
          return 1
        fi
        printf "\e[96m%s:\e[0m\n" "$1"
        local pkg
        while IFS= read -r pkg; do
          [ -n "$pkg" ] && printf "  \e[1m*\e[0m %s\n" "$pkg"
        done < <(_nx_scope_pkgs "$scope_file")
        ;;
      tree)
        local scopes s
        # base is always present
        if [ -d "$scopes_dir" ]; then
          printf "\e[96mbase:\e[0m\n"
          while IFS= read -r pkg; do
            [ -n "$pkg" ] && printf "  \e[1m*\e[0m %s\n" "$pkg"
          done < <(_nx_scope_pkgs "$scopes_dir/base.nix")
        fi
        scopes="$(_nx_scopes)"
        if [ -n "$scopes" ]; then
          while IFS= read -r s; do
            printf "\e[96m%s:\e[0m\n" "$s"
            while IFS= read -r pkg; do
              [ -n "$pkg" ] && printf "  \e[1m*\e[0m %s\n" "$pkg"
            done < <(_nx_scope_pkgs "$scopes_dir/$s.nix")
          done <<<"$scopes"
        fi
        local pkgs
        pkgs="$(_nx_read_pkgs)"
        if [ -n "$pkgs" ]; then
          printf "\e[96mextra:\e[0m\n"
          while IFS= read -r pkg; do
            [ -n "$pkg" ] && printf "  \e[1m*\e[0m %s\n" "$pkg"
          done <<<"$pkgs"
        fi
        ;;
      remove | rm)
        shift
        [ $# -eq 0 ] && {
          echo "Usage: nx scope remove <scope> [scope...]" >&2
          return 1
        }
        if [ ! -f "$config_nix" ]; then
          printf "\e[31mNo nix-env config found. Run nix/setup.sh to initialize.\e[0m\n" >&2
          return 1
        fi
        local current_scopes is_init
        current_scopes="$(_nx_scopes)"
        is_init="$(_nx_is_init)"
        if [ -z "$current_scopes" ]; then
          printf "\e[33mNo scopes configured - nothing to remove.\e[0m\n"
          return 0
        fi
        local ov_dir="$env_dir/local"
        if [ -n "${NIX_ENV_OVERLAY_DIR:-}" ] && [ -d "$NIX_ENV_OVERLAY_DIR" ]; then
          ov_dir="$NIX_ENV_OVERLAY_DIR"
        fi
        # build removal set: for each name, match both "name" and "local_name" in config
        local remove_set=" "
        local r
        for r in "$@"; do
          remove_set+="$r local_$r "
        done
        local remaining=() removed=false
        while IFS= read -r s; do
          if [[ " $remove_set " == *" $s "* ]]; then
            printf "\e[32mremoved scope: %s\e[0m\n" "${s#local_}"
            removed=true
          else
            remaining+=("$s")
          fi
        done <<<"$current_scopes"
        # clean up overlay + installed scope files
        for r in "$@"; do
          rm -f "$ov_dir/scopes/$r.nix" "$scopes_dir/local_$r.nix"
          if [ -f "$scopes_dir/$r.nix" ] && [[ "$r" != local_* ]]; then
            : # repo scope - don't delete the file, setup.sh will re-sync it
          fi
        done
        # report names not found anywhere
        for r in "$@"; do
          if [[ " $remove_set " == *" $r "* ]]; then
            local _found=false
            printf '%s\n' "$current_scopes" | grep -qx "$r" 2>/dev/null && _found=true
            printf '%s\n' "$current_scopes" | grep -qx "local_$r" 2>/dev/null && _found=true
            [ "$_found" = false ] && printf "\e[33mscope '%s' is not configured - skipping\e[0m\n" "$r" >&2
          fi
        done
        if [ "$removed" = false ]; then
          return 0
        fi
        local nix_scopes=""
        local s
        for s in "${remaining[@]}"; do
          nix_scopes+="    \"$s\""$'\n'
        done
        local tmp
        tmp="$(mktemp)"
        cat >"$tmp" <<EOF
# Generated by nx scope remove - re-run nix/setup.sh to reconfigure.
{
  isInit = ${is_init:-false};

  scopes = [
$nix_scopes  ];
}
EOF
        mv "$tmp" "$config_nix"
        _nx_apply
        printf "Restart your shell to apply changes.\n"
        ;;
      add | create)
        shift
        [ $# -eq 0 ] && {
          echo "Usage: nx scope add <name> [pkg...]" >&2
          return 1
        }
        local name="${1//-/_}"
        shift
        local ov_dir="$env_dir/local"
        if [ -n "${NIX_ENV_OVERLAY_DIR:-}" ] && [ -d "$NIX_ENV_OVERLAY_DIR" ]; then
          ov_dir="$NIX_ENV_OVERLAY_DIR"
        fi
        local scope_file="$ov_dir/scopes/$name.nix"
        local created=false
        if [ ! -f "$scope_file" ]; then
          mkdir -p "$ov_dir/scopes" "$scopes_dir"
          printf '{ pkgs }: with pkgs; []\n' >"$scope_file"
          command cp "$scope_file" "$scopes_dir/local_$name.nix"
          if [ -f "$config_nix" ]; then
            local current_scopes
            current_scopes="$(_nx_scopes)"
            if ! printf '%s\n' "$current_scopes" | grep -qx "local_$name" 2>/dev/null; then
              local is_init
              is_init="$(_nx_is_init)"
              local all_scopes=()
              if [ -n "$current_scopes" ]; then
                while IFS= read -r s; do
                  all_scopes+=("$s")
                done <<<"$current_scopes"
              fi
              all_scopes+=("local_$name")
              local nix_scopes=""
              for s in "${all_scopes[@]}"; do
                nix_scopes+="    \"$s\""$'\n'
              done
              cat >"$config_nix" <<SCOPE_ADD_EOF
# Generated by nx scope add - re-run nix/setup.sh to reconfigure.
{
  isInit = ${is_init:-false};

  scopes = [
$nix_scopes  ];
}
SCOPE_ADD_EOF
            fi
          fi
          created=true
          printf "\e[32mCreated scope '%s' at %s\e[0m\n" "$name" "$scope_file"
        fi
        if [ $# -gt 0 ]; then
          local validated=() p
          for p in "$@"; do
            printf "\e[90mvalidating %s...\e[0m\r" "$p"
            if _nx_validate_pkg "$p"; then
              validated+=("$p")
            else
              printf "\e[31m%s not found in nixpkgs\e[0m\n" "$p" >&2
            fi
          done
          if [ ${#validated[@]} -gt 0 ]; then
            _nx_scope_file_add "$scope_file" "${validated[@]}"
            command cp "$scope_file" "$scopes_dir/local_$name.nix"
            _nx_apply
          fi
        elif [ "$created" = true ]; then
          printf "Add packages: \e[1mnx scope add %s <pkg> [pkg...]\e[0m\n" "$name"
        else
          printf "\e[33mScope '%s' already exists.\e[0m Add packages: nx scope add %s <pkg>\n" "$name" "$name"
        fi
        ;;
      edit)
        shift
        [ $# -eq 0 ] && {
          echo "Usage: nx scope edit <name>" >&2
          return 1
        }
        local name="${1//-/_}"
        local ov_dir="$env_dir/local"
        if [ -n "${NIX_ENV_OVERLAY_DIR:-}" ] && [ -d "$NIX_ENV_OVERLAY_DIR" ]; then
          ov_dir="$NIX_ENV_OVERLAY_DIR"
        fi
        local scope_file="$ov_dir/scopes/$name.nix"
        if [ ! -f "$scope_file" ]; then
          printf "\e[31mScope '%s' not found.\e[0m Create it first: nx scope add %s\n" "$name" "$name" >&2
          return 1
        fi
        "${EDITOR:-vi}" "$scope_file"
        command cp "$scope_file" "$scopes_dir/local_$name.nix"
        printf "\e[32mSynced scope '%s'.\e[0m Run \e[1mnx upgrade\e[0m to apply.\n" "$name"
        ;;
      *)
        cat <<'EOF'
Usage: nx scope <command> [args]

Commands:
  list                      List enabled scopes
  show <scope>              Show packages in a scope
  tree                      Show all scopes with their packages
  add <name> [pkg...]       Create a scope or add packages to it
  edit <name>               Open a scope file in $EDITOR
  remove <scope> [scope...] Remove one or more scopes
EOF
        ;;
      esac
      ;;
    profile)
      shift
      # shell rc profile block management (not the nix profile)
      local _pb_marker="nix-env managed"
      # legacy marker strings injected by the old grep-then-append pattern
      local _pb_legacy_markers=(
        'aliases_nix' 'aliases_git' 'aliases_kubectl' 'functions.sh'
        'fzf --bash' 'fzf --zsh' 'uv generate-shell-completion'
        'kubectl completion' 'Makefile'
        'NODE_EXTRA_CA_CERTS' 'REQUESTS_CA_BUNDLE' 'CLOUDSDK_CORE_CUSTOM_CA_CERTS_FILE'
        'nix-profile/bin:' '.local/bin' 'nix-daemon.sh'
      )
      # rc files managed by setup
      local _pb_rc_files=("$HOME/.bashrc" "$HOME/.zshrc")

      # source manage_block if available
      local _pb_lib
      _pb_lib="$(dirname "$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "$HOME/.config/bash/aliases_nix.sh")")"
      local _pb_lib_path
      for _pb_lib_path in \
        "$_pb_lib/../../lib/profile_block.sh" \
        "$HOME/.config/bash/../../../.assets/lib/profile_block.sh"; do
        [ -f "$_pb_lib_path" ] && { source "$_pb_lib_path"; break; }
      done

      case "${1:-help}" in
      doctor)
        # Check managed block health in rc files
        local _pb_ok=true
        local _pb_rc
        for _pb_rc in "${_pb_rc_files[@]}"; do
          [ -f "$_pb_rc" ] || continue
          local _pb_count
          _pb_count="$(grep -cF "# >>> $_pb_marker >>>" "$_pb_rc" 2>/dev/null || true)"
          if [ "$_pb_count" -eq 0 ] 2>/dev/null; then
            printf "\e[33m[warn] no managed block in %s - run: nix/configure/profiles.sh\e[0m\n" "$_pb_rc" >&2
            _pb_ok=false
          elif [ "$_pb_count" -gt 1 ] 2>/dev/null; then
            printf "\e[31m[fail] %s duplicate managed blocks in %s - run: nx profile migrate\e[0m\n" \
              "$_pb_count" "$_pb_rc" >&2
            _pb_ok=false
          fi
          local _pb_m
          for _pb_m in "${_pb_legacy_markers[@]}"; do
            if grep -qF "$_pb_m" "$_pb_rc" 2>/dev/null; then
              # only warn if it's outside the managed block
              local _pb_outside
              _pb_outside="$(awk -v begin="# >>> $_pb_marker >>>" -v end="# <<< $_pb_marker <<<" '
                $0==begin{skip=1;next} skip&&$0==end{skip=0;next} !skip{print}
              ' "$_pb_rc" | grep -cF "$_pb_m" 2>/dev/null || true)"
              if [ "$_pb_outside" -gt 0 ] 2>/dev/null; then
                printf "\e[33m[warn] legacy injection '%s' found outside managed block in %s\e[0m\n" \
                  "$_pb_m" "$_pb_rc" >&2
                _pb_ok=false
              fi
            fi
          done
        done
        [ "$_pb_ok" = true ] && printf "\e[32m[ok] managed profile blocks look healthy\e[0m\n"
        [ "$_pb_ok" = true ] || return 1
        ;;
      migrate)
        # Remove legacy injections and re-run profiles.sh / profiles.zsh
        local _dry_run=false
        [ "${2:-}" = "--dry-run" ] && _dry_run=true
        printf "\e[96mScanning for legacy profile injections...\e[0m\n"
        local _pb_rc _pb_m _found=false
        for _pb_rc in "${_pb_rc_files[@]}"; do
          [ -f "$_pb_rc" ] || continue
          # only scan lines outside the managed block
          local _outside
          _outside="$(awk -v begin="# >>> $_pb_marker >>>" -v end="# <<< $_pb_marker <<<" '
            $0==begin{skip=1;next} skip&&$0==end{skip=0;next} !skip{print}
          ' "$_pb_rc")"
          for _pb_m in "${_pb_legacy_markers[@]}"; do
            if printf '%s\n' "$_outside" | grep -qF "$_pb_m" 2>/dev/null; then
              _found=true
              printf "  found legacy marker '%s' in %s\n" "$_pb_m" "$_pb_rc"
            fi
          done
        done
        if [ "$_found" = false ]; then
          printf "\e[32mNo legacy injections found. Nothing to migrate.\e[0m\n"
          return 0
        fi
        if [ "$_dry_run" = true ]; then
          printf "\e[96m(dry-run) would remove the above markers and regenerate managed block.\e[0m\n"
          return 0
        fi
        printf "\e[96mRemoving legacy injections...\e[0m\n"
        for _pb_rc in "${_pb_rc_files[@]}"; do
          [ -f "$_pb_rc" ] || continue
          # determine which legacy markers exist outside managed block in this file
          local _outside
          _outside="$(awk -v begin="# >>> $_pb_marker >>>" -v end="# <<< $_pb_marker <<<" '
            $0==begin{skip=1;next} skip&&$0==end{skip=0;next} !skip{print}
          ' "$_pb_rc")"
          local _has_legacy=false
          for _pb_m in "${_pb_legacy_markers[@]}"; do
            printf '%s\n' "$_outside" | grep -qF "$_pb_m" 2>/dev/null && _has_legacy=true
          done
          [ "$_has_legacy" = false ] && continue
          local _backup="${_pb_rc}.nixenv-backup-$(date +%Y%m%d%H%M%S)"
          command cp -p "$_pb_rc" "$_backup"
          # remove legacy lines (and blank line immediately before them)
          # only outside the managed block
          for _pb_m in "${_pb_legacy_markers[@]}"; do
            local _tmp
            _tmp="$(mktemp)"
            awk -v begin="# >>> $_pb_marker >>>" -v end="# <<< $_pb_marker <<<" \
                -v marker="$_pb_m" '
              $0==begin        { in_block=1; print; next }
              in_block&&$0==end{ in_block=0; print; next }
              in_block         { print; next }
              /^[[:space:]]*$/  { prev_blank=1; buf=$0; next }
              index($0, marker) && !in_block {
                prev_blank=0; buf=""
                next
              }
              {
                if (prev_blank) { print buf }
                prev_blank=0; buf=""
                print
              }
              END { if (prev_blank) print buf }
            ' "$_pb_rc" >"$_tmp"
            mv -f "$_tmp" "$_pb_rc"
          done
          printf "\e[32mmigrated %s (backup: %s)\e[0m\n" "$_pb_rc" "$_backup"
        done
        printf "\e[96mRe-run nix/configure/profiles.sh (and profiles.zsh if using zsh) to install managed block.\e[0m\n"
        ;;
      uninstall)
        # Remove the managed block from all rc files
        if ! command -v manage_block &>/dev/null 2>&1 && ! type manage_block &>/dev/null 2>&1; then
          printf "\e[31mmanage_block not loaded - cannot uninstall profile\e[0m\n" >&2
          return 1
        fi
        local _pb_rc
        for _pb_rc in "${_pb_rc_files[@]}"; do
          [ -f "$_pb_rc" ] || continue
          manage_block "$_pb_rc" "$_pb_marker" remove
          printf "\e[32mremoved managed block from %s\e[0m\n" "$_pb_rc"
        done
        printf "\e[96mProfile blocks removed. Sourced files in ~/.config/bash/ are untouched.\e[0m\n"
        ;;
      help | *)
        cat <<'PROFILE_HELP'
Usage: nx profile <command>

Commands:
  doctor          Check managed block health in rc files
  migrate         Remove legacy injected lines (dry-run with --dry-run)
  uninstall       Remove managed blocks from ~/.bashrc and ~/.zshrc
  help            Show this help
PROFILE_HELP
        ;;
      esac
      ;;
    overlay)
      shift
      local env_dir="$_NX_ENV_DIR"
      local ov_dir=""
      if [ -n "${NIX_ENV_OVERLAY_DIR:-}" ] && [ -d "$NIX_ENV_OVERLAY_DIR" ]; then
        ov_dir="$NIX_ENV_OVERLAY_DIR"
      elif [ -d "$env_dir/local" ]; then
        ov_dir="$env_dir/local"
      fi
      case "${1:-list}" in
      list | ls)
        if [ -z "$ov_dir" ]; then
          printf "\e[33mNo overlay directory active.\e[0m\n"
          printf "Create one at %s/local/ or set NIX_ENV_OVERLAY_DIR.\n" "$env_dir"
          return 0
        fi
        printf "\e[96mOverlay directory:\e[0m %s\n" "$ov_dir"
        local f hdr
        hdr=false
        for f in "$ov_dir/scopes"/*.nix; do
          [ -f "$f" ] || continue
          [ "$hdr" = false ] && printf "\e[96mScopes:\e[0m\n" && hdr=true
          printf "  \e[1m*\e[0m %s\n" "$(basename "$f" .nix)"
        done
        hdr=false
        for f in "$ov_dir/bash_cfg"/*.sh; do
          [ -f "$f" ] || continue
          [ "$hdr" = false ] && printf "\e[96mShell config:\e[0m\n" && hdr=true
          printf "  \e[1m*\e[0m %s\n" "$(basename "$f")"
        done
        local hook_dir
        for hook_dir in pre-setup.d post-setup.d; do
          hdr=false
          for f in "$ov_dir/hooks/$hook_dir"/*.sh; do
            [ -f "$f" ] || continue
            [ "$hdr" = false ] && printf "\e[96mHooks (%s):\e[0m\n" "$hook_dir" && hdr=true
            printf "  \e[1m*\e[0m %s\n" "$(basename "$f")"
          done
        done
        ;;
      status)
        local scopes_dir="$env_dir/scopes"
        printf "\e[96mOverlay:\e[0m "
        if [ -n "$ov_dir" ]; then
          printf "%s\n" "$ov_dir"
        else
          printf "\e[33mnone\e[0m\n"
        fi
        local f hdr name indicator
        hdr=false
        for f in "$scopes_dir"/local_*.nix; do
          [ -f "$f" ] || continue
          [ "$hdr" = false ] && printf "\e[96mOverlay scopes (synced):\e[0m\n" && hdr=true
          name="$(basename "$f" .nix)"
          name="${name#local_}"
          indicator=""
          if [ -n "$ov_dir" ] && [ -f "$ov_dir/scopes/$name.nix" ]; then
            if ! cmp -s "$ov_dir/scopes/$name.nix" "$f" 2>/dev/null; then
              indicator=" \e[33m(modified)\e[0m"
            fi
          else
            indicator=" \e[33m(source missing)\e[0m"
          fi
          printf "  \e[1m*\e[0m %s%b\n" "$name" "$indicator"
        done
        [ "$hdr" = false ] && printf "\e[90mNo overlay scopes synced.\e[0m\n"
        if [ -n "$ov_dir" ] && [ -d "$ov_dir/bash_cfg" ]; then
          hdr=false
          for f in "$ov_dir/bash_cfg"/*.sh; do
            [ -f "$f" ] || continue
            [ "$hdr" = false ] && printf "\e[96mOverlay shell config:\e[0m\n" && hdr=true
            local bname installed
            bname="$(basename "$f")"
            installed="$HOME/.config/bash/$bname"
            indicator=""
            if [ -f "$installed" ]; then
              if cmp -s "$f" "$installed" 2>/dev/null; then
                indicator=" \e[32m(synced)\e[0m"
              else
                indicator=" \e[33m(differs)\e[0m"
              fi
            else
              indicator=" \e[33m(not installed)\e[0m"
            fi
            printf "  \e[1m*\e[0m %s%b\n" "$bname" "$indicator"
          done
        fi
        ;;
      help | *)
        cat <<'OVERLAY_HELP'
Usage: nx overlay <command>

Commands:
  list      Show active overlay directory and contents
  status    Show sync status of overlay files
  help      Show this help
OVERLAY_HELP
        ;;
      esac
      ;;
    prune)
      # remove stale imperative profile entries (anything not 'nix-env')
      local profile_json stale_names name
      profile_json="$(nix profile list --json 2>/dev/null)" || {
        printf "\e[31mFailed to list nix profile.\e[0m\n" >&2
        return 1
      }
      stale_names="$(printf '%s\n' "$profile_json" | jq -r '.elements | keys[] | select(. != "nix-env")')"
      if [ -z "$stale_names" ]; then
        printf "\e[32mNo stale profile entries found.\e[0m\n"
        return 0
      fi
      printf "\e[96mStale profile entries:\e[0m\n"
      while IFS= read -r name; do
        printf "  \e[1m*\e[0m %s\n" "$name"
      done <<<"$stale_names"
      printf "\e[96mRemoving...\e[0m\n"
      while IFS= read -r name; do
        nix profile remove "$name" && printf "\e[32mremoved %s\e[0m\n" "$name"
      done <<<"$stale_names"
      printf "\e[32mdone.\e[0m Run \e[1mnx gc\e[0m to free disk space.\n"
      ;;
    gc | clean)
      nix profile wipe-history
      nix store gc
      ;;
    rollback)
      nix profile rollback || {
        printf "\e[31mnix profile rollback failed\e[0m\n" >&2
        return 1
      }
      printf "\e[32mRolled back to previous profile generation.\e[0m\n"
      printf "Restart your shell to apply changes.\n"
      ;;
    pin)
      shift
      local _pin_file="$_NX_ENV_DIR/pinned_rev"
      case "${1:-show}" in
      set)
        shift
        local _rev="${1:-}"
        if [ -z "$_rev" ]; then
          local _lock="$_NX_ENV_DIR/flake.lock"
          [ -f "$_lock" ] || {
            printf "\e[31mNo flake.lock found - run nx upgrade first.\e[0m\n" >&2
            return 1
          }
          _rev="$(jq -r '.nodes.nixpkgs.locked.rev' "$_lock" 2>/dev/null)" || true
          [ -n "$_rev" ] && [ "$_rev" != "null" ] || {
            printf "\e[31mCould not read nixpkgs revision from flake.lock.\e[0m\n" >&2
            return 1
          }
        fi
        printf '%s\n' "$_rev" >"$_pin_file"
        printf "\e[32mPinned nixpkgs to %s\e[0m\n" "$_rev"
        ;;
      remove | rm)
        if [ -f "$_pin_file" ]; then
          rm "$_pin_file"
          printf "\e[32mPin removed.\e[0m Upgrades will use latest nixpkgs-unstable.\n"
        else
          printf "\e[90mNo pin set.\e[0m\n"
        fi
        ;;
      show)
        if [ -f "$_pin_file" ]; then
          printf "\e[96mPinned to:\e[0m %s\n" "$(tr -d '[:space:]' <"$_pin_file")"
        else
          printf "\e[90mNo pin set.\e[0m Upgrades use latest nixpkgs-unstable.\n"
        fi
        ;;
      help | *)
        cat <<'PIN_HELP'
Usage: nx pin <command>

Commands:
  set [rev]   Pin nixpkgs to a commit SHA (default: current flake.lock rev)
  remove      Remove the pin (use latest nixpkgs-unstable)
  show        Show current pin status (default)
  help        Show this help

The pin takes effect on the next `nx upgrade` or `nix/setup.sh --upgrade`.
PIN_HELP
        ;;
      esac
      ;;
    doctor)
      local _dr_script
      for _dr_script in \
        "$(dirname "$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "$HOME/.config/bash/aliases_nix.sh")")/../../.assets/lib/nx_doctor.sh" \
        "$HOME/.config/nix-env/nx_doctor.sh"; do
        if [ -f "$_dr_script" ]; then
          bash "$_dr_script" "${@:2}"
          return $?
        fi
      done
      printf '\e[31mnx doctor not found\e[0m\n' >&2
      return 1
      ;;
    version)
      devenv
      ;;
    help | -h | --help)
      cat <<'EOF'
Usage: nx <command> [args]

Commands:
  search  <query>         Search for packages in nixpkgs
  install <pkg> [pkg...]  Install packages (declarative, via packages.nix)
  remove  <pkg> [pkg...]  Remove user-installed packages
  upgrade                 Upgrade all packages to latest nixpkgs
  rollback                Roll back to previous profile generation
  pin                     Pin nixpkgs to a specific revision (nx pin help)
  list                    List all installed packages with scope annotations
  scope                   Manage scopes (nx scope help)
  overlay                 Manage overlay directory (nx overlay help)
  profile                 Manage shell rc profile blocks (nx profile help)
  doctor                  Run health checks on the nix-env environment
  prune                   Remove stale imperative profile entries
  gc                      Garbage collect old versions and free disk space
  version                 Show installation provenance and version info
  help                    Show this help
EOF
      ;;
    *)
      printf "\e[31mUnknown command: %s\e[0m\n" "$1" >&2
      nx help
      return 1
      ;;
    esac
  }

  # bash completion for nx
  _nx_completions() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD - 1]}"

    if [ "$COMP_CWORD" -eq 1 ]; then
      while IFS= read -r line; do COMPREPLY+=("$line"); done < <(compgen -W "search install remove upgrade rollback pin list scope overlay profile doctor prune gc version help" -- "$cur")
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "scope" ]; then
      while IFS= read -r line; do COMPREPLY+=("$line"); done < <(compgen -W "list show tree add edit remove" -- "$cur")
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "overlay" ]; then
      while IFS= read -r line; do COMPREPLY+=("$line"); done < <(compgen -W "list status help" -- "$cur")
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "pin" ]; then
      while IFS= read -r line; do COMPREPLY+=("$line"); done < <(compgen -W "set remove show help" -- "$cur")
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "profile" ]; then
      while IFS= read -r line; do COMPREPLY+=("$line"); done < <(compgen -W "doctor migrate uninstall help" -- "$cur")
    fi
  }
  complete -F _nx_completions nx
fi
#endregion
