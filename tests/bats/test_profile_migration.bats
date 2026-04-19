#!/usr/bin/env bats
# Integration tests for nx profile subcommand and legacy-to-managed-block migration
bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
ALIASES_NIX="$REPO_ROOT/.assets/config/bash_cfg/aliases_nix.sh"

setup() {
  TEST_DIR="$(mktemp -d)"
  export HOME="$TEST_DIR"
  mkdir -p "$TEST_DIR/.config/bash"

  # Source the library and the aliases (nix guard won't fire - nix not available)
  # We need manage_block available for the profile subcommand
  # shellcheck source=../../.assets/lib/profile_block.sh
  source "$REPO_ROOT/.assets/lib/profile_block.sh"

  # Stub nix so the `if command -v nix` guard in aliases_nix.sh fires
  nix() { return 0; }
  export -f nix

  # shellcheck source=../../.assets/config/bash_cfg/aliases_nix.sh
  source "$ALIASES_NIX"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
_write_legacy_bashrc() {
  cat >"$HOME/.bashrc" <<'RC'
# existing user content
alias ll='ls -la'

# Nix
export PATH="$HOME/.nix-profile/bin:$PATH"

# nix aliases
. "$HOME/.config/bash/aliases_nix.sh"

# git aliases
. "$HOME/.config/bash/aliases_git.sh"

# fzf integration
[ -x "$HOME/.nix-profile/bin/fzf" ] && eval "$(fzf --bash)"

# NODE_EXTRA_CA_CERTS handled elsewhere
RC
}

_write_clean_bashrc_with_block() {
  local marker="nix-env managed"
  cat >"$HOME/.bashrc" <<RC
# user content above
alias ll='ls -la'

# >>> $marker >>>
export PATH="\$HOME/.nix-profile/bin:\$PATH"
. "\$HOME/.config/bash/aliases_nix.sh"
# <<< $marker <<<

# user content below
alias gs='git status'
RC
}

# ---------------------------------------------------------------------------
# nx profile doctor
# ---------------------------------------------------------------------------

@test "profile doctor warns when no managed block" {
  printf '# just some content\n' >"$HOME/.bashrc"
  run nx profile doctor
  [ "$status" -ne 0 ]
  [[ "$output" =~ "no managed block" ]]
}

@test "profile doctor passes when managed block present" {
  _write_clean_bashrc_with_block
  run nx profile doctor
  [ "$status" -eq 0 ]
  [[ "$output" =~ "healthy" ]]
}

@test "profile doctor detects legacy marker outside managed block" {
  _write_clean_bashrc_with_block
  printf '\n# nix aliases\n. "$HOME/.config/bash/aliases_nix.sh"\n' >>"$HOME/.bashrc"
  run nx profile doctor
  [ "$status" -ne 0 ]
  [[ "$output" =~ "legacy" ]]
}

@test "profile doctor ignores legacy marker inside managed block" {
  # The managed block itself contains 'aliases_nix' - doctor should not flag it
  local marker="nix-env managed"
  cat >"$HOME/.bashrc" <<RC
# >>> $marker >>>
. "\$HOME/.config/bash/aliases_nix.sh"
# <<< $marker <<<
RC
  run nx profile doctor
  [ "$status" -eq 0 ]
}

@test "profile doctor fails on duplicate managed blocks" {
  local marker="nix-env managed"
  cat >"$HOME/.bashrc" <<RC
# >>> $marker >>>
export A=1
# <<< $marker <<<
# >>> $marker >>>
export A=1
# <<< $marker <<<
RC
  run nx profile doctor
  [ "$status" -ne 0 ]
  [[ "$output" =~ "duplicate" ]]
}

# ---------------------------------------------------------------------------
# nx profile migrate
# ---------------------------------------------------------------------------

@test "profile migrate --dry-run reports legacy markers without modifying rc" {
  _write_legacy_bashrc
  local before
  before="$(cat "$HOME/.bashrc")"
  run nx profile migrate --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dry-run" ]]
  [ "$(cat "$HOME/.bashrc")" = "$before" ]
}

@test "profile migrate reports no legacy markers on clean rc" {
  _write_clean_bashrc_with_block
  run nx profile migrate
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Nothing to migrate" ]]
}

@test "profile migrate removes known legacy markers" {
  _write_legacy_bashrc
  run nx profile migrate
  [ "$status" -eq 0 ]
  # legacy markers should be gone from rc
  run grep -c 'aliases_nix' "$HOME/.bashrc"
  [ "$output" -eq 0 ]
  run grep -c 'NODE_EXTRA_CA_CERTS' "$HOME/.bashrc"
  [ "$output" -eq 0 ]
}

@test "profile migrate preserves user content outside legacy lines" {
  _write_legacy_bashrc
  nx profile migrate
  grep -q "alias ll='ls -la'" "$HOME/.bashrc"
}

@test "profile migrate creates a backup file" {
  _write_legacy_bashrc
  nx profile migrate
  local backups
  backups="$(find "$HOME" -name '.bashrc.nixenv-backup-*' 2>/dev/null | wc -l)"
  [ "$backups" -ge 1 ]
}

# ---------------------------------------------------------------------------
# nx profile uninstall
# ---------------------------------------------------------------------------

@test "profile uninstall removes managed block from bashrc" {
  _write_clean_bashrc_with_block
  run nx profile uninstall
  [ "$status" -eq 0 ]
  run grep -cF "# >>> nix-env managed >>>" "$HOME/.bashrc"
  [ "$output" -eq 0 ]
}

@test "profile uninstall preserves content outside the block" {
  _write_clean_bashrc_with_block
  nx profile uninstall
  grep -q "alias ll='ls -la'" "$HOME/.bashrc"
  grep -q "alias gs='git status'" "$HOME/.bashrc"
}

@test "profile uninstall is a no-op on rc without managed block" {
  printf 'just user content\n' >"$HOME/.bashrc"
  run nx profile uninstall
  [ "$status" -eq 0 ]
  grep -q "just user content" "$HOME/.bashrc"
}

@test "profile doctor fails after uninstall" {
  _write_clean_bashrc_with_block
  nx profile uninstall
  run nx profile doctor
  [ "$status" -ne 0 ]
}
