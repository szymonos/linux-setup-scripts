#!/usr/bin/env bash
: '
. .assets/provision/source.sh
'

# *Helper to enable strict mode in the current shell when explicitly requested.
# This file is intended to be dot-sourced, so we avoid changing shell options
# implicitly on import. Call enable_strict_mode from scripts that want it.
enable_strict_mode() {
  set -euo pipefail
}

# *Function to log in to GitHub as the specified user using the gh CLI
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
          ((retries++)) || true
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
      ((retries++)) || true
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

# *Function to download file from specified uri
download_file() {
  # initialize local variables used as named parameters
  local uri=''
  local target_dir=''
  # parse named parameters
  while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
      param="${1/--/}"
      declare $param="${2:-}"
    fi
    shift
  done

  if [ -z "$uri" ]; then
    printf "\e[31mError: The \e[4muri\e[24m parameter is required.\e[0m\n" >&2
    return 1
  elif ! type curl &>/dev/null; then
    printf "\e[31mError: The \e[4mcurl\e[24m command is required.\e[0m\n" >&2
    return 1
  fi
  # set the target directory to the current directory if not specified
  [ -z "$target_dir" ] && target_dir='.' || true

  # define local variables
  local file_name="$(basename $uri)"
  local max_retries=8
  local retry_count=0

  while [ $retry_count -le $max_retries ]; do
    # download file
    status_code=$(curl -w %{http_code} -#Lko "$target_dir/$file_name" "$uri" 2>/dev/null)

    # check the HTTP status code
    case $status_code in
    200)
      echo "Download successful. Ready to install." >&2
      return 0
      ;;
    404)
      printf "\e[33mRequested file not found at the specified URL or is inaccessible:\n\e[0;4m${uri}\e[0m\n" >&2
      return 1
      ;;
    *)
      ((retry_count++)) || true
      echo "retrying... $retry_count/$max_retries" >&2
      ;;
    esac
  done

  echo "Failed to download file after $max_retries attempts." >&2
  return 1
}

