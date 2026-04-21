#!/usr/bin/env bash
: '
# run health check
bash .assets/lib/nx_doctor.sh
# :strict mode (warnings are failures)
bash .assets/lib/nx_doctor.sh --strict
# :JSON output
bash .assets/lib/nx_doctor.sh --json
'
set -eo pipefail

ENV_DIR="${ENV_DIR:-$HOME/.config/nix-env}"
DEV_ENV_DIR="${DEV_ENV_DIR:-$HOME/.config/dev-env}"

_dr_pass=0 _dr_fail=0 _dr_warn=0
_dr_json="false"
_dr_strict="false"
_dr_checks=""

while [ $# -gt 0 ]; do
  case "$1" in
  --json) _dr_json="true" ;;
  --strict) _dr_strict="true" ;;
  esac
  shift
done

_check() {
  local name="$1" status="$2" detail="${3:-}"
  if [ "$status" = "pass" ]; then
    _dr_pass=$((_dr_pass + 1))
    [ "$_dr_json" = "false" ] && printf '\e[32m  PASS  %s\e[0m\n' "$name"
  elif [ "$status" = "warn" ]; then
    _dr_warn=$((_dr_warn + 1))
    [ "$_dr_json" = "false" ] && printf '\e[33m  WARN  %s: %s\e[0m\n' "$name" "$detail"
  else
    _dr_fail=$((_dr_fail + 1))
    [ "$_dr_json" = "false" ] && printf '\e[31m  FAIL  %s: %s\e[0m\n' "$name" "$detail"
  fi
  if [ -n "$_dr_checks" ]; then
    _dr_checks="$_dr_checks,"
  fi
  local escaped_detail
  escaped_detail="$(printf '%s' "$detail" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  _dr_checks="${_dr_checks}{\"name\":\"$name\",\"status\":\"$status\",\"detail\":\"$escaped_detail\"}"
}

# -- 1. nix_available --------------------------------------------------------
if command -v nix >/dev/null 2>&1; then
  _check "nix_available" "pass"
else
  _check "nix_available" "fail" "nix not found in PATH"
fi

# -- 2. flake_lock ------------------------------------------------------------
if [ -f "$ENV_DIR/flake.lock" ]; then
  if command -v jq >/dev/null 2>&1; then
    _nixpkgs_rev="$(jq -r '.nodes.nixpkgs.locked.rev // empty' "$ENV_DIR/flake.lock" 2>/dev/null)" || true
    if [ -n "$_nixpkgs_rev" ]; then
      _check "flake_lock" "pass"
    else
      _check "flake_lock" "warn" "flake.lock exists but nixpkgs node not found"
    fi
  else
    _check "flake_lock" "warn" "flake.lock exists but jq not available to validate"
  fi
else
  _check "flake_lock" "fail" "$ENV_DIR/flake.lock not found"
fi

# -- 3. install_record -------------------------------------------------------
if [ -f "$DEV_ENV_DIR/install.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    _ir_status="$(jq -r '.status // empty' "$DEV_ENV_DIR/install.json" 2>/dev/null)" || true
    if [ -n "$_ir_status" ]; then
      if [ "$_ir_status" = "success" ]; then
        _check "install_record" "pass"
      else
        _ir_phase="$(jq -r '.phase // "unknown"' "$DEV_ENV_DIR/install.json" 2>/dev/null)" || true
        _check "install_record" "warn" "last run status: $_ir_status (phase: $_ir_phase)"
      fi
    else
      _check "install_record" "warn" "install.json exists but missing status field"
    fi
  else
    _check "install_record" "pass"
  fi
else
  _check "install_record" "warn" "$DEV_ENV_DIR/install.json not found"
fi

# -- 4. scope_binaries -------------------------------------------------------
# Parse "# bins:" comments from scope .nix files (single source of truth).
_scopes_dir=""
for _sd_path in \
  "$ENV_DIR/scopes" \
  "$(cd "$(dirname "$0")/../../nix/scopes" 2>/dev/null && pwd)"; do
  if [ -d "$_sd_path" ]; then
    _scopes_dir="$_sd_path"
    break
  fi
done

if [ -n "$_scopes_dir" ] && [ -f "$DEV_ENV_DIR/install.json" ] && command -v jq >/dev/null 2>&1; then
  _installed_scopes="$(jq -r '.scopes[]? // empty' "$DEV_ENV_DIR/install.json" 2>/dev/null)" || true
  _missing_bins=""
  for _scope in $_installed_scopes; do
    _nix_file="$_scopes_dir/$_scope.nix"
    [ -f "$_nix_file" ] || continue
    _bins="$(sed -n 's/^# bins: *//p' "$_nix_file")" || true
    for _bin in $_bins; do
      if ! command -v "$_bin" >/dev/null 2>&1; then
        _missing_bins="${_missing_bins:+$_missing_bins, }$_scope/$_bin"
      fi
    done
  done
  if [ -z "$_missing_bins" ]; then
    _check "scope_binaries" "pass"
  else
    _check "scope_binaries" "warn" "missing: $_missing_bins"
  fi
else
  _check "scope_binaries" "warn" "cannot verify (scope files or install.json not found)"
fi

# -- 5. shell_profile --------------------------------------------------------
_profile_ok=true
_profile_detail=""
_block_marker="nix-env managed"
for _rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$_rc" ] || continue
  _count="$(grep -cF "# >>> $_block_marker >>>" "$_rc" 2>/dev/null || true)"
  _rc_name="$(basename "$_rc")"
  if [ "$_count" = "0" ] 2>/dev/null; then
    _profile_detail="${_profile_detail:+$_profile_detail; }no managed block in $_rc_name"
    _profile_ok=false
  elif [ "$_count" -gt 1 ] 2>/dev/null; then
    _profile_detail="${_profile_detail:+$_profile_detail; }$_count duplicate blocks in $_rc_name"
    _profile_ok=false
  fi
done
if [ "$_profile_ok" = true ]; then
  _check "shell_profile" "pass"
else
  _check "shell_profile" "fail" "$_profile_detail"
fi

# -- 6. cert_bundle -----------------------------------------------------------
_cert_dir="$HOME/.config/certs"
if [ -f "$_cert_dir/ca-custom.crt" ]; then
  _cert_ok=true
  _cert_detail=""
  if [ ! -e "$_cert_dir/ca-bundle.crt" ]; then
    _cert_detail="ca-bundle.crt missing"
    _cert_ok=false
  fi
  if [ ! -f "$HOME/.vscode-server/server-env-setup" ] || \
     ! grep -q 'NODE_EXTRA_CA_CERTS' "$HOME/.vscode-server/server-env-setup" 2>/dev/null; then
    _cert_detail="${_cert_detail:+$_cert_detail; }NODE_EXTRA_CA_CERTS not in server-env-setup"
    _cert_ok=false
  fi
  if [ "$_cert_ok" = true ]; then
    _check "cert_bundle" "pass"
  else
    _check "cert_bundle" "fail" "$_cert_detail"
  fi
else
  _check "cert_bundle" "pass"
fi

# -- 7. nix_profile -----------------------------------------------------------
if command -v nix >/dev/null 2>&1; then
  if nix profile list --json 2>/dev/null | grep -q 'nix-env'; then
    _check "nix_profile" "pass"
  elif nix profile list 2>/dev/null | grep -q 'nix-env'; then
    _check "nix_profile" "pass"
  else
    _check "nix_profile" "fail" "nix-env not found in nix profile list"
  fi
else
  _check "nix_profile" "fail" "nix not available"
fi

# -- 8. overlay_dir -----------------------------------------------------------
if [ -n "${NIX_ENV_OVERLAY_DIR:-}" ]; then
  if [ -d "$NIX_ENV_OVERLAY_DIR" ] && [ -r "$NIX_ENV_OVERLAY_DIR" ]; then
    _check "overlay_dir" "pass"
  else
    _check "overlay_dir" "fail" "NIX_ENV_OVERLAY_DIR=$NIX_ENV_OVERLAY_DIR is not a readable directory"
  fi
fi

# -- Summary ------------------------------------------------------------------
if [ "$_dr_json" = "true" ]; then
  _overall="ok"
  [ "$_dr_warn" -gt 0 ] && _overall="degraded"
  [ "$_dr_fail" -gt 0 ] && _overall="broken"
  if command -v jq >/dev/null 2>&1; then
    printf '{"status":"%s","pass":%d,"warn":%d,"fail":%d,"checks":[%s]}' \
      "$_overall" "$_dr_pass" "$_dr_warn" "$_dr_fail" "$_dr_checks" | jq .
  else
    printf '{"status":"%s","pass":%d,"warn":%d,"fail":%d,"checks":[%s]}\n' \
      "$_overall" "$_dr_pass" "$_dr_warn" "$_dr_fail" "$_dr_checks"
  fi
else
  printf '\n'
  if [ "$_dr_fail" -gt 0 ]; then
    printf '\e[31m  %d passed, %d warnings, %d failed\e[0m\n' "$_dr_pass" "$_dr_warn" "$_dr_fail"
  elif [ "$_dr_warn" -gt 0 ]; then
    printf '\e[33m  %d passed, %d warnings\e[0m\n' "$_dr_pass" "$_dr_warn"
  else
    printf '\e[32m  all %d checks passed\e[0m\n' "$_dr_pass"
  fi
fi

if [ "$_dr_strict" = "true" ]; then
  [ $((_dr_fail + _dr_warn)) -eq 0 ] || exit 1
else
  [ "$_dr_fail" -eq 0 ] || exit 1
fi
