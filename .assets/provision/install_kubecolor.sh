#!/usr/bin/env bash
: '
sudo .assets/provision/install_kubecolor.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='kubecolor'
case $SYS_ID in
alpine)
  exit 0
  ;;
fedora)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
opensuse)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
esac

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
REL=$1
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'kubecolor' --repo 'kubecolor')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  script -q -c "kubecolor version" output.log &>/dev/null
  VER=$(cat -v output.log | grep -Po '(?<=m)([0-9]\.[0-9]\.[0-9])(?=\^)')
  rm -f output.log
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
case $SYS_ID in
fedora)
  dnf config-manager addrepo --from-repofile https://kubecolor.github.io/packages/rpm/kubecolor.repo &>/dev/null
  dnf install -y kubecolor >&2 2>/dev/null
  ;;
opensuse)
  sudo zypper addrepo https://kubecolor.github.io/packages/rpm/kubecolor.repo &>/dev/null
  zypper in -y $APP >&2 2>/dev/null
  ;;
*)
  binary=true
  ;;
esac

if [ "$binary" = true ] && [ -n "$REL" ]; then
  printf "Installing $APP \e[1mv$REL\e[22m from binary.\n" >&2
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -dp "$HOME")
  # calculate download uri
  if [[ "$SYS_ID" =~ ^(debian|ubuntu)$ ]]; then
    asset="kubecolor_${REL}_linux_amd64.deb"
  else
    asset="kubecolor_${REL}_linux_amd64.tar.gz"
  fi
  URL="https://github.com/kubecolor/kubecolor/releases/download/v${REL}/${asset}"
  # download and install file
  if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
    if [[ "$SYS_ID" =~ ^(debian|ubuntu)$ ]]; then
      sudo dpkg -i "$TMP_DIR/$asset" >&2 2>/dev/null
    else
      tar -zxf "$TMP_DIR/$asset" -C "$TMP_DIR"
      install -m 0755 "$TMP_DIR/kubecolor" /usr/bin/
    fi
  fi
  # remove temporary dir
  rm -fr "$TMP_DIR"
fi
