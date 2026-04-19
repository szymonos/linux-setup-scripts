# phase: profiles
# Bash, zsh, and PowerShell shell profile setup.
#
# Reads:  CONFIGURE_DIR

phase_profiles_bash() {
  _io_run "$CONFIGURE_DIR/profiles.sh"
}

phase_profiles_zsh() {
  if command -v zsh &>/dev/null; then
    _io_run "$CONFIGURE_DIR/profiles.zsh"
  fi
}

phase_profiles_pwsh() {
  if command -v pwsh &>/dev/null; then
    _io_run pwsh -nop "$CONFIGURE_DIR/profiles.ps1"
  fi
}
