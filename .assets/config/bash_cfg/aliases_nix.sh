# guard: skip when sourced by non-bash shells (e.g. dash via /etc/profile.d/)
[ -z "$BASH_VERSION" ] && return 0

# nix package management wrapper (apt/brew-like UX)
if command -v nix &>/dev/null; then
  nx() {
    case "${1:-help}" in
      search)
        shift
        [ $# -eq 0 ] && { echo "Usage: nx search <query>" >&2; return 1; }
        local query="$*"
        # use the NixOS search API for instant results instead of slow local eval
        curl -sS "https://search.nixos.org/backend/latest-42-nixos-unstable/_search" \
          -H 'Content-Type: application/json' \
          -d "{\"from\":0,\"size\":20,\"query\":{\"bool\":{\"must\":[{\"dis_max\":{\"queries\":[{\"multi_match\":{\"query\":\"$query\",\"type\":\"cross_fields\",\"fields\":[\"package_attr_name^9\",\"package_attr_name.*^5.3999999999999995\",\"package_pname^6\",\"package_pname.*^3.5999999999999996\",\"package_description^1.3\",\"package_description.*^0.78\",\"package_longDescription^1\",\"package_longDescription.*^0.6\",\"flake_name^0.5\",\"flake_name.*^0.3\"]}}]}}]}},\"_source\":[\"package_attr_name\",\"package_pversion\",\"package_description\"]}" 2>/dev/null \
        | jq -r '.hits.hits[]._source | "\u001b[1m* \(.package_attr_name)\u001b[0m (\(.package_pversion))\n  \(.package_description // "")\n"'
        ;;
      install|add)
        shift
        [ $# -eq 0 ] && { echo "Usage: nx install <pkg> [pkg...]" >&2; return 1; }
        local pkgs=()
        local p; for p in "$@"; do pkgs+=("nixpkgs#$p"); done
        nix profile add "${pkgs[@]}"
        ;;
      remove|uninstall)
        shift
        [ $# -eq 0 ] && { echo "Usage: nx remove <pkg> [pkg...]" >&2; return 1; }
        local p; for p in "$@"; do
          nix profile remove "$p" || printf "\e[33mfailed to remove: %s\e[0m\n" "$p" >&2
        done
        ;;
      upgrade|update)
        shift
        if [ $# -eq 0 ]; then
          nix profile upgrade --all
        else
          local p; for p in "$@"; do nix profile upgrade "nixpkgs#$p"; done
        fi
        ;;
      list|ls)
        nix profile list
        ;;
      gc|clean)
        nix profile wipe-history
        nix store gc
        ;;
      help|-h|--help)
        cat <<'EOF'
Usage: nx <command> [args]

Commands:
  search  <query>         Search for packages in nixpkgs
  install <pkg> [pkg...]  Install one or more packages
  remove  <pkg> [pkg...]  Remove one or more packages
  upgrade [pkg]           Upgrade all packages or a specific one
  list                    List installed packages
  gc                      Garbage collect old versions and free disk space
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
    local cur commands
    cur="${COMP_WORDS[COMP_CWORD]}"
    commands="search install remove upgrade list gc help"

    if [ "$COMP_CWORD" -eq 1 ]; then
      mapfile -t COMPREPLY < <(compgen -W "$commands" -- "$cur")
    fi
  }
  complete -F _nx_completions nx
fi
