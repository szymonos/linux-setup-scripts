# phase: configure
# GitHub CLI auth, git config, scope-based post-install configuration.
# shellcheck disable=SC2154  # globals set by bootstrap phase
#
# Reads:  CONFIGURE_DIR, sorted_scopes, omp_theme, starship_theme
# Writes: GITHUB_TOKEN

phase_configure_gh() {
  local unattended="${1:-false}"
  _io_run "$CONFIGURE_DIR/gh.sh" "$unattended"
  if [[ -z "${GITHUB_TOKEN:-}" ]] && command -v gh &>/dev/null && gh auth token &>/dev/null; then
    GITHUB_TOKEN="$(gh auth token 2>/dev/null)"
    export GITHUB_TOKEN
  fi
}

phase_configure_git() {
  local unattended="${1:-false}"
  if [[ "$unattended" != "true" ]]; then
    _io_run "$CONFIGURE_DIR/git.sh"
  fi
}

phase_configure_per_scope() {
  local sc
  for sc in "${sorted_scopes[@]}"; do
    case $sc in
    docker)
      _io_run "$CONFIGURE_DIR/docker.sh"
      ;;
    conda)
      _io_run "$CONFIGURE_DIR/conda.sh"
      ;;
    az)
      _io_run "$CONFIGURE_DIR/az.sh"
      ;;
    oh_my_posh)
      _io_run "$CONFIGURE_DIR/omp.sh" "$omp_theme"
      ;;
    starship)
      _io_run "$CONFIGURE_DIR/starship.sh" "$starship_theme"
      ;;
    esac
  done
}
