: '
. .assets/config/bash_cfg/functions.sh
'
# *Function to display system information in a user-friendly format
function sysinfo {
  # dot-source os-release file
  . /etc/os-release
  # get cpu info
  cpu_name="$(sed -En '/^model name\s*: (.+)/{s//\1/;p;q}' /proc/cpuinfo)"
  cpu_cores="$(sed -En '/^cpu cores\s*: ([0-9]+)/{s//\1/;p;q}' /proc/cpuinfo)"
  # calculate memory usage
  mem_inf=($(awk -F ':|kB' '/MemTotal:|MemAvailable:/ {printf $2, " "}' /proc/meminfo))
  mem_total=${mem_inf[0]}
  mem_used=$((mem_total - mem_inf[1]))
  mem_perc=$(awk '{printf "%.0f", $1 * $2 / $3}' <<<"$mem_used 100 $mem_total")
  mem_used=$(awk '{printf "%.2f", $1 / $2 / $3}' <<<"$mem_used 1024 1024")
  mem_total=$(awk '{printf "%.2f", $1 / $2 / $3}' <<<"$mem_total 1024 1024")

  # build system properties string
  SYS_PROP="\n\e[1;32mOS         :\e[1;37m $NAME $([ -n "$BUILD_ID" ] && printf "$BUILD_ID" || [ -n "$VERSION" ] && printf "$VERSION" || printf "$VERSION_ID") $(uname -m)\e[0m"
  SYS_PROP+="\n\e[1;32mKernel     :\e[0m $(uname -r)"
  SYS_PROP+="\n\e[1;32mUptime     :\e[0m $(uptime -p | sed 's/^up //')"
  [ -n "$WSL_DISTRO_NAME" ] && SYS_PROP+="\n\e[1;32mOS Host    :\e[0m Windows Subsystem for Linux" || true
  [ -n "$WSL_DISTRO_NAME" ] && SYS_PROP+="\n\e[1;32mWSL Distro :\e[0m $WSL_DISTRO_NAME" || true
  [ -n "$CONTAINER_ID" ] && SYS_PROP+="\n\e[1;32mDistroBox  :\e[0m $CONTAINER_ID" || true
  [ -n "$TERM_PROGRAM" ] && SYS_PROP+="\n\e[1;32mTerminal   :\e[0m $TERM_PROGRAM" || true
  type bash &>/dev/null && SYS_PROP+="\n\e[1;32mShell      :\e[0m $(bash --version | head -n1 | sed 's/ (.*//')" || true
  SYS_PROP+="\n\e[1;32mCPU        :\e[0m $cpu_name ($cpu_cores)"
  SYS_PROP+="\n\e[1;32mMemory     :\e[0m ${mem_used} GiB / ${mem_total} GiB (${mem_perc} %%)"
  [ -n "$LANG" ] && SYS_PROP+="\n\e[1;32mLocale     :\e[0m $LANG" || true

  # print user@host header
  printf "\e[1;34m$(id -un)\e[0m@\e[1;34m$([ -n "$HOSTNAME" ] && printf "$HOSTNAME" || printf "$NAME")\e[0m\n"
  USER_HOST="$(id -un)@$([ -n "HOSTNAME" ] && printf "$HOSTNAME" || printf "$NAME")"
  printf '%0.s-' $(seq 1 ${#USER_HOST})
  # print system properties
  printf "$SYS_PROP\n"
}
# set alias
alias sysinfo='gsi'

# *Function for fixing Python SSL certificate issues by adding custom certificates to certifi's cacert.pem
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
