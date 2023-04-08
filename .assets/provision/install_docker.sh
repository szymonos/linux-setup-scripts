#!/usr/bin/env bash
: '
sudo .assets/provision/install_docker.sh
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
arch)
  sudo -u $(id -un 1000) paru -Sy --needed --noconfirm docker
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
  echo -e '\e[93mwarning: systemd is not running\e[0m'
fi
