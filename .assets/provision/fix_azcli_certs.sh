#!/usr/bin/env bash
: '
.assets/provision/fix_azcli_certs.sh
'
if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(fedora|debian|ubuntu|opensuse)' /etc/os-release)

# specify path for installed custom certificates
case $SYS_ID in
fedora | opensuse)
  [ "$SYS_ID" = 'fedora' ] && CERT_PATH='/etc/pki/ca-trust/source/anchors' || CERT_PATH='/usr/share/pki/trust/anchors'
  CERTIFY_CRT=$(rpm -ql azure-cli 2>/dev/null | grep 'site-packages/certifi/cacert.pem') || true
  ;;
debian | ubuntu)
  CERT_PATH='/usr/local/share/ca-certificates'
  CERTIFY_CRT=$(dpkg-query -L azure-cli 2>/dev/null | grep 'site-packages/certifi/cacert.pem') || true
  ;;
esac

# get list of installed certificates
cert_paths=($(ls $CERT_PATH/*.crt 2>/dev/null))
if [ -z "$cert_paths" ]; then
  printf '\e[33mno self-signed certificates installed\e[0m\n' >&2
  exit 0
fi

# determine certifi path to add certificate
if [ -z "$CERTIFY_CRT" ]; then
  CERTIFY_CRT="$(pip show azure-cli 2>/dev/null | grep -oP '^Location: \K.+')/certifi/cacert.pem"
  if [ ! -f "$CERTIFY_CRT" ]; then
    printf '\e[33mcertifi/cacert.pem not found\e[0m\n' >&2
    exit 0
  fi
fi

for path in ${cert_paths[@]}; do
  serial=$(openssl x509 -in "$path" -noout -serial -nameopt RFC2253 | cut -d= -f2)
  if ! grep -qw "$serial" "$CERTIFY_CRT"; then
    echo "$(openssl x509 -in $path -noout -subject -nameopt RFC2253)"
    CERT="
$(openssl x509 -in $path -noout -issuer -subject -serial -fingerprint -nameopt RFC2253 | xargs -I {} echo "# {}")
$(cat $path)"
    if [ -w "$CERTIFY_CRT" ]; then
      echo "$CERT" >>"$CERTIFY_CRT"
    else
      echo "$CERT" | sudo tee -a "$CERTIFY_CRT" >/dev/null
    fi
  fi
done
