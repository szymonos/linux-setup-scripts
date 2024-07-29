#!/usr/bin/env bash
: '
sudo .assets/provision/fix_nodejs_certs.sh
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

CERT_PATH='/etc/ssl/certs/ca-certificates.crt'
# specify path for installed custom certificates
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

# set the system wide cafile for nodejs
if ! (npm config get | grep -q 'cafile'); then
  npm config set -g cafile "$CERT_PATH"
fi
