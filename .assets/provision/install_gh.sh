#!/usr/bin/env bash
: '
sudo .assets/provision/install_gh.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
case $SYS_ID in
alpine)
  apk -e info github-cli &>/dev/null && exit 0 || true
  ;;
arch)
  pacman -Qqe github-cli &>/dev/null && exit 0 || true
  ;;
fedora | opensuse)
  rpm -q gh &>/dev/null && exit 0 || true
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -dp "$HOME")
  if download_file --uri "https://cli.github.com/packages/githubcli-archive-keyring.gpg" --target_dir "$TMP_DIR"; then
    mkdir -p -m 755 /etc/apt/keyrings
    install -m 0644 "$TMP_DIR/githubcli-archive-keyring.gpg" /etc/apt/keyrings
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >/etc/apt/sources.list.d/github-cli.list
  fi
  # remove temporary dir
  rm -fr "$TMP_DIR"
  # check if installed already
  dpkg -s gh &>/dev/null && exit 0 || true
  ;;
esac

printf "\e[92minstalling \e[1mgithub-cli\e[0m\n" >&2
case $SYS_ID in
alpine)
  apk add --no-cache github-cli >&2 2>/dev/null
  ;;
arch)
  pacman -Sy --needed --noconfirm github-cli >&2 2>/dev/null
  ;;
fedora)
  dnf install -y gh >&2 2>/dev/null
  ;;
debian | ubuntu)
  apt-get update && apt-get install -y gh >&2 2>/dev/null
  ;;
opensuse)
  zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo
  zypper ref
  zypper install -y gh >&2 2>/dev/null
  ;;
esac
