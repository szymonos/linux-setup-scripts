#!/usr/bin/env bash
: '
sudo .assets/provision/install_pwsh.sh >/dev/null
'
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m'
  exit 1
fi

APP='pwsh'
REL=$1
# get latest release if not provided as a parameter
while [[ -z "$REL" ]]; do
  REL=$(curl -sk https://api.github.com/repos/PowerShell/PowerShell/releases/latest | grep -Po '"tag_name": *"v?\K.*?(?=")')
  [[ -n "$REL" ]] || echo 'retrying...' >&2
done
# return latest release
echo $REL

if type $APP &>/dev/null; then
  VER=$(pwsh -nop -c '$PSVersionTable.PSVersion.ToString()')
  if [ "$REL" = "$VER" ]; then
    echo -e "\e[32m$APP v$VER is already latest\e[0m" >&2
    exit 0
  fi
fi

echo -e "\e[92minstalling $APP v$REL\e[0m" >&2
# determine system id
SYS_ID=$(grep -oPm1 '^ID(_LIKE)?=.*?\K(alpine|arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)

case $SYS_ID in
alpine)
  apk add --no-cache ncurses-terminfo-base krb5-libs libgcc libintl libssl1.1 libstdc++ tzdata userspace-rcu zlib icu-libs >&2 2>/dev/null
  apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache lttng-ust >&2 2>/dev/null
  while [[ ! -f powershell.tar.gz ]]; do
    curl -Lsk -o powershell.tar.gz "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell-${REL}-linux-alpine-x64.tar.gz"
  done
  mkdir -p /opt/microsoft/powershell/7 && tar -zxf powershell.tar.gz -C /opt/microsoft/powershell/7 && rm powershell.tar.gz
  chmod +x /opt/microsoft/powershell/7/pwsh && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
  ;;
fedora)
  dnf install -y "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell-${REL}-1.rh.x86_64.rpm" >&2 2>/dev/null || binary=true
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  [ "$SYS_ID" = 'debian' ] && apt-get update >&2 && apt-get install -y libicu67 >&2 2>/dev/null || true
  while [[ ! -f powershell.deb ]]; do
    curl -Lsk -o powershell.deb "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell_${REL}-1.deb_amd64.deb"
  done
  dpkg -i powershell.deb && rm -f powershell.deb >&2 2>/dev/null || binary=true
  ;;
*)
  binary=true
  ;;
esac

if [[ "$binary" = true ]]; then
  echo 'Installing from binary.' >&2
  [ "$SYS_ID" = 'opensuse' ] && zypper in -y libicu >&2 2>/dev/null || true
  while [[ ! -f powershell.tar.gz ]]; do
    curl -Lsk -o powershell.tar.gz "https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell-${REL}-linux-x64.tar.gz"
  done
  mkdir -p /opt/microsoft/powershell/7
  tar -zxf powershell.tar.gz -C /opt/microsoft/powershell/7 && rm -f powershell.tar.gz
  chmod +x /opt/microsoft/powershell/7/pwsh
  [ -f /usr/bin/pwsh ] || ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
fi
