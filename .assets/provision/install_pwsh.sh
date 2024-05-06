#!/usr/bin/env bash
: '
sudo .assets/provision/install_pwsh.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

APP='pwsh'
REL=$1
retry_count=0
# try 10 times to get latest release if not provided as a parameter
while [ -z "$REL" ]; do
  REL=$(curl -sk https://api.github.com/repos/PowerShell/PowerShell/releases/latest | sed -En 's/.*"tag_name": "v?([^"]*)".*/\1/p')
  ((retry_count++))
  if [ $retry_count -eq 10 ]; then
    printf "\e[33m$APP version couldn't be retrieved\e[0m\n" >&2
    exit 0
  fi
  [[ "$REL" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(pwsh -nop -c '$PSVersionTable.PSVersion.ToString()')
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[22m v$REL\e[0m\n" >&2
# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

case $SYS_ID in
alpine)
  apk add --no-cache ncurses-terminfo-base krb5-libs libgcc libintl libssl1.1 libstdc++ tzdata userspace-rcu zlib icu-libs >&2 2>/dev/null
  apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache lttng-ust >&2 2>/dev/null
  TMP_DIR=$(mktemp -dp "$PWD")
  retry_count=0
  while [[ ! -f "$TMP_DIR/$APP.tar.gz" && $retry_count -lt 10 ]]; do
    curl -#Lko "$TMP_DIR/$APP.tar.gz" "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell-${REL}-linux-alpine-x64.tar.gz"
    ((retry_count++))
  done
  mkdir -p /opt/microsoft/powershell/7 && tar -zxf "$TMP_DIR/$APP.tar.gz" -C /opt/microsoft/powershell/7
  rm -fr "$TMP_DIR"
  chmod +x /opt/microsoft/powershell/7/pwsh && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
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
    sudo -u $user paru -Sy --needed --noconfirm powershell-bin
  else
    binary=true
  fi
  ;;
fedora)
  dnf install -y "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell-${REL}-1.rh.x86_64.rpm" >&2 2>/dev/null || binary=true
  ;;
debian | ubuntu)
  if grep -qGw '"24.04"' /etc/os-release; then
    # install pwsh from binary
    # TODO remove after the issue on the Ubuntu 24.04 will be fixed
    binary=true
  else
    export DEBIAN_FRONTEND=noninteractive
    [ "$SYS_ID" = 'debian' ] && apt-get update >&2 && apt-get install -y libicu67 >&2 2>/dev/null || true
    TMP_DIR=$(mktemp -dp "$PWD")
    retry_count=0
    while [[ ! -f "$TMP_DIR/$APP.deb" && $retry_count -lt 10 ]]; do
      curl -#Lko "$TMP_DIR/$APP.deb" "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell_${REL}-1.deb_amd64.deb"
      ((retry_count++))
    done
    dpkg -i "$TMP_DIR/$APP.deb" >&2 2>/dev/null || binary=true
    rm -fr "$TMP_DIR"
  fi
  ;;
*)
  binary=true
  ;;
esac

if [ "$binary" = true ]; then
  echo 'Installing from binary.' >&2
  [ "$SYS_ID" = 'opensuse' ] && zypper in -y libicu >&2 2>/dev/null || true
  TMP_DIR=$(mktemp -dp "$PWD")
  retry_count=0
  while [[ ! -f "$TMP_DIR/$APP.tar.gz" && $retry_count -lt 10 ]]; do
    curl -#Lko "$TMP_DIR/$APP.tar.gz" "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell-${REL}-linux-x64.tar.gz"
    ((retry_count++))
  done
  mkdir -p /opt/microsoft/powershell/7
  tar -zxf "$TMP_DIR/$APP.tar.gz" -C /opt/microsoft/powershell/7
  rm -fr "$TMP_DIR"
  chmod +x /opt/microsoft/powershell/7/pwsh
  [ -f /usr/bin/pwsh ] || ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
fi
