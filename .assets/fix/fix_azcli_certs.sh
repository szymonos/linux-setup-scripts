#!/usr/bin/env bash
: '
# patch azure-cli certifi bundle with custom CA certificates
.assets/fix/fix_azcli_certs.sh
'
set -euo pipefail

# resolve repo root dir
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$SCRIPT_ROOT/.assets/config/bash_cfg/functions.sh"

# *discover azure-cli certifi cacert.pem
AZCLI_CERTIFI=""
SYS_ID="$(sed -En '/^ID.*(fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release 2>/dev/null)" || true
case ${SYS_ID:-} in
fedora | opensuse)
  AZCLI_CERTIFI=$(rpm -ql azure-cli 2>/dev/null | grep 'site-packages/certifi/cacert.pem') || true
  ;;
debian | ubuntu)
  AZCLI_CERTIFI=$(dpkg-query -L azure-cli 2>/dev/null | grep 'site-packages/certifi/cacert.pem') || true
  ;;
esac
if [ -z "$AZCLI_CERTIFI" ]; then
  # try azure-cli venv
  AZ_VENV="$HOME/.azure/.venv/bin/activate"
  if [ -f "$AZ_VENV" ]; then
    source "$AZ_VENV" 2>/dev/null || true
    location=$(pip show certifi 2>/dev/null | grep -oP '^Location: \K.+') || true
    if [ -n "$location" ]; then
      AZCLI_CERTIFI="${location}/certifi/cacert.pem"
    fi
  fi
fi

if [ -z "$AZCLI_CERTIFI" ] || [ ! -f "$AZCLI_CERTIFI" ]; then
  printf '\e[33mazure-cli certifi/cacert.pem not found\e[0m\n' >&2
  exit 0
fi

fixcertpy "$AZCLI_CERTIFI"
