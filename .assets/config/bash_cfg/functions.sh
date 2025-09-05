: '
. .assets/config/bash_cfg/functions.sh
'

function fxcertpy {
  # check if pip and openssl are available
  type pip &>/dev/null && true || return 1
  type openssl &>/dev/null && true || return 1

  # determine system id
  SYS_ID="$(sed -En '/^ID.*(fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

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
  *)
    return 0
    ;;
  esac

  # get list of installed certificates
  cert_paths=($(ls $CERT_PATH/*.crt 2>/dev/null))
  if [ -z "$cert_paths" ]; then
    return 0
  fi

  certify_paths=()
  # determine venv certifi cacert.pem path
  if . .venv/bin/activate 2>/dev/null; then
    [ -x $HOME/.local/bin/uv ] && SHOW=$(uv pip show -f certifi 2>/dev/null) || true
    [ -n "$SHOW" ] && true || SHOW=$(pip show -f certifi 2>/dev/null)
    if [ -n "$SHOW" ]; then
      location=$(echo "$SHOW" | grep -oP '^Location: \K.+')
      if [ -n "$location" ]; then
        cacert=$(echo "$SHOW" | grep -oE '\S+cacert\.pem$')
        if [ -n "$cacert" ]; then
          certify_paths+=("${location}/${cacert}")
        fi
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
    return 0
  fi

  # iterate over certify files
  for certify in ${certify_paths[@]}; do
    echo "${certify//$HOME/\~}" >&2
    # iterate over installed certificates
    for path in ${cert_paths[@]}; do
      serial=$(openssl x509 -in "$path" -noout -serial -nameopt RFC2253 | cut -d= -f2)
      if ! grep -qw "$serial" "$certify"; then
        # add certificate to array
        echo " - $(openssl x509 -in $path -noout -subject -nameopt RFC2253 | sed 's/\\//g')" >&2
        CERT="
$(openssl x509 -in $path -noout -issuer -subject -serial -fingerprint -nameopt RFC2253 | sed 's/\\//g' | xargs -I {} echo "# {}")
$(openssl x509 -in $path -outform PEM)"
        # append new certificates to certify cacert.pem
        if [ -w "$certify" ]; then
          echo "$CERT" >>"$certify"
        else
          echo "$CERT" | sudo tee -a "$certify" >/dev/null
        fi
      fi
    done
  done
}
