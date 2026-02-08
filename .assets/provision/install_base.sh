#!/usr/bin/env sh
: '
sudo .assets/provision/install_base.sh $(id -un)
'
set -eu

if [ $(id -u) -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

install_pkgs() {
  manager=$1
  pkgs=$2

  case "$manager" in
  apk)
    if ! apk add --no-cache $pkgs 2>/dev/null; then
      for pkg in $pkgs; do
        apk add --no-cache "$pkg" 2>/dev/null || true
      done
    fi
    ;;
  pacman)
    if ! pacman -Sy --needed --noconfirm --color=auto $pkgs 2>/dev/null; then
      for pkg in $pkgs; do
        pacman -S --needed --noconfirm --color=auto "$pkg" 2>/dev/null || true
      done
    fi
    ;;
  dnf)
    if ! dnf install -y $pkgs 2>/dev/null; then
      for pkg in $pkgs; do
        dnf install -y "$pkg" 2>/dev/null || true
      done
    fi
    ;;
  apt)
    if ! apt-get install -y $pkgs 2>/dev/null; then
      for pkg in $pkgs; do
        apt-get install -y "$pkg" 2>/dev/null || true
      done
    fi
    ;;
  zypper)
    if ! zypper --non-interactive in -y $pkgs 2>/dev/null; then
      for pkg in $pkgs; do
        zypper --non-interactive --no-refresh in -y "$pkg" 2>/dev/null || true
      done
    fi
    ;;
  *)
    # fallback: do nothing
    true
    ;;
  esac
}

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

case $SYS_ID in
alpine)
  # update package index
  apk update 2>/dev/null || true
  # install base packages
  pkgs="bash bind-tools build-base ca-certificates curl iputils gawk git jq less lsb-release-minimal mandoc nmap openssh-client shfmt openssl sudo tar tig tree unzip vim which whois"
  install_pkgs apk "$pkgs"
  ;;
arch)
  # initialize keyring
  pacman-key --init
  # refresh package database and install archlinux-keyring
  pacman -Sy --needed --noconfirm --color=auto archlinux-keyring
  # install base packages
  pkgs="base-devel bash-completion curl dnsutils gawk git jq lsb-release man-db nmap openssh shfmt openssl tar tig tree unzip vim wget which whois"
  install_pkgs pacman "$pkgs"
  # install paru
  if ! pacman -Qqe paru >/dev/null 2>&1; then
    user=${1:-$(id -un 1000 2>/dev/null || true)}
    if ! sudo -u $user true 2>/dev/null; then
      if [ -n "$user" ]; then
        printf "\e[31;1mUser does not exist ($user).\e[0m\n"
      else
        printf "\e[31;1mUser ID 1000 not found.\e[0m\n"
      fi
      exit 1
    fi
    sudo -u $user bash -c 'git clone https://aur.archlinux.org/paru-bin.git && cd paru-bin && makepkg -si --noconfirm && cd ..; rm -fr paru-bin'
    grep -qw '^BottomUp' /etc/paru.conf || sed -i 's/^#BottomUp/BottomUp/' /etc/paru.conf
  fi
  ;;
fedora)
  # cache metadata once so subsequent installs don't refresh repeatedly
  dnf makecache -q 2>/dev/null || true
  # install development tools group
  rpm -q patch >/dev/null 2>&1 || dnf group install -y development-tools 2>/dev/null || true
  # install base packages
  if [ "$(readlink $(which dnf))" = 'dnf5' ]; then
    pkgs="bash-completion bind-utils curl dnf5-plugins gawk git iputils jq man-db nmap shfmt openssl tar tig tree unzip vim wget which whois"
  else
    pkgs="bash-completion bind-utils curl dnf-plugins-core gawk git iputils jq man-db nmap shfmt openssl tar tig tree unzip vim wget which whois"
  fi
  install_pkgs dnf "$pkgs"
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  # refresh package index
  apt-get update 2>/dev/null
  # install base packages
  pkgs="build-essential bash-completion ca-certificates curl gawk gnupg dnsutils git iputils-tracepath jq lsb-release man-db nmap shfmt openssl tar tig tree unzip vim wget which whois"
  install_pkgs apt "$pkgs"
  ;;
opensuse)
  # refresh package index
  zypper refresh 2>/dev/null || true
  # install development tools pattern
  rpm -q patch >/dev/null 2>&1 || zypper --non-interactive --no-refresh in -yt pattern devel_basis 2>/dev/null || true
  # install base packages
  pkgs="bash-completion bind-utils curl gawk git jq lsb-release nmap shfmt openssl tar tig tree unzip vim wget which whois"
  install_pkgs zypper "$pkgs"
  ;;
esac
