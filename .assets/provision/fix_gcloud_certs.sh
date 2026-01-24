#!/usr/bin/env bash
: '
sudo .assets/provision/fix_gcloud_certs.sh
'
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

SYS_ID="$(sed -En '/^ID.*(alpine|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

case "$SYS_ID" in
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
esac

cert_files=($(find "$CERT_PATH" -maxdepth 1 -name '*.crt' 2>/dev/null || true))
if [ "${#cert_files[@]}" -eq 0 ]; then
  printf '\nNo custom certificates found in %s\n' "$CERT_PATH" >&2
  exit 0
fi

# locate gcloud's certifi bundle
certifi_locations=(
  "/usr/local/google-cloud-sdk/lib/third_party/certifi/cacert.pem"
  "/usr/lib/google-cloud-sdk/lib/third_party/certifi/cacert.pem"
  "/usr/lib64/google-cloud-sdk/lib/third_party/certifi/cacert.pem"
)

GCLOUD_CERTIFI=""
for loc in "${certifi_locations[@]}"; do
  if [ -f "$loc" ]; then
    GCLOUD_CERTIFI="$loc"
    break
  fi
done

if [ -z "$GCLOUD_CERTIFI" ]; then
  printf '\e[33mGoogle Cloud SDK certifi bundle not found\e[0m\n' >&2
  exit 0
fi

# instantiate variable about number of certificates added
cert_count=0
# track unique serials that have been added across all certify files
declare -A added_serials=()
# iterate over certify files
for cert_path in "${cert_files[@]}"; do
  serial=$(openssl x509 -in "$cert_path" -noout -serial -nameopt RFC2253 | cut -d= -f2)
  if ! grep -qw "$serial" "$GCLOUD_CERTIFI"; then
    openssl x509 -in "$cert_path" -noout -subject -nameopt RFC2253 | sed 's/\\//g' >&2
    cert_content="
$(openssl x509 -in "$cert_path" -noout -issuer -subject -serial -fingerprint -nameopt RFC2253 | sed 's/\\//g' | sed 's/^/# /')
$(openssl x509 -in "$cert_path" -outform PEM)"

    if [ -w "$GCLOUD_CERTIFI" ]; then
      echo "$cert_content" >>"$GCLOUD_CERTIFI"
    else
      printf '\e[33mInsufficient permissions to write to %s\e[0m\n' "$GCLOUD_CERTIFI" >&2
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
  printf "\e[34madded $cert_count certificate(s) to gcloud-cli certifi bundle\e[0m\n" >&2
else
  printf '\e[34mno new certificates to add to gcloud-cli certifi bundle\e[0m\n' >&2
fi
