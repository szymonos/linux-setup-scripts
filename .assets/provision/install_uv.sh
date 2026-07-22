#!/usr/bin/env bash
: '
.assets/provision/install_uv.sh >/dev/null
'
set -euo pipefail

if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='uv'
REL=${1:-}
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'astral-sh' --repo 'uv')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if [ -x "$HOME/.local/bin/uv" ]; then
  VER="$($HOME/.local/bin/uv self version | sed -En 's/.*\s([0-9\.]+)/\1/p')"
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  else
    # update uv using the self update command
    printf "\e[92mupdating \e[1m$APP\e[22m\n" >&2
    # build the env for self update: UV_SYSTEM_CERTS (uv 0.11.0+) supersedes the
    # deprecated UV_NATIVE_TLS. Only add UV_NATIVE_TLS for legacy uv (< 0.11.0),
    # which predates UV_SYSTEM_CERTS and still needs it for the TLS-verified update.
    # An empty/unparseable VER means uv's output format changed - i.e. a newer uv -
    # so treat it as new and skip the deprecated var to avoid the warning.
    uv_env=(UV_SYSTEM_CERTS=true)
    if [ -n "$VER" ] && [ "$VER" != '0.11.0' ] &&
      [ "$(printf '%s\n0.11.0\n' "$VER" | sort -V | head -n1)" = "$VER" ]; then
      uv_env+=(UV_NATIVE_TLS=true)
    fi
    # retry uv self update up to 5 times if it fails
    retry_count=0
    max_retries=5
    while [ $retry_count -le $max_retries ]; do
      env "${uv_env[@]}" "$HOME/.local/bin/uv" self update >&2
      [ $? -eq 0 ] && break || true
      ((retry_count++)) || true
      echo "retrying... $retry_count/$max_retries" >&2
      if [ $retry_count -eq $max_retries ]; then
        printf "\e[31mFailed to update $APP after $max_retries attempts.\e[0m\n" >&2
        exit 1
      fi
    done
  fi
fi

# check if the binary is already installed
printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -d -p "$HOME")
trap 'rm -fr "$TMP_DIR"' EXIT
# calculate download uri
URL="https://astral.sh/uv/install.sh"
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  retry_count=0
  while [ ! -x "$HOME/.local/bin/uv" ] && [ $retry_count -lt 10 ]; do
    sh "$TMP_DIR/install.sh"
    ((retry_count++)) || true
  done
fi
exit 0
