#!/usr/bin/env bash
: '
# set user-scope npm cafile
.assets/fix/fix_nodejs_certs.sh
# set system-wide npm cafile (requires root)
sudo .assets/fix/fix_nodejs_certs.sh
'
set -euo pipefail

if [ $EUID -eq 0 ]; then
  # *root: set global cafile to the system CA bundle
  SYS_ID="$(sed -En '/^ID.*(alpine|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
  case $SYS_ID in
  arch | alpine | fedora | opensuse)
    exit 0
    ;;
  debian | ubuntu)
    CERT_PATH='/etc/ssl/certs/ca-certificates.crt'
    ;;
  *)
    printf '\e[1;33mWarning: Unsupported system id (%s).\e[0m\n' "$SYS_ID" >&2
    exit 0
    ;;
  esac
  if ! (npm config get | grep -q 'cafile'); then
    npm config set -g cafile "$CERT_PATH"
  fi
else
  # *non-root: set user-scope cafile to the full trust store bundle
  CERT_BUNDLE="$HOME/.config/certs/ca-bundle.crt"
  if [ -f "$CERT_BUNDLE" ] && ! (npm config get | grep -q 'cafile'); then
    npm config set cafile "$CERT_BUNDLE"
  fi
fi
