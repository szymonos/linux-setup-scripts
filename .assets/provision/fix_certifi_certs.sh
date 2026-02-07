#!/usr/bin/env bash
: '
.assets/provision/fix_certifi_certs.sh
'
if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

# specify path for installed custom certificates
case $SYS_ID in
alpine)
  exit 0
  ;;
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

cert_paths=($(ls "$CERT_PATH"/*.crt 2>/dev/null || true))
if [ ${#cert_paths[@]} -eq 0 ]; then
  exit 0
fi

certify_paths=()
# determine certifi cacert.pem path
SHOW=$(pip show -f certifi 2>/dev/null)
if [ -n "$SHOW" ]; then
  location=$(echo "$SHOW" | grep -oP '^Location: \K.+')
  if [ -n "$location" ]; then
    cacert=$(echo "$SHOW" | grep -oE '\S+cacert\.pem$')
    if [ -n "$cacert" ]; then
      certify_paths+=("${location}/${cacert}")
    fi
  fi
fi
# determine pip cacert.pem path
SHOW=$(pip show -f pip 2>/dev/null)
if [ -n "$SHOW" ]; then
  location=$(echo "$SHOW" | grep -oP '^Location: \K.+')
  if [ -n "$location" ]; then
    cacert=$(echo "$SHOW" | grep -oE '\S+cacert\.pem$')
    if [ -n "$cacert" ]; then
      certify_paths+=("${location}/${cacert}")
    fi
  fi
fi

# exit script if no certify cacert.pem found
if [ -z "$certify_paths" ]; then
  printf '\e[33mcertifi/cacert.pem not found\e[0m\n' >&2
  exit 0
fi

# iterate over certify files
for certify in "${certify_paths[@]}"; do
  echo "${certify//$HOME/\~}" >&2
  # iterate over installed certificates
  for path in "${cert_paths[@]}"; do
    serial=$(openssl x509 -in "$path" -noout -serial -nameopt RFC2253 | cut -d= -f2)
    if ! grep -qw "$serial" "$certify"; then
      # add certificate to array
      subj=$(openssl x509 -in "$path" -noout -subject -nameopt RFC2253 | sed 's/\\//g')
      echo " - $subj" >&2
      info=$(openssl x509 -in "$path" -noout -issuer -subject -serial -fingerprint -nameopt RFC2253 | sed 's/\\//g' | xargs -I {} printf '# %s\n' "{}")
      pem=$(openssl x509 -in "$path" -outform PEM)
      CERT="$info\n$pem"
      # append new certificates to certify cacert.pem
      if [ -w "$certify" ]; then
        printf '%s\n' "$CERT" >>"$certify"
      else
        printf '%s\n' "$CERT" | sudo tee -a "$certify" >/dev/null
      fi
    fi
  done
done
