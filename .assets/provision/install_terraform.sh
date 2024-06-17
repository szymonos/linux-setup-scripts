#!/usr/bin/env bash
: '
sudo .assets/provision/install_terraform.sh
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
# check if package installed already using package manager
APP='terraform'
case $SYS_ID in
alpine)
  exit 0
  ;;
arch)
  pacman -Qqe $APP &>/dev/null && exit 0 || true
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
[ -z "$REL" ] && REL="$(get_gh_release_latest --owner 'hashicorp' --repo 'terraform')"
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$($APP --version | sed -En 's/Terraform v([0-9\.]+)/\1/p')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
case $SYS_ID in
arch)
  pacman -Sy --needed --noconfirm terraform >&2 2>/dev/null
  ;;
fedora)
  dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
  dnf -y install terraform
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  wget -O- https://apt.releases.hashicorp.com/gpg 2>/dev/null | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
  gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" >/etc/apt/sources.list.d/hashicorp.list
  apt-get update && apt-get install terraform
  ;;
opensuse)
  zypper in -y terraform >&2 2>/dev/null
  ;;
esac
