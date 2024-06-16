#!/usr/bin/env bash
: '
. .assets/provision/source.sh
'
# function to download file from specified uri
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
    printf "\e[31mError: The \e[4muri\e[24m parameter is required.\e[0m\n"
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

  if [[ -z "$owner" || -z "$repo" ]]; then
    printf "\e[31mError: The \e[4mowner\e[24m and \e[4mrepo\e[24m parameters are required.\e[0m\n"
    return 1
  fi

  # define local variables
  local gh_api="https://api.github.com/repos/${owner}/${repo}/releases/latest"

  while [ -z "$rel" ]; do
    rel=$(curl -sk "$gh_api" | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
    ((retry_count++))
    if [ $retry_count -eq 10 ]; then
      printf "\e[33mLatest \e[4m${owner}/${repo}\e[24m version couldn't be retrieved.\e[0m\n" >&2
      return 1
    fi
    [[ "$rel" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] || echo 'retrying...' >&2
  done

  echo $rel
  return 0
}
