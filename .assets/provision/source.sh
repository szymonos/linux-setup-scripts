#!/usr/bin/env bash
: '
. .assets/provision/source.sh
'
# *function to log in to GitHub as the specified user using the gh CLI
# Usage: login_gh_user              # logs in the current user
# Usage: login_gh_user -u $user     # logs in the specified user
# Usage: login_gh_user -u $user -k  # logs in the specified user admin:public_key scope
login_gh_user() {
  # check if the gh CLI is installed
  if ! [ -x /usr/bin/gh ]; then
    printf "\e[31mError: The \e[1mgh\e[22m command is required but not installed.\e[0m\n" >&2
    return 1
  fi

  # initialize local variable to the current user
  local user="$(id -un)"
  local token=""
  local retries=0
  local key=false
  # parse named parameters
  OPTIND=1
  while getopts ":u:k" opt; do
    case $opt in
    u)
      user="$OPTARG"
      ;;
    k)
      key=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    esac
  done
  shift $((OPTIND - 1))

  # check if the user exists
  if ! id -u "$user" &>/dev/null; then
    printf "\e[31mError: The user \e[1m$user\e[22m does not exist.\e[0m\n" >&2
    return 1
  fi

  # *check gh authentication status
  auth_status="$(sudo -u "$user" gh auth status 2>/dev/null)"
  # extract gh username
  gh_user="$(echo "$auth_status" | sed -rn '/Logged in to/ s/.*account ([[:alnum:]._.-]+).*/\1/p')"
  gh_user=${gh_user:-$user}

  if echo "$auth_status" | grep -Fwq '✓'; then
    if [ "$key" = true ]; then
      if echo "$auth_status" | grep -Fwq 'admin:public_key'; then
        printf "\e[32mUser \e[1m$gh_user\e[22m is already authenticated to GitHub.\e[0m\n" >&2
      else
        while [[ $retries -lt 5 ]] && [ -z "$token" ]; do
          sudo -u "$user" gh auth refresh -s admin:public_key >&2
          token="$(sudo -u "$user" gh auth token 2>/dev/null)"
          ((retries++))
        done
      fi
    else
      printf "\e[32mUser \e[1m$gh_user\e[22m is already authenticated to GitHub.\e[0m\n" >&2
    fi
  else
    # try to authenticate the user
    while [[ $retries -lt 3 ]] && [ -z "$token" ]; do
      if [ "$key" = true ]; then
        sudo -u "$user" gh auth login -s admin:public_key >&2
      else
        sudo -u "$user" gh auth login >&2
      fi
      token="$(sudo -u "$user" gh auth token 2>/dev/null)"
      ((retries++))
    done

    if [ -n "$token" ]; then
      auth_status="$(sudo -u "$user" gh auth status)"
    else
      printf "\e[33mFailed to authenticate to GitHub.\e[0m\n" >&2
      echo 'none'
      return 1
    fi
  fi

  # *check gh authentication method
  if echo "$auth_status" | grep -Fwq 'keyring'; then
    echo 'keyring'
  elif echo "$auth_status" | grep -Fwq '.config/gh/hosts.yml'; then
    gh_cfg=$(echo "$auth_status" | sed -n '/Logged in to/ s/.*(\([^)]*\)).*/\1/p')
    cat "$gh_cfg"
  else
    echo 'unknown'
  fi

  return 0
}

# *function to download file from specified uri
download_file() {
  # named parameters: --uri <url> [--target_dir <dir>]
  local uri="" target_dir="."
  while [ $# -gt 0 ]; do
    case "$1" in
    --*=*)
      param="${1%%=*}"
      val="${1#*=}"
      param="${param#--}"
      declare "$param"="$val"
      shift
      ;;
    --*)
      param="${1#--}"
      shift
      declare "$param"="$1"
      shift
      ;;
    *)
      shift
      ;;
    esac
  done

  if [ -z "${uri:-}" ]; then
    printf "\e[31mError: The \e[4muri\e[24m parameter is required.\e[0m\n" >&2
    return 1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    printf "\e[31mError: The \e[4mcurl\e[24m command is required.\e[0m\n" >&2
    return 1
  fi

  target_dir="${target_dir:-.}"
  mkdir -p "$target_dir" >/dev/null 2>&1 || true

  local file_name file_path
  file_name="$(basename "$uri")"
  file_path="$target_dir/$file_name"
  local attempt=0 max_attempts=8

  while [ $attempt -lt $max_attempts ]; do
    if curl --fail -sS -L --retry 3 --retry-delay 2 -o "$file_path" "$uri"; then
      echo "Download successful. Ready to install." >&2
      return 0
    fi
    attempt=$((attempt + 1))
    # If a 404 is returned curl will exit non-zero; detect and bail early
    if [ -f "$file_path" ] && [ ! -s "$file_path" ]; then
      rm -f "$file_path" >/dev/null 2>&1 || true
    fi
    echo "Download attempt $attempt/$max_attempts failed. Retrying..." >&2
    sleep $((attempt < 3 ? 1 : 2))
  done

  printf "\e[31mFailed to download file after %s attempts: %s\e[0m\n" "$max_attempts" "$uri" >&2
  return 1
}

