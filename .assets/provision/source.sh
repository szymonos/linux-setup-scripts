#!/usr/bin/env bash
: '
. .assets/provision/source.sh
'
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
