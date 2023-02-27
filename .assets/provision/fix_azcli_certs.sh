#!/usr/bin/env bash
: '
.assets/provision/fix_azcli_certs.sh
'
if [[ $EUID -eq 0 ]]; then
  echo -e '\e[91mDo not run the script as root!\e[0m\n'
  exit 1
fi
# cache root credentials
sudo true

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(fedora|debian|ubuntu|opensuse)' /etc/os-release)

# specify path for installed custom certificates
case $SYS_ID in
fedora | opensuse)
  [[ "$SYS_ID" = 'fedora' ]] && CERT_PATH='/etc/pki/ca-trust/source/anchors' || CERT_PATH='/usr/share/pki/trust/anchors'
  CERTIFY_CRT=$(rpm -ql azure-cli 2>/dev/null | grep 'site-packages/certifi/cacert.pem') || true
  ;;
debian | ubuntu)
  CERT_PATH='/usr/local/share/ca-certificates'
  CERTIFY_CRT=$(dpkg-query -L azure-cli 2>/dev/null | grep 'site-packages/certifi/cacert.pem') || true
  ;;
esac

# determine certifi path to add certificate
if [ -z "$CERTIFY_CRT" ]; then
  CERTIFY_CRT="$(pip show azure-cli 2>/dev/null | grep -oP '^Location: \K.+')/certifi/cacert.pem"
  [[ -f "$CERTIFY_CRT" ]] || (echo -e '\e[91mcertifi/cacert.pem not found!\e[0m' >&2 && exit 0)
fi

# get list of installed certificates
cert_paths=($(ls $CERT_PATH/*.crt 2>/dev/null))

for path in ${cert_paths[@]}; do
  serial=$(openssl x509 -in "$path" -noout -serial -nameopt RFC2253 | cut -d= -f2)
  if ! grep -qw "$serial" "$CERTIFY_CRT"; then
    echo "$(openssl x509 -in $path -noout -subject -nameopt RFC2253)"
    cat <<EOF | sudo tee -a "$CERTIFY_CRT" >/dev/null

$(openssl x509 -in $path -noout -issuer -subject -serial -fingerprint -nameopt RFC2253 | xargs -I {} echo "# {}")
$(cat $path)
EOF
  fi
done
