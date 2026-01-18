: '
. .assets/config/bash_cfg/functions.sh
'

function fixcertpy {
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

  # print notification about cacert.pem file(s) update
  if [ ${#certify_paths[@]} -gt 0 ]; then
    printf '\e[36madding custom certificates to the following files:\e[0m\n' >&2
  else
    printf '\e[33mno certify/cacert.pem files found to be updated\e[0m\n' >&2
    return 0
  fi
  # instantiate variable about number of certificates added
  cert_count=0
  # track unique serials that have been added across all certify files
  declare -A added_serials=()
  # iterate over certify files
  for certify in "${certify_paths[@]}"; do
    echo "${certify//$HOME/\~}" >&2
    # iterate over installed certificates
    for path in "${cert_paths[@]}"; do
      serial=$(openssl x509 -in "$path" -noout -serial -nameopt RFC2253 2>/dev/null | cut -d= -f2)
      # skip if openssl didn't produce a serial
      [ -n "$serial" ] || continue
      if ! grep -qw "$serial" "$certify"; then
        # add certificate to array (print subject)
        echo " - $(openssl x509 -in "$path" -noout -subject -nameopt RFC2253 | sed 's/\\//g')" >&2
        CERT="
$(openssl x509 -in "$path" -noout -issuer -subject -serial -fingerprint -nameopt RFC2253 | sed 's/\\//g' | xargs -I {} echo "# {}")
$(openssl x509 -in "$path" -outform PEM)"
        # append new certificates to certify cacert.pem
        if [ -w "$certify" ]; then
          echo "$CERT" >>"$certify"
        else
          echo "$CERT" | sudo tee -a "$certify" >/dev/null
        fi
        # increment unique certificate count only once per serial
        if [ -z "${added_serials[$serial]+x}" ]; then
          added_serials[$serial]=1
          cert_count=$((cert_count + 1))
        fi
      fi
    done
  done
  if [ $cert_count -gt 0 ]; then
    printf "\e[34madded $cert_count certificate(s) to certifi/cacert.pem file(s)\e[0m\n" >&2
  else
    printf '\e[34mno new certificates to add\e[0m\n' >&2
  fi
}

# alias for backward compatibility
alias fxcertpy='fixcertpy'
