#!/usr/bin/env bash
: '
./fix_certifi_certs.sh
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
fedora)
  CERT_PATH='/etc/pki/ca-trust/source/anchors'
  ;;
debian | ubuntu)
  CERT_PATH='/usr/local/share/ca-certificates'
  ;;
opensuse)
  CERT_PATH='/usr/share/pki/trust/anchors'
  ;;
esac

certify_paths=()
# determine certifi cacert.pem path
SHOW=$(pip show -f certifi 2>/dev/null)
if [[ -n $SHOW ]]; then
  location=$(echo "$SHOW" | grep -oP '^Location: \K.+')
  if [[ -n $location ]]; then
    cacert=$(echo "$SHOW" | grep -oE '\S+cacert\.pem$')
    if [[ -n $cacert ]]; then
      certify_paths+=("${location}/${cacert}")
    fi
  fi
fi
# determine pip cacert.pem path
SHOW=$(pip show -f pip 2>/dev/null)
if [[ -n $SHOW ]]; then
  location=$(echo "$SHOW" | grep -oP '^Location: \K.+')
  if [[ -n $location ]]; then
    cacert=$(echo "$SHOW" | grep -oE '\S+cacert\.pem$')
    if [[ -n $cacert ]]; then
      certify_paths+=("${location}/${cacert}")
    fi
  fi
fi

# exit script if no certify cacert.pem found
[[ -n $certify_paths ]] || (echo -e '\e[91mcertifi/cacert.pem not found!\e[0m' >&2 && exit 0)

# get list of installed certificates
cert_paths=($(ls $CERT_PATH/*.crt 2>/dev/null))

for path in ${cert_paths[@]}; do
  serial=$(openssl x509 -in "$path" -noout -serial -nameopt RFC2253 | cut -d= -f2)
  for certify in ${certify_paths[@]}; do
    if ! grep -qw "$serial" "$certify"; then
      echo "$(openssl x509 -in $path -noout -subject -nameopt RFC2253)"
      cat <<EOF | sudo tee -a "$certify" >/dev/null

$(openssl x509 -in $path -noout -issuer -subject -serial -fingerprint -nameopt RFC2253 | xargs -I {} echo "# {}")
$(cat $path)
EOF
    fi
  done
done
