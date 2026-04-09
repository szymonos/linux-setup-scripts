#!/usr/bin/env bash
: '
.assets/fix/fix_gcloud_certs.sh
Discovers gcloud SDK certifi cacert.pem and patches it with custom certificates.
'
set -euo pipefail

# resolve repo root dir
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$SCRIPT_ROOT/.assets/config/bash_cfg/functions.sh"

# *discover gcloud certifi cacert.pem
GCLOUD_CERTIFI=""
for loc in \
  "/usr/local/google-cloud-sdk/lib/third_party/certifi/cacert.pem" \
  "/usr/lib/google-cloud-sdk/lib/third_party/certifi/cacert.pem" \
  "/usr/lib64/google-cloud-sdk/lib/third_party/certifi/cacert.pem"; do
  if [ -f "$loc" ]; then
    GCLOUD_CERTIFI="$loc"
    break
  fi
done

if [ -z "$GCLOUD_CERTIFI" ]; then
  printf '\e[33mgcloud certifi/cacert.pem not found\e[0m\n' >&2
  exit 0
fi

fixcertpy "$GCLOUD_CERTIFI"
