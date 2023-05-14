#!/usr/bin/env bash
: '
sudo .assets/provision/install_docker.sh $(id -un)
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

case $SYS_ID in
alpine)
  exit 0
  ;;
arch)
  if pacman -Qqe paru &>/dev/null; then
    user=${1:-$(id -un 1000 2>/dev/null)}
    if ! sudo -u $user true 2>/dev/null; then
      if [ -n "$user" ]; then
        printf "\e[31;1mUser does not exist ($user).\e[0m\n"
      else
        printf "\e[31;1mUser ID 1000 not found.\e[0m\n"
      fi
      exit 1
    fi
    sudo -u $user paru -Sy --needed --noconfirm docker
  else
    printf '\e[33;1mWarning: paru not installed.\e[0m\n'
  fi
  ;;
fedora)
  if rpm -q docker &>/dev/null; then
    dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
  fi
  if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    dnf config-manager --add-repo 'https://download.docker.com/linux/fedora/docker-ce.repo'
  fi
  dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  if dpkg -s docker &>/dev/null; then
    apt-get remove docker docker-engine docker.io containerd runc 2>/dev/null
  fi
  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSLk "https://download.docker.com/linux/$SYS_ID/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$SYS_ID \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
  fi
  apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ;;
opensuse)
  zypper in -y docker containerd docker-compose
  ;;
esac

# add user to docker group
if ! grep -q "^docker:.*\b$(id -un 1000)\b" /etc/group; then
  usermod -aG docker $(id -un 1000)
fi

# start docker services if systemd is running
if systemctl status 2>/dev/null | grep -qw systemd; then
  systemctl enable --now docker.service
  systemctl enable --now containerd.service
else
  printf '\e[33;1mWarning: systemd is not running.\e[0m\n'
fi
