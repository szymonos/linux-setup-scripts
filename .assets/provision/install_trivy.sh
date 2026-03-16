#!/usr/bin/env bash
: '
sudo .assets/provision/install_trivy.sh >/dev/null
'
set -euo pipefail

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# set binary flag if package manager is not supported
binary=false
# check if package installed already using package manager
APP='trivy'
case $SYS_ID in
arch)
  pacman -Qqe $APP &>/dev/null && exit 0 || true
  ;;
fedora)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
debian)
  dpkg -s $APP &>/dev/null && exit 0 || true
  ;;
ubuntu)
  dpkg -s $APP &>/dev/null && exit 0 || true
  ;;
opensuse)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
esac

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
REL=${1:-}
# get latest release if not provided as a parameter
if [ -z "$REL" ]; then
  REL="$(get_gh_release_latest --owner 'aquasecurity' --repo 'trivy')"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo $REL

if type $APP &>/dev/null; then
  VER=$(trivy --version 2>/dev/null | sed -En 's/Version: ([0-9.]+).*/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[0m\n" >&2
case $SYS_ID in
arch)
  pacman -Sy --needed --noconfirm $APP >&2 2>/dev/null || binary=true
  ;;
fedora)
  if [ ! -f /etc/yum.repos.d/trivy.repo ]; then
    cat >/etc/yum.repos.d/trivy.repo <<'EOF'
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
EOF
  fi
  dnf install -y $APP >&2 2>/dev/null || binary=true
  ;;
debian)
  export DEBIAN_FRONTEND=noninteractive
  mkdir -p /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/trivy.gpg ]; then
    curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key 2>/dev/null | gpg --dearmor -o /etc/apt/keyrings/trivy.gpg
  fi
  echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" >/etc/apt/sources.list.d/trivy.list
  chmod 644 /etc/apt/keyrings/trivy.gpg /etc/apt/sources.list.d/trivy.list
  apt-get update >&2 && apt-get install -y $APP >&2 2>/dev/null || binary=true
  ;;
ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  mkdir -p /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/trivy.gpg ]; then
    curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key 2>/dev/null | gpg --dearmor -o /etc/apt/keyrings/trivy.gpg
  fi
  echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" >/etc/apt/sources.list.d/trivy.list
  chmod 644 /etc/apt/keyrings/trivy.gpg /etc/apt/sources.list.d/trivy.list
  apt-get update >&2 && apt-get install -y $APP >&2 2>/dev/null || binary=true
  ;;
opensuse)
  zypper --non-interactive in -y $APP >&2 2>/dev/null || binary=true
  ;;
*)
  binary=true
  ;;
esac

if [ "$binary" = true ] && [ -n "$REL" ]; then
  printf "Installing $APP \e[1mv$REL\e[22m from binary.\n" >&2
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -d -p "$HOME")
  trap 'rm -fr "$TMP_DIR"' EXIT
  # calculate download uri
  URL="https://github.com/aquasecurity/trivy/releases/download/v${REL}/trivy_${REL}_Linux-64bit.tar.gz"
  # download and install file
  if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
    tar -zxf "$TMP_DIR/$(basename "$URL")" -C "$TMP_DIR"
    install -m 0755 "$TMP_DIR/$APP" /usr/local/bin/
  fi
fi
