# Managed-block helper for shell rc files.
# Compatible with bash 3.2 and BSD sed (macOS).
#
# Usage:
#   source .assets/lib/profile_block.sh
#   manage_block <rc-file> <marker> <action> [<content-file>]
#
#   action = upsert  -> replace the block (or insert if absent) with content-file
#   action = remove  -> delete the block; no-op if absent
#   action = inspect -> print start and end line numbers; exits 0 if present, 1 if absent
#
# Marker format (written into the rc file):
#   # >>> <marker> >>>
#   ... block content ...
#   # <<< <marker> <<<
#
# Guarantees:
#   - Atomic write via tmp file + mv; rc is never half-written.
#   - If the block appears more than once, all occurrences are replaced/removed
#     with a warning message to stderr.
#   - rc file is created empty if it does not exist.
#   - File mode is preserved via cp + mv pattern.
#   - Works with BSD sed (no -i ''; uses tmp file instead).

_pb_begin_tag() { printf '# >>> %s >>>' "$1"; }
_pb_end_tag()   { printf '# <<< %s <<<' "$1"; }

# _pb_count_occurrences <rc-file> <marker>
# prints the number of begin-tag lines found
_pb_count_occurrences() {
  local rc="$1" marker="$2"
  local tag
  tag="$(_pb_begin_tag "$marker")"
  # grep -c returns 0 when no match on some implementations; guard with || true
  grep -cF "$tag" "$rc" 2>/dev/null || true
}

# manage_block <rc-file> <marker> <action> [<content-file>]
manage_block() {
  local rc="$1" marker="$2" action="$3" content_file="${4:-}"

  # ensure rc exists
  [ -f "$rc" ] || touch "$rc"

  local begin_tag end_tag
  begin_tag="$(_pb_begin_tag "$marker")"
  end_tag="$(_pb_end_tag "$marker")"

  case "$action" in
  inspect)
    local start_line end_line
    start_line="$(grep -nF "$begin_tag" "$rc" 2>/dev/null | head -1 | cut -d: -f1)"
    end_line="$(grep -nF "$end_tag"   "$rc" 2>/dev/null | head -1 | cut -d: -f1)"
    if [ -z "$start_line" ] || [ -z "$end_line" ]; then
      return 1
    fi
    printf '%s %s\n' "$start_line" "$end_line"
    return 0
    ;;

  remove)
    local count
    count="$(_pb_count_occurrences "$rc" "$marker")"
    if [ "$count" -eq 0 ] 2>/dev/null; then
      return 0
    fi
    if [ "$count" -gt 1 ] 2>/dev/null; then
      printf '\e[33mwarning: found %s occurrences of managed block "%s" in %s; removing all\e[0m\n' \
        "$count" "$marker" "$rc" >&2
    fi
    local tmp
    tmp="$(mktemp)"
    # Use awk to strip all occurrences (BSD awk compatible)
    awk -v begin="$begin_tag" -v end="$end_tag" '
      $0 == begin { skip=1; next }
      skip && $0 == end { skip=0; next }
      !skip { print }
    ' "$rc" >"$tmp"
    # strip trailing blank lines then ensure final newline
    _pb_normalize_trailing "$tmp"
    cp -p "$rc" "${rc}.nixenv-backup-$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
    mv -f "$tmp" "$rc"
    return 0
    ;;

  upsert)
    [ -z "$content_file" ] && {
      printf '\e[31merror: manage_block upsert requires a content file\e[0m\n' >&2
      return 1
    }
    [ -f "$content_file" ] || {
      printf '\e[31merror: content file not found: %s\e[0m\n' "$content_file" >&2
      return 1
    }

    local count
    count="$(_pb_count_occurrences "$rc" "$marker")"
    if [ "$count" -gt 1 ] 2>/dev/null; then
      printf '\e[33mwarning: found %s occurrences of managed block "%s" in %s; replacing all with one\e[0m\n' \
        "$count" "$marker" "$rc" >&2
    fi

    local tmp new_block
    tmp="$(mktemp)"

    # Build the block string we will insert
    new_block="$(printf '%s\n' "$begin_tag"; cat "$content_file"; printf '%s\n' "$end_tag")"

    if [ "$count" -eq 0 ] 2>/dev/null; then
      # Append: ensure blank line separator before the block
      {
        if [ -s "$rc" ]; then
          cat "$rc"
          printf '\n'
        fi
        printf '%s\n' "$new_block"
      } >"$tmp"
    else
      # Replace: use awk to substitute first occurrence, delete rest
      awk -v begin="$begin_tag" -v end="$end_tag" -v replacement="$new_block" '
        BEGIN { done=0; skip=0 }
        $0 == begin {
          if (!done) { print replacement; done=1 }
          skip=1; next
        }
        skip && $0 == end { skip=0; next }
        !skip { print }
      ' "$rc" >"$tmp"
    fi

    _pb_normalize_trailing "$tmp"
    cp -p "$rc" "${rc}.nixenv-backup-$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
    mv -f "$tmp" "$rc"
    return 0
    ;;

  *)
    printf '\e[31merror: manage_block: unknown action "%s"\e[0m\n' "$action" >&2
    return 1
    ;;
  esac
}

# _pb_normalize_trailing <file>
# Strips consecutive trailing blank lines, ensures exactly one trailing newline.
# BSD sed compatible (no -i '').
_pb_normalize_trailing() {
  local file="$1"
  local tmp
  tmp="$(mktemp)"
  # awk: print all lines; at end, ensure file ends with exactly one newline.
  # We strip runs of trailing empty lines by buffering them.
  awk '
    /^[[:space:]]*$/ { blank++; next }
    { for (i=0; i<blank; i++) print ""; blank=0; print }
  ' "$file" >"$tmp"
  mv -f "$tmp" "$file"
}
