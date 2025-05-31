#!/usr/bin/env bash
: '
.assets/provision/setup_gh.sh
.assets/provision/setup_gh.sh 'show_token'
'
# parse named parameters
# *check gh authentication status and login to GitHub if necessary
if [ -x /usr/bin/gh ]; then
  retry_count=0
  while [[ $retry_count -lt 5 ]] && [ -z "$token" ]; do
    token="$(gh auth token 2>/dev/null)"
    if [ -z "$token" ]; then
      gh auth login
      token="$(gh auth token 2>/dev/null)"
    fi
    ((retry_count++))
  done
  if [ -n "$token" ] && [ 'show_token' = "$1" ]; then
    echo "$token"
  fi
fi
