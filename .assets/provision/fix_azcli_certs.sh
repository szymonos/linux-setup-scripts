#!/usr/bin/env bash
: '
.assets/provision/fix_azcli_certs.sh
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
fedora | opensuse)
  [ "$SYS_ID" = 'fedora' ] && CERT_PATH='/etc/pki/ca-trust/source/anchors' || CERT_PATH='/usr/share/pki/trust/anchors'
  CERTIFY_CRT=$(rpm -ql azure-cli 2>/dev/null | grep 'site-packages/certifi/cacert.pem') || true
  ;;
debian | ubuntu)
  CERT_PATH='/usr/local/share/ca-certificates'
  CERTIFY_CRT=$(dpkg-query -L azure-cli 2>/dev/null | grep 'site-packages/certifi/cacert.pem') || true
  ;;
esac

# get list of installed certificates (use ls-based command substitution for readability)
# ls prints nothing to stdout when the glob doesn't match (stderr is redirected)
# so the resulting array will be empty -- this mirrors the original behaviour.
cert_paths=($(ls "$CERT_PATH"/*.crt 2>/dev/null || true))
if [ ${#cert_paths[@]} -eq 0 ]; then
  printf '\nThere are no certificate(s) to install.\n' >&2
  exit 0
fi

# determine certifi path to add certificate
if [ -z "$CERTIFY_CRT" ]; then
  # try to activate azure-cli venv
  AZ_VENV="$HOME/.azure/.venv/bin/activate"
  [ -f "$AZ_VENV" ] && source "$AZ_VENV" || true
  # calculate certifi path
  CERTIFY_CRT="$(pip show azure-cli 2>/dev/null | grep -oP '^Location: \K.+')/certifi/cacert.pem"
  if [ ! -f "$CERTIFY_CRT" ]; then
    printf '\e[33mcertifi/cacert.pem not found\e[0m\n' >&2
    exit 0
  fi
fi

# instantiate variable about number of certificates added
cert_count=0
# track unique serials that have been added across all certify files
declare -A added_serials=()
# iterate over certify files
for path in "${cert_paths[@]}"; do
  serial=$(openssl x509 -in "$path" -noout -serial -nameopt RFC2253 | cut -d= -f2)
  if ! grep -qw "$serial" "$CERTIFY_CRT"; then
    subject=$(openssl x509 -in "$path" -noout -subject -nameopt RFC2253 | sed 's/\\//g')
    printf '%s\n' "$subject" >&2

    info=$(openssl x509 -in "$path" -noout -issuer -subject -serial -fingerprint -nameopt RFC2253 | sed 's/\\//g' | xargs -I {} printf '# %s\n' "{}")
    pem=$(openssl x509 -in "$path" -outform PEM)
    CERT="$info\n$pem"

    if [ -w "$CERTIFY_CRT" ]; then
      printf '%s\n' "$CERT" >>"$CERTIFY_CRT"
    else
      printf '%s\n' "$CERT" | sudo tee -a "$CERTIFY_CRT" >/dev/null
    fi
    # increment unique certificate count only once per serial
    if [ -z "${added_serials[$serial]+x}" ]; then
      added_serials[$serial]=1
      cert_count=$((cert_count + 1))
    fi
  fi
done

# print summary of added certificates
if [ $cert_count -gt 0 ]; then
  printf "\e[34madded $cert_count certificate(s) to azure-cli certifi bundle\e[0m\n" >&2
else
  printf '\e[34mno new certificates to add to azure-cli certifi bundle\e[0m\n' >&2
fi