# *Function to get the latest release from the specified GitHub repo
get_gh_release_latest() {
  # initialize local variables used as named parameters
  local owner=''
  local repo=''
  local asset=''
  local regex=''
  # parse named parameters
  while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
      param="${1/--/}"
      declare $param="${2:-}"
    fi
    shift
  done

  # define local variables
  local max_retries=8
  local retry_count=0
  local api_response=''
  local token=''

  if [[ -z "$owner" || -z "$repo" ]]; then
    printf "\e[31mError: The \e[4mowner\e[24m and \e[4mrepo\e[24m parameters are required.\e[0m\n" >&2
    return 1
  elif ! type curl &>/dev/null; then
    printf "\e[31mError: The \e[4mcurl\e[24m command is required.\e[0m\n" >&2
    return 1
  elif ! type jq &>/dev/null; then
    printf "\e[31mError: The \e[4mjq\e[24m command is required.\e[0m\n" >&2
    return 1
  fi

  # try to retrieve gh-cli token
  if [ -x /usr/bin/gh ]; then
    # get the token from the gh command
    token="$(gh auth token 2>/dev/null)"
  fi

  # calculate the API URI
  api_uri="https://api.github.com/repos/$owner/$repo/releases"
  # get the latest release if asset or regex is not specified
  [ -z "$asset" ] && [ -z "$regex" ] && api_uri+="/latest" || true
  cmnd="curl -sk $api_uri -H 'Accept: application/vnd.github+json'"
  # set the header with the token
  [ -n "$token" ] && cmnd+=" -H 'Authorization: Bearer ${token}'"
  # send API request to GitHub
  while [ $retry_count -le $max_retries ]; do
    if echo "$api_response" | jq -r 'try .message catch empty' | grep -wq "API rate limit exceeded"; then
      printf "\e[31mError: API rate limit exceeded. Please try again later.\e[0m\n" >&2
      return 1
    fi
    # get the latest release
    api_response="$(eval $cmnd)"

    # check for exceeded API rate limit
    if [ -n "$token" ] && echo "$api_response" | jq -r 'try .message catch empty' | grep -wq "API rate limit exceeded"; then
      printf "\e[31mError: API rate limit exceeded. Please try again later.\e[0m\n" >&2
      return 1
    elif echo "$api_response" | jq -r 'try .message catch empty' | grep -wq "Bad credentials"; then
      printf "\e[31mError: Bad credentials, run the \e[4mgh auth login\e[24m command.\e[0m\n" >&2
      return 1
    fi

    # select release by asset name or regex
    if echo "$api_response" | jq -e 'type == "array"' >/dev/null && echo "$api_response" | jq -e 'any(.[]; has("assets"))' >/dev/null; then
      if [ -n "$asset" ]; then
        api_response="$(echo $api_response | jq -r "limit(1; .[] | select(.assets[]?.name == \"$asset\"))")"
      elif [ -n "$regex" ]; then
        api_response="$(echo $api_response | jq -r "limit(1; .[] | select(.assets[]?.name | test(\"$regex\")))")"
      fi
    fi

    # Check if 'tag_name' exists
    if echo "$api_response" | jq -e '.tag_name | select(. != null and . != "")' >/dev/null; then
      local tag_name download_url rel
      tag_name="$(echo "$api_response" | jq -r '.tag_name')"
      rel="$(echo "$tag_name" | sed -E 's/[^0-9]*([0-9]+\.[0-9]+\.[0-9]+)/\1/')"
      if [ -n "$rel" ]; then
        download_url=''
        if [ -n "$asset" ]; then
          download_url="$(echo "$api_response" | jq -r ".assets[] | select(.name == \"$asset\") | .browser_download_url")"
        elif [ -n "$regex" ]; then
          download_url="$(echo "$api_response" | jq -r ".assets[] | select(.name | test(\"$regex\")) | .browser_download_url")"
        fi
        # return the version and download URL if available
        if [ -n "$download_url" ]; then
          printf '{"version":"%s","download_url":"%s"}' "$rel" "$download_url"
        else
          echo "$rel"
        fi
        return 0
      else
        printf "\e[31mError: Returned tag_name doesn't conform to the semantic versioning ($tag_name).\e[0m\n" >&2
        return 1
      fi
    else
      # increment the retry count
      ((retry_count++)) || true
      echo "retrying... $retry_count/$max_retries" >&2
    fi
  done

  printf "\e[33mFailed to get latest release after $max_retries attempts.\e[0m\n" >&2
  return 1
}

# *Helper function to recursively find a file by name (POSIX-compliant, no find command needed)
find_file() {
  local search_dir="$1"
  local target="$2"

  # check current directory
  if [ -f "$search_dir/$target" ]; then
    echo "$search_dir/$target"
    return 0
  fi

  # recursively search subdirectories
  for item in "$search_dir"/*; do
    if [ -d "$item" ]; then
      local result=$(find_file "$item" "$target")
      if [ -n "$result" ]; then
        echo "$result"
        return 0
      fi
    fi
  done

  return 1
}

# *Function to download and install GitHub releases into user directory
install_github_release_user() {
  local gh_owner gh_repo file_name binary_name current_version
  local auth_header retry_count latest_release response http_code body file url tmp_dir binary_path

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
    --gh_owner)
      gh_owner="$2"
      shift 2
      ;;
    --gh_repo)
      gh_repo="$2"
      shift 2
      ;;
    --file_name)
      file_name="$2"
      shift 2
      ;;
    --binary_name)
      binary_name="$2"
      shift 2
      ;;
    --current_version)
      current_version="$2"
      shift 2
      ;;
    *)
      printf "\e[31mUnknown parameter: $1\e[0m\n" >&2
      return 1
      ;;
    esac
  done

  #region initialization
  # validate required parameters
  if [ -z "$gh_owner" ] || [ -z "$gh_repo" ] || [ -z "$file_name" ]; then
    printf "\e[31mMissing required parameters: --gh_owner, --gh_repo, --file_name\e[0m\n" >&2
    return 1
  fi

  # set binary_name to gh_repo if not provided
  [ -z "$binary_name" ] && binary_name="$gh_repo"

  # check for GITHUB_TOKEN environment variable (should start with 'ghp_' or 'gho_' and be ~40 chars)
  auth_header=""
  if [ -n "$GITHUB_TOKEN" ] && echo "$GITHUB_TOKEN" | grep -qE "^gh[po]_" && [ ${#GITHUB_TOKEN} -ge 36 ]; then
    auth_header="-H \"Authorization: Bearer $GITHUB_TOKEN\""
  fi

  # create temporary directory and set cleanup trap
  tmp_dir=$(mktemp -d -p "$HOME")

  # Save existing traps to restore after cleanup
  local saved_return=$(trap -p RETURN)
  local saved_exit=$(trap -p EXIT)

  # Create trap that cleans up and restores outer traps (if any)
  local cleanup="rm -rf \"$tmp_dir\" >/dev/null 2>&1"
  [ -n "$saved_return" ] && cleanup="$cleanup; $saved_return" || cleanup="$cleanup; trap - RETURN"
  [ -n "$saved_exit" ] && cleanup="$cleanup; $saved_exit" || cleanup="$cleanup; trap - EXIT"
  trap "$cleanup" RETURN EXIT
  #endregion

  #region get latest release version
  printf "\e[96mfetching latest release for \e[4m%s/%s\e[24m...\e[0m\n" "$gh_owner" "$gh_repo"
  retry_count=0
  latest_release=""
  while :; do
    response=$(eval curl -skw "\"\\n%{http_code}\"" $auth_header "\"https://api.github.com/repos/${gh_owner}/${gh_repo}/releases/latest\"" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    # check for API errors
    if echo "$body" | grep -q '"message".*"API rate limit exceeded"'; then
      printf "\e[31mAPI rate limit exceeded. Please set a valid GITHUB_TOKEN environment variable.\e[0m\n" >&2
      return 1
    elif echo "$body" | grep -q '"message".*"Bad credentials"'; then
      printf "\e[31mBad credentials. The GITHUB_TOKEN is invalid.\e[0m\n" >&2
      return 1
    fi

    if [ "$http_code" = "404" ]; then
      printf "\e[31mRelease not found (404) for \e[4m%s/%s\e[0m\n" "$gh_owner" "$gh_repo" >&2
      return 1
    elif [ "$http_code" = "200" ]; then
      latest_release=$(echo "$body" | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
      [ -n "$latest_release" ] && break
    fi

    ((retry_count++)) || true
    if [ $retry_count -eq 5 ]; then
      printf "\e[31m5/5 failed to get latest release for \e[4m%s/%s\e[0m\n" "$gh_owner" "$gh_repo" >&2
      return 1
    else
      printf "%d/5 retrying...\n" "$retry_count" >&2
      sleep 1
    fi
  done

  # skip download if current_version is provided AND it equals the latest release
  if [ -n "$current_version" ] && [ "$current_version" = "$latest_release" ]; then
    printf "\e[32;1m%s\e[22m v%s is already latest release, skipping download\e[0m\n" "$binary_name" "$current_version" >&2
    return 0
  fi
  #endregion

  #region download file
  printf "\e[96mdownloading \e[1m%s\e[22m v%s...\e[0m\n" "$binary_name" "$latest_release"

  # Replace version placeholder in filename
  file="${file_name//\{VERSION\}/$latest_release}"
  url="https://github.com/${gh_owner}/${gh_repo}/releases/download/v${latest_release}/${file}"

  retry_count=0
  while :; do
    http_code=$(curl -fsSL -w "%{http_code}" "$url" -o "$tmp_dir/${file}" 2>/dev/null)

    if [ "$http_code" = "404" ]; then
      printf "\e[31mfile not found (404): \e[4m%s\e[0m\n" "$url" >&2
      return 1
    elif [ -f "$tmp_dir/${file}" ] && [ -s "$tmp_dir/${file}" ]; then
      break
    fi

    ((retry_count++)) || true
    if [ $retry_count -eq 5 ]; then
      printf "\e[31m5/5 failed to download \e[1m%s\e[22m v%s\e[0m\n" "$binary_name" "$latest_release" >&2
      return 1
    else
      printf "%d/5 retrying...\n" "$retry_count" >&2
      sleep 1
    fi
  done
  #endregion

  #region extract archive
  if [[ "$file" == *.tar.gz ]]; then
    tar -zxf "$tmp_dir/${file}" -C "$tmp_dir" 2>/dev/null
  elif [[ "$file" == *.zip ]]; then
    unzip -q -o "$tmp_dir/${file}" -d "$tmp_dir" 2>/dev/null
  fi

  # find the binary recursively using helper function (works without find command)
  binary_path=$(find_file "$tmp_dir" "$binary_name")

  if [ -f "$binary_path" ]; then
    [ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin"
    install -m 0755 "$binary_path" "$HOME/.local/bin/" &&
      printf "\e[32;1m%s\e[22m v%s installed successfully\e[0m\n" "$binary_name" "$latest_release" >&2
    return 0
  else
    printf "\e[31mBinary \e[1m%s\e[22m not found in archive\e[0m\n" "$binary_name" >&2
    return 1
  fi
  #endregion
}
