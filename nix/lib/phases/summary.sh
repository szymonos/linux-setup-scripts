# phase: summary
# Mode detection and final status output.
# shellcheck disable=SC2154  # globals set by bootstrap phase
#
# Reads:  upgrade_packages, remove_scopes, any_scope, quiet_summary,
#         platform, sorted_scopes
# Writes: _mode

phase_summary_detect_mode() {
  if [[ "$upgrade_packages" == "true" ]]; then
    _mode="upgrade"
  elif [[ ${#remove_scopes[@]} -gt 0 ]]; then
    _mode="remove"
  elif [[ "$any_scope" == "true" ]]; then
    _mode="install"
  else
    _mode="reconfigure"
  fi
}

phase_summary_print() {
  [[ "$quiet_summary" == "true" ]] && return 0

  printf "\n\e[95;1m<< Setup completed successfully >>\e[0m\n"
  if [[ "$_mode" == "remove" ]]; then
    printf "\e[90mPlatform: %s | Mode: remove | Removed: %s | Scopes: %s\e[0m\n" "$platform" "${remove_scopes[*]}" "${sorted_scopes[*]}"
  else
    printf "\e[90mPlatform: %s | Mode: %s | Scopes: %s\e[0m\n" "$platform" "$_mode" "${sorted_scopes[*]}"
  fi
  local invoking_shell
  invoking_shell="$(ps -o comm= -p "$PPID" 2>/dev/null | sed 's/^-//')" || true
  invoking_shell="${invoking_shell:-$(basename "$SHELL")}"
  case "$invoking_shell" in
  zsh) printf "\e[97mRestart your terminal or run \e[4msource ~/.zshrc\e[24m to apply changes.\e[0m\n\n" ;;
  bash) printf "\e[97mRestart your terminal or run \e[4msource ~/.bashrc\e[24m to apply changes.\e[0m\n\n" ;;
  pwsh) printf "\e[97mRestart your terminal or run \e[4m. \$PROFILE\e[24m to apply changes.\e[0m\n\n" ;;
  *) printf "\e[97mRestart your terminal to apply changes.\e[0m\n\n" ;;
  esac
}
