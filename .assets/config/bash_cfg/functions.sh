: '
. .assets/config/bash_cfg/functions.sh
'
# guard: skip when sourced by non-bash shells (e.g. dash via /etc/profile.d/)
[ -z "$BASH_VERSION" ] && return 0

# *Function to display system information in a user-friendly format
sysinfo() {
  # dot-source os-release file
  . /etc/os-release
  # get cpu info
  cpu_name="$(sed -En '/^model name[[:space:]]*: (.+)/{
    s//\1/;p;q
  }' /proc/cpuinfo)"
  cpu_cores="$(sed -En '/^cpu cores[[:space:]]*: ([0-9]+)/{
    s//\1/;p;q
  }' /proc/cpuinfo)"
  # calculate memory usage
  local mem_inf=()
  while IFS= read -r _l; do mem_inf+=("$_l"); done < <(awk -F ':|kB' '/MemTotal:|MemAvailable:/ {print $2}' /proc/meminfo)
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
  USER_HOST="$(id -un)@$([ -n "$HOSTNAME" ] && printf "$HOSTNAME" || printf "$NAME")"
  printf '%0.s-' $(seq 1 ${#USER_HOST})
  # print system properties
  printf "$SYS_PROP\n"
}
# set alias
alias gsi='sysinfo'

# *Function for fixing Python SSL certificate issues by adding custom certificates to certifi's cacert.pem
# Usage: fixcertpy [path ...]
#   If paths are provided, patches only those cacert.pem files.
#   If no paths are given, auto-discovers Python certifi bundles (venv, pip).
fixcertpy() {
  # openssl is always needed for serial/fingerprint extraction
  type openssl &>/dev/null || return 1

  # load custom certificates into in-memory PEM array
  local cert_pems=()
  local CERT_BUNDLE="$HOME/.config/certs/ca-custom.crt"
  if [ -f "$CERT_BUNDLE" ]; then
    # parse individual PEM certs from bundle into array
    local current_pem=""
    while IFS= read -r line; do
      if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
        current_pem="$line"
      elif [[ "$line" == "-----END CERTIFICATE-----" ]]; then
        current_pem+=$'\n'"$line"
        cert_pems+=("$current_pem")
        current_pem=""
      elif [[ -n "$current_pem" ]]; then
        current_pem+=$'\n'"$line"
      fi
    done < "$CERT_BUNDLE"
  else
    # fall back to distro-specific cert paths
    local SYS_ID
    SYS_ID="$(sed -En '/^ID.*(alpine|fedora|debian|ubuntu|opensuse).*/{
      s//\1/;p;q
    }' /etc/os-release 2>/dev/null)"
    local CERT_PATH
    case ${SYS_ID:-} in
    alpine)
      return 0
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
    *)
      return 0
      ;;
    esac
    # read each .crt file into the PEM array
    for f in "$CERT_PATH"/*.crt; do
      [ -f "$f" ] && cert_pems+=("$(cat "$f")") || true
    done
  fi

  if [ "${#cert_pems[@]}" -eq 0 ]; then
    printf '\033[36mno custom certificates found\033[0m\n' >&2
    return 0
  fi

  # discover certifi cacert.pem bundles
  local certifi_paths=()
  if [ $# -gt 0 ]; then
    # use explicitly provided paths
    for p in "$@"; do
      [ -f "$p" ] && certifi_paths+=("$p")
    done
  else
    # auto-discover Python certifi bundles
    type pip &>/dev/null || return 1
    local SHOW location cacert
    # check venv certifi
    if . .venv/bin/activate 2>/dev/null; then
      SHOW=""
      { [ -x "$HOME/.local/bin/uv" ] || [ -x "$HOME/.nix-profile/bin/uv" ]; } && SHOW=$(uv pip show -f certifi 2>/dev/null) || true
      [ -n "$SHOW" ] || SHOW=$(pip show -f certifi 2>/dev/null) || true
      if [ -n "$SHOW" ]; then
        location=$(echo "$SHOW" | sed -n 's/^Location: //p')
        if [ -n "$location" ]; then
          cacert=$(echo "$SHOW" | grep -oE '[^[:space:]]+cacert\.pem$')
          [ -n "$cacert" ] && certifi_paths+=("${location}/${cacert}")
        fi
      fi
    fi
    # check pip certifi
    SHOW=$(pip show -f certifi 2>/dev/null) || true
    if [ -n "$SHOW" ]; then
      location=$(echo "$SHOW" | sed -n 's/^Location: //p')
      if [ -n "$location" ]; then
        cacert=$(echo "$SHOW" | grep -oE '[^[:space:]]+cacert\.pem$')
        [ -n "$cacert" ] && certifi_paths+=("${location}/${cacert}")
      fi
    fi
    # check pip's own cacert.pem
    SHOW=$(pip show -f pip 2>/dev/null) || true
    if [ -n "$SHOW" ]; then
      location=$(echo "$SHOW" | sed -n 's/^Location: //p')
      if [ -n "$location" ]; then
        cacert=$(echo "$SHOW" | grep -oE '[^[:space:]]+cacert\.pem$')
        [ -n "$cacert" ] && certifi_paths+=("${location}/${cacert}")
      fi
    fi
  fi

  # exit if no target bundles found
  if [ ${#certifi_paths[@]} -eq 0 ]; then
    printf '\e[33mno certifi/cacert.pem bundles found\e[0m\n' >&2
    return 0
  fi

  # append custom certificates to each target bundle
  local cert_count=0
  local _added_serials=" "
  local certifi pem serial CERT
  for certifi in "${certifi_paths[@]}"; do
    echo "${certifi//$HOME/\~}" >&2
    for pem in "${cert_pems[@]}"; do
      serial=$(openssl x509 -noout -serial -nameopt RFC2253 <<< "$pem" 2>/dev/null | cut -d= -f2)
      [ -n "$serial" ] || continue
      if ! grep -qw "$serial" "$certifi"; then
        echo " - $(openssl x509 -noout -subject -nameopt RFC2253 <<< "$pem" | sed 's/\\//g')" >&2
        CERT="
$(openssl x509 -noout -issuer -subject -serial -fingerprint -nameopt RFC2253 <<< "$pem" | sed 's/\\//g' | xargs -I {} echo "# {}")
$(openssl x509 -outform PEM <<< "$pem")"
        if [ -w "$certifi" ]; then
          echo "$CERT" >>"$certifi"
        else
          printf '\e[33minsufficient permissions to write to %s, run the script as root.\e[0m\n' "$certifi" >&2
          break
        fi
        if [[ " $_added_serials " != *" $serial "* ]]; then
          _added_serials+="$serial "
          cert_count=$((cert_count + 1))
        fi
      fi
    done
  done
  if [ $cert_count -gt 0 ]; then
    printf "\e[34madded $cert_count certificate(s) to certifi bundle(s)\e[0m\n" >&2
  else
    printf '\e[34mno new certificates to add\e[0m\n' >&2
  fi
}

# alias for backward compatibility
alias fxcertpy='fixcertpy'

# *Function to show dev environment install provenance
devenv() {
  local install_json="$HOME/.config/dev-env/install.json"
  if [ ! -f "$install_json" ]; then
    printf "\e[33mNo install record found.\e[0m\n"
    return 0
  fi
  if ! type jq &>/dev/null; then
    cat "$install_json"
    return 0
  fi
  local ver entry src src_ref scopes installed_at mode status phase plat nix_ver err_msg
  ver="$(jq -r '.version // "unknown"' "$install_json")"
  entry="$(jq -r '.entry_point // "unknown"' "$install_json")"
  src="$(jq -r '.source // "unknown"' "$install_json")"
  src_ref="$(jq -r '.source_ref // "" | if . == "" then "n/a" else .[0:12] end' "$install_json")"
  scopes="$(jq -r '.scopes // [] | join(", ")' "$install_json")"
  installed_at="$(jq -r '.installed_at // "unknown"' "$install_json")"
  mode="$(jq -r '.mode // "unknown"' "$install_json")"
  status="$(jq -r '.status // "unknown"' "$install_json")"
  phase="$(jq -r '.phase // "unknown"' "$install_json")"
  plat="$(jq -r '"\(.platform // "unknown")/\(.arch // "unknown")"' "$install_json")"
  nix_ver="$(jq -r '.nix_version // ""' "$install_json")"
  err_msg="$(jq -r '.error // ""' "$install_json")"

  printf "\e[96mdev-env\e[0m %s\n" "$ver"
  printf "  \e[90mEntry:     \e[0m%s\n" "$entry"
  printf "  \e[90mSource:    \e[0m%s (%s)\n" "$src" "$src_ref"
  printf "  \e[90mPlatform:  \e[0m%s\n" "$plat"
  printf "  \e[90mMode:      \e[0m%s\n" "$mode"
  if [ "$status" = "success" ]; then
    printf "  \e[90mStatus:    \e[32m%s\e[0m\n" "$status"
  else
    printf "  \e[90mStatus:    \e[31m%s\e[0m (phase: %s)\n" "$status" "$phase"
    [ -n "$err_msg" ] && printf "  \e[90mError:     \e[31m%s\e[0m\n" "$err_msg"
  fi
  printf "  \e[90mInstalled: \e[0m%s\n" "$installed_at"
  [ -n "$nix_ver" ] && printf "  \e[90mNix:       \e[0m%s\n" "$nix_ver"
  printf "  \e[90mScopes:    \e[0m%s\n" "$scopes"
}

# *Function for intercepting MITM proxy certificates from TLS chain and saving to user cert bundle
cert_intercept() {
  # check if openssl is available
  if ! type openssl &>/dev/null; then
    printf '\e[31mopenssl is required but not installed.\e[0m\n' >&2
    return 1
  fi

  local _default_host="${NIX_ENV_TLS_PROBE_URL:-https://www.google.com}"
  _default_host="${_default_host#https://}"
  _default_host="${_default_host#http://}"
  local uris=("${@:-$_default_host}")
  local cert_bundle="$HOME/.config/certs/ca-custom.crt"
  local cert_count=0
  local skip_count=0

  # ensure cert directory exists
  mkdir -p "$HOME/.config/certs"

  # read existing serials from bundle for deduplication
  local _existing_serials=" "
  if [ -f "$cert_bundle" ]; then
    while IFS= read -r serial; do
      [ -n "$serial" ] && _existing_serials+="$serial "
    done < <(openssl storeutl -noout -text -certs "$cert_bundle" 2>/dev/null | sed -n 's/.*Serial Number: *//p' || true)
    # fallback: parse PEM blocks and extract serials individually
    if [ "$_existing_serials" = " " ]; then
      local current_pem=""
      while IFS= read -r line; do
        if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
          current_pem="$line"
        elif [[ "$line" == "-----END CERTIFICATE-----" ]]; then
          current_pem+=$'\n'"$line"
          local ser
          ser=$(openssl x509 -noout -serial <<< "$current_pem" 2>/dev/null | cut -d= -f2)
          [ -n "$ser" ] && _existing_serials+="$ser "
          current_pem=""
        elif [[ -n "$current_pem" ]]; then
          current_pem+=$'\n'"$line"
        fi
      done < "$cert_bundle"
    fi
  fi

  for uri in "${uris[@]}"; do
    printf '\e[36mintercepting certificates from %s...\e[0m\n' "$uri" >&2

    # get full TLS chain
    local chain_pem
    chain_pem=$(openssl s_client -showcerts -connect "${uri}:443" </dev/null 2>/dev/null) || {
      printf '\e[33mfailed to connect to %s\e[0m\n' "$uri" >&2
      continue
    }

    # parse individual PEM blocks from chain, skip the first (leaf) cert
    local pem_blocks=()
    local current_pem=""
    local cert_index=0
    while IFS= read -r line; do
      if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
        current_pem="$line"
      elif [[ "$line" == "-----END CERTIFICATE-----" ]]; then
        current_pem+=$'\n'"$line"
        cert_index=$((cert_index + 1))
        # skip the first cert (leaf/server cert)
        if [ $cert_index -gt 1 ]; then
          pem_blocks+=("$current_pem")
        fi
        current_pem=""
      elif [[ -n "$current_pem" ]]; then
        current_pem+=$'\n'"$line"
      fi
    done <<< "$chain_pem"

    # process each intermediate/root cert
    for pem in "${pem_blocks[@]}"; do
      local serial
      serial=$(openssl x509 -noout -serial -nameopt RFC2253 <<< "$pem" 2>/dev/null | cut -d= -f2)
      [ -n "$serial" ] || continue

      # check for duplicate
      if [[ " $_existing_serials " == *" $serial "* ]]; then
        skip_count=$((skip_count + 1))
        continue
      fi

      # format cert with header comments and append to bundle
      local header
      header=$(openssl x509 -noout -issuer -subject -serial -fingerprint -nameopt RFC2253 <<< "$pem" 2>/dev/null | sed 's/\\//g' | xargs -I {} echo "# {}")
      local cert_pem
      cert_pem=$(openssl x509 -outform PEM <<< "$pem" 2>/dev/null)

      printf '%s\n%s\n' "$header" "$cert_pem" >> "$cert_bundle"
      _existing_serials+="$serial "
      cert_count=$((cert_count + 1))
      printf ' \e[32m+ %s\e[0m\n' "$(openssl x509 -noout -subject -nameopt RFC2253 <<< "$pem" 2>/dev/null | sed 's/\\//g')" >&2
    done
  done

  # print summary
  if [ $cert_count -gt 0 ]; then
    printf '\e[34madded %d certificate(s) to %s\e[0m\n' "$cert_count" "${cert_bundle/$HOME/\~}" >&2
  else
    printf '\e[34mno new certificates to add\e[0m\n' >&2
  fi
  [ $skip_count -gt 0 ] && printf '\e[90m(%d already existing, skipped)\e[0m\n' "$skip_count" >&2
}
