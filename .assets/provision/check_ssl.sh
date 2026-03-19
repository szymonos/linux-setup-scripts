#!/usr/bin/env bash
: '
sudo .assets/provision/check_ssl.sh
'

# install curl if not available
if ! command -v curl >/dev/null 2>&1; then
  printf '\e[3minstalling curl for SSL check...\e[0m\n' >&2
  SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
  case $SYS_ID in
  alpine)
    apk add --no-cache --no-check-certificate curl >/dev/null 2>&1
    ;;
  arch)
    pacman -Sy --needed --noconfirm curl >/dev/null 2>&1
    ;;
  fedora)
    dnf install -y --setopt=sslverify=0 curl >/dev/null 2>&1
    ;;
  debian | ubuntu)
    apt-get update >/dev/null 2>&1 && apt-get install -y curl >/dev/null 2>&1
    ;;
  opensuse)
    zypper --non-interactive in -y curl >/dev/null 2>&1
    ;;
  esac
fi

# check SSL connectivity
if command -v curl >/dev/null 2>&1; then
  curl -sS https://www.google.com >/dev/null 2>&1 && echo true || echo false
elif command -v wget >/dev/null 2>&1; then
  wget -q --spider https://www.google.com 2>&1 && echo true || echo false
elif command -v python3 >/dev/null 2>&1; then
  python3 -c "import urllib.request; urllib.request.urlopen('https://www.google.com')" 2>/dev/null && echo true || echo false
else
  echo unknown
fi
