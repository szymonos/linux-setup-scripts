#!/usr/bin/env bash
: '
sudo .assets/provision/install_gh.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='gh'
case $SYS_ID in
alpine)
  apk -e info github-cli &>/dev/null && exit 0 || true
  ;;
arch)
  pacman -Qqe github-cli &>/dev/null && exit 0 || true
  ;;
fedora | opensuse)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
debian | ubuntu)
  dpkg -s $APP &>/dev/null && exit 0 || true
  ;;
esac

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
REL=$1
retry_count=0
# get latest release if not provided as a parameter
[ -z "$REL" ] && REL="$(get_gh_release_latest --owner 'cli' --repo 'cli')"
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(gh --version | sed -En 's/.*\s([0-9\.]+)\s.*/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
case $SYS_ID in
alpine)
  apk add --no-cache github-cli >&2 2>/dev/null
  ;;
arch)
  pacman -Sy --needed --noconfirm github-cli >&2 2>/dev/null
  ;;
fedora)
  dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
  dnf install -y gh >&2 2>/dev/null
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  curl -fsSLk https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >/etc/apt/sources.list.d/github-cli.list
  apt-get update && apt-get install -y gh >&2 2>/dev/null
  ;;
opensuse)
  zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo
  zypper ref
  zypper install -y gh >&2 2>/dev/null
  ;;
esac
