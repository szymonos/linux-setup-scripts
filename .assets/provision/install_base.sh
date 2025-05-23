#!/usr/bin/env sh
: '
sudo .assets/provision/install_base.sh $(id -un)
'
if [ $(id -u) -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

case $SYS_ID in
alpine)
  apk add --no-cache bash bind-tools build-base ca-certificates iputils curl git jq less lsb-release-minimal mandoc nmap openssh-client openssl sudo tar tig tree unzip vim whois
  ;;
arch)
  pacman -Sy --needed --noconfirm --color=auto base-devel bash-completion dnsutils git jq lsb-release man-db nmap openssh openssl tar tig tree unzip vim wget whois 2>/dev/null
  # install paru
  if ! pacman -Qqe paru &>/dev/null; then
    user=${1:-$(id -un 1000 2>/dev/null)}
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
  rpm -q patch &>/dev/null || dnf group install -y development-tools
  dnf install -qy bash-completion bind-utils curl dnf5-plugins git iputils jq man-db nmap openssl tar tig tree unzip vim wget whois
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update && apt-get install -y build-essential bash-completion ca-certificates gnupg dnsutils curl git iputils-tracepath jq lsb-release man-db nmap openssl tar tig tree unzip vim wget whois
  ;;
opensuse)
  rpm -q patch &>/dev/null || zypper in -yt pattern devel_basis
  zypper in -y bash-completion bind-utils git jq lsb-release nmap openssl tar tig tree unzip vim wget whois
  ;;
esac
