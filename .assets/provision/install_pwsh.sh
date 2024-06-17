#!/usr/bin/env bash
: '
sudo .assets/provision/install_pwsh.sh >/dev/null
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# dotsource file with common functions
. .assets/provision/source.sh

# define variables
APP='pwsh'
REL=$1
retry_count=0
# get latest release if not provided as a parameter
[ -z "$REL" ] && REL="$(get_gh_release_latest --owner 'PowerShell' --repo 'PowerShell')"
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
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -dp "$PWD")
  # calculate download uri
  URL="https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell-${REL}-linux-alpine-x64.tar.gz"
  # download and install file
  if download_file --uri $URL --target_dir $TMP_DIR; then
    mkdir -p /opt/microsoft/powershell/7
    tar -zxf "$TMP_DIR/$(basename $URL)" -C /opt/microsoft/powershell/7
    chmod +x /opt/microsoft/powershell/7/pwsh
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
  fi
  # remove temporary dir
  rm -fr "$TMP_DIR"
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
    # create temporary dir for the downloaded binary
    TMP_DIR=$(mktemp -dp "$PWD")
    # calculate download uri
    URL="https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell_${REL}-1.deb_amd64.deb"
    # download and install file
    if download_file --uri $URL --target_dir $TMP_DIR; then
      dpkg -i "$TMP_DIR/$(basename $URL)" >&2 2>/dev/null || binary=true
    fi
    # remove temporary dir
    rm -fr "$TMP_DIR"
  fi
  ;;
*)
  binary=true
  ;;
esac

if [ "$binary" = true ] && [ -n "$REL" ]; then
  echo 'Installing from binary.' >&2
  [ "$SYS_ID" = 'opensuse' ] && zypper in -y libicu >&2 2>/dev/null || true
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -dp "$PWD")
  # calculate download uri
  URL="https://github.com/PowerShell/PowerShell/releases/download/v${REL}/powershell-${REL}-linux-x64.tar.gz"
  # download and install file
  if download_file --uri $URL --target_dir $TMP_DIR; then
    mkdir -p /opt/microsoft/powershell/7
    tar -zxf "$TMP_DIR/$(basename $URL)" -C /opt/microsoft/powershell/7
    chmod +x /opt/microsoft/powershell/7/pwsh
    [ -f /usr/bin/pwsh ] || ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
  fi
  # remove temporary dir
  rm -fr "$TMP_DIR"
fi
