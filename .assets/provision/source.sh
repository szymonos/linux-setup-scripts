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

  if echo "$auth_status" | grep -Fwq '✓'; then
    if [ "$key" = true ]; then
      if echo "$auth_status" | grep -Fwq 'admin:public_key'; then
        printf "\e[32mUser \e[1m$user\e[22m is already authenticated to GitHub.\e[0m\n" >&2
      else
        while [[ $retries -lt 5 ]] && [ -z "$token" ]; do
          sudo -u "$user" gh auth refresh -s admin:public_key >&2
          token="$(sudo -u "$user" gh auth token 2>/dev/null)"
          ((retries++))
        done
      fi
    else
      printf "\e[32mUser \e[1m$user\e[22m is already authenticated to GitHub.\e[0m\n" >&2
    fi
  else
    # try to authenticate the user
    while [[ $retries -lt 5 ]] && [ -z "$token" ]; do
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
      printf "\e[31mFailed to authenticate user \e[1m$user\e[22m to GitHub.\e[0m\n" >&2
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
  # initialize local variables used as named parameters
  local uri
  local target_dir
  # parse named parameters
  while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
      param="${1/--/}"
      declare $param="$2"
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
      printf "\e[31mError: The file at the specified URL does not exist or is inaccessible:\n\e[0;4m${uri}\e[0m\n" >&2
      return 1
      ;;
    *)
      ((retry_count++))
      echo "retrying... $retry_count/$max_retries" >&2
      ;;
    esac
  done

  echo "Failed to download file after $max_retries attempts." >&2
  return 1
}

# *function to get the latest release from the specified GitHub repo
get_gh_release_latest() {
  # initialize local variables used as named parameters
  local owner
  local repo
  local asset
  local regex
  # parse named parameters
  while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
      param="${1/--/}"
      declare $param="$2"
    fi
    shift
  done

  # define local variables
  local max_retries=8
  local retry_count=0
  local api_response
  local token

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
      tag_name="$(echo "$api_response" | jq -r '.tag_name')"
      rel="$(echo $tag_name | sed -E 's/[^0-9]*([0-9]+\.[0-9]+\.[0-9]+)/\1/')"
      if [ -n "$rel" ]; then
        if [ -n "$asset" ]; then
          download_url="$(echo "$api_response" | jq -r ".assets[] | select(.name == \"$asset\") | .browser_download_url")"
        elif [ -n "$regex" ]; then
          download_url="$(echo "$api_response" | jq -r ".assets[] | select(.name | test(\"$regex\")) | .browser_download_url")"
        else
          unset download_url
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
      ((retry_count++))
      echo "retrying... $retry_count/$max_retries" >&2
    fi
  done

  printf "\e[31mFailed to get latest release after $max_retries attempts.\e[0m\n" >&2
  return 1
}