# *function to get the latest release from the specified GitHub repo
get_gh_release_latest() {
  # named params: --owner <owner> --repo <repo> [--asset <name>] [--regex <regex>]
  local owner="" repo="" asset="" regex=""
  while [ $# -gt 0 ]; do
    case "$1" in
    --*=*)
      param="${1%%=*}"
      val="${1#*=}"
      param="${param#--}"
      declare "$param"="$val"
      shift
      ;;
    --*)
      param="${1#--}"
      shift
      declare "$param"="$1"
      shift
      ;;
    *)
      shift
      ;;
    esac
  done

  local max_retries=8
  local attempt=0
  local api_response
  local token=""

  if [ -z "${owner:-}" ] || [ -z "${repo:-}" ]; then
    printf "\e[31mError: The \e[4mowner\e[24m and \e[4mrepo\e[24m parameters are required.\e[0m\n" >&2
    return 1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    printf "\e[31mError: The \e[4mcurl\e[24m command is required.\e[0m\n" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    printf "\e[31mError: The \e[4mjq\e[24m command is required.\e[0m\n" >&2
    return 1
  fi

  if command -v gh >/dev/null 2>&1; then
    token="$(gh auth token 2>/dev/null || true)"
  fi

  api_uri="https://api.github.com/repos/$owner/$repo/releases"
  if [ -z "${asset:-}" ] && [ -z "${regex:-}" ]; then
    api_uri="$api_uri/latest"
  fi

  # prepare curl headers
  headers=(-H 'Accept: application/vnd.github+json')
  [ -n "$token" ] && headers+=(-H "Authorization: Bearer $token")

  while [ $attempt -lt $max_retries ]; do
    api_response="$(curl --fail -sS -L "${headers[@]}" "$api_uri" 2>/dev/null || true)"

    # detect API errors
    msg="$(echo "$api_response" | jq -r 'try .message catch empty')"
    if echo "$msg" | grep -Fq "API rate limit exceeded"; then
      printf "\e[31mError: API rate limit exceeded. Please try again later.\e[0m\n" >&2
      return 1
    fi
    if echo "$msg" | grep -Fq "Bad credentials"; then
      printf "\e[31mError: Bad credentials, run the \e[4mgh auth login\e[24m command.\e[0m\n" >&2
      return 1
    fi

    # if this is an array response and asset/regex provided, try to pick matching release
    if echo "$api_response" | jq -e 'type == "array"' >/dev/null 2>&1 && echo "$api_response" | jq -e 'any(.[]; has("assets"))' >/dev/null 2>&1; then
      if [ -n "${asset:-}" ]; then
        api_response="$(echo "$api_response" | jq -r "limit(1; .[] | select(.assets[]?.name == \"$asset\"))")"
      elif [ -n "${regex:-}" ]; then
        api_response="$(echo "$api_response" | jq -r "limit(1; .[] | select(.assets[]?.name | test(\"$regex\")))")"
      fi
    fi

    if echo "$api_response" | jq -e '.tag_name | select(. != null and . != "")' >/dev/null 2>&1; then
      tag_name="$(echo "$api_response" | jq -r '.tag_name')"
      rel="$(echo "$tag_name" | sed -E 's/[^0-9]*([0-9]+\.[0-9]+\.[0-9]+)/\1/')"
      if [ -n "$rel" ]; then
        if [ -n "${asset:-}" ]; then
          download_url="$(echo "$api_response" | jq -r ".assets[] | select(.name == \"$asset\") | .browser_download_url")"
        elif [ -n "${regex:-}" ]; then
          download_url="$(echo "$api_response" | jq -r ".assets[] | select(.name | test(\"$regex\")) | .browser_download_url")"
        else
          unset download_url
        fi
        if [ -n "${download_url:-}" ]; then
          printf '{"version":"%s","download_url":"%s"}' "$rel" "$download_url"
        else
          echo "$rel"
        fi
        return 0
      else
        printf "\e[31mError: Returned tag_name doesn't conform to the semantic versioning (%s).\e[0m\n" "$tag_name" >&2
        return 1
      fi
    fi

    attempt=$((attempt + 1))
    echo "retrying... $attempt/$max_retries" >&2
    sleep $((attempt < 3 ? 1 : 2))
  done

  printf "\e[33mFailed to get latest release after %s attempts.\e[0m\n" "$max_retries" >&2
  return 1
}
