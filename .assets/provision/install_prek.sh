#!/usr/bin/env bash
: '
.assets/provision/install_prek.sh >/dev/null
'
if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='prek'

# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'j178' --repo 'prek')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

# check installed version of prek and update if necessary
if [ -x "$HOME/.local/bin/prek" ]; then
  VER="$($HOME/.local/bin/prek --version | sed -En 's/.*\s([0-9\.]+)/\1/p')"
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  else
    retry_count=0
    max_retries=5
    while [ $retry_count -le $max_retries ]; do
      $HOME/.local/bin/prek self update >&2
      [ $? -eq 0 ] && break || true
      ((retry_count++))
      echo "retrying... $retry_count/$max_retries" >&2
      if [ $retry_count -eq $max_retries ]; then
        printf "\e[31mFailed to update $APP after $max_retries attempts.\e[0m\n" >&2
        exit 1
      fi
    done
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# create temporary dir for the downloaded binary
TMP_DIR=$(mktemp -dp "$HOME")
# calculate download uri
URL="https://github.com/j178/prek/releases/download/v$REL/prek-installer.sh"
# download and install file
if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
  retry_count=0
  while [ ! -x "$HOME/.local/bin/prek" ] && [ $retry_count -lt 10 ]; do
    sh "$TMP_DIR/prek-installer.sh"
    ((retry_count++))
  done
fi
# remove temporary dir
rm -fr "$TMP_DIR"

exit 0
