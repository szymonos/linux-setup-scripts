#!/usr/bin/env bash
: '
. .assets/provision/source.sh
'
# *function to download file from specified uri
download_file() {
  # parse named parameters
  local uri=${uri}
  local target_dir=${target_dir:-'.'}
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

  # define local variables
  local file_name="$(basename $uri)"
  local max_retries=10
  local retry_count=0

  while [[ $retry_count -lt $max_retries ]]; do
    # download file
    status_code=$(curl -w %{http_code} -#Lko "$target_dir/$file_name" "$uri")

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
      ;;
    esac
  done

  echo "Failed to download file after $max_retries attempts." >&2
  return 1
}

# *function to get the latest release from the specified GitHub repo
get_gh_release_latest() {
  # parse named parameters
  local owner=${owner}
  local repo=${repo}
  while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
      param="${1/--/}"
      declare $param="$2"
    fi
    shift
  done

  # define local variables
  local max_retries=1
  local retry_count=0
  local api_response
  local rate_limit_message="API rate limit exceeded"

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

  # send API request to GitHub
  while [ $retry_count -lt $max_retries ]; do
    api_response=$(curl -sk https://api.github.com/repos/$owner/$repo/releases/latest)
    # check for API rate limit exceeded
    if echo "$api_response" | jq -e '.message' | grep -q "API rate limit exceeded"; then
      type gh &>/dev/null && token="$(gh auth token 2>/dev/null)"
      if [ -n "$token" ]; then
        header="Authorization: Bearer ${token}"
        api_response=$(curl -H "$header" -sk https://api.github.com/repos/$owner/$repo/releases/latest)
        # check for bad credentials
        if echo "$api_response" | jq -e '.message' | grep -q "Bad credentials"; then
          printf "\e[31mError: Bad credentials, run the \e[4mgh auth login\e[24m command.\e[0m\n" >&2
          return 1
        fi
      else
        printf "\e[31mError: API rate limit exceeded. Please try again later.\e[0m\n" >&2
        return 1
      fi
    fi
    # get the tag_name from the API response
    tag_name=$(echo "$api_response" | jq -r '.tag_name')
    if [ -n "$tag_name" ]; then
      rel="$(echo $tag_name | sed -E 's/.*[^0-9]?([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
      if [ -n "$rel" ]; then
        echo "$rel"
        return 0
      else
        printf "\e[31mError: Returned tag_name doesn't conform to the semantic versioning.\e[0m\n" >&2
        return 1
      fi
    else
      # increment the retry count
      ((retry_count++))
      echo "retrying... $(($retry_count + 1))/$max_retries" >&2
    fi
  done

  printf "\e[31mFailed to get latest release after $max_retries attempts.\e[0m\n" >&2
  return 1
}
