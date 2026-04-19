# Side-effect wrappers for nix/setup.sh phases.
# Tests override these functions to stub external commands.

# -- Output helpers ------------------------------------------------------------
info() { printf "\e[96m%s\e[0m\n" "$*"; }
ok() { printf "\e[32m%s\e[0m\n" "$*"; }
warn() { printf "\e[33m%s\e[0m\n" "$*" >&2; }
err() { printf "\e[31;1m%s\e[0m\n" "$*" >&2; }

# -- Thin shims for external commands ------------------------------------------
# Phases call these instead of the raw commands. Tests redefine them to assert
# the right commands are issued without executing them.
_io_nix() { nix "$@"; }
_io_nix_eval() { nix eval --impure --raw --expr "$1"; }
_io_curl_probe() { curl -sS "$1" >/dev/null 2>&1; }
_io_run() { "$@"; }
