#!/usr/bin/env bash
: '
https://docs.cloud.google.com/sdk/docs/install-sdk

sudo .assets/provision/install_gcloud.sh >/dev/null
'
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# determine system id
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
readonly APP='google-cloud-cli'
readonly BIN='gcloud'

case $SYS_ID in
alpine)
  true
  ;;
arch)
  pacman -Qqe $APP &>/dev/null && exit 0 || true
  ;;
fedora)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
debian | ubuntu)
  dpkg -s $APP &>/dev/null && exit 0 || true
  ;;
opensuse)
  rpm -q $APP &>/dev/null && exit 0 || true
  ;;
esac

# dotsource file with common functions
. .assets/provision/source.sh

# fetches the latest Google Cloud CLI version from the rapid channel metadata
get_latest_gcloud_version() {
  local metadata_uri='https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json'
  if ! command -v curl &>/dev/null; then
    printf '\e[31mThe curl command is required to determine the latest Google Cloud CLI release.\e[0m\n' >&2
    exit 1
  fi
  if ! command -v jq &>/dev/null; then
    printf '\e[31mThe jq command is required to parse the Google Cloud CLI release metadata.\e[0m\n' >&2
    exit 1
  fi
  curl -fsSL "$metadata_uri" | jq -r '.version'
}

# installs Google Cloud CLI from the official tarball when a package manager is unavailable
install_from_tarball() {
  local version="$1"
  local gcloud_dir='google-cloud-sdk'
  local install_dir='/usr/local'
  local archive_name
  local url
  local tmp_dir

  if [ -n "$version" ]; then
    archive_name="google-cloud-cli-${version}-linux-x86_64.tar.gz"
  else
    archive_name='google-cloud-cli-linux-x86_64.tar.gz'
  fi
  url="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${archive_name}"
  tmp_dir="$(mktemp -dp "$HOME")"

  printf '\e[33mFalling back to the official Google Cloud CLI tarball.\e[0m\n' >&2
  if ! download_file --uri "$url" --target_dir "$tmp_dir"; then
    rm -rf "$tmp_dir"
    printf '\e[31mFailed to download the Google Cloud CLI archive.\e[0m\n' >&2
    exit 1
  fi

  tar -zxf "$tmp_dir/$archive_name" -C "$tmp_dir"
  rm -rf "$install_dir/$gcloud_dir"
  mkdir -p "$install_dir"
  mv "$tmp_dir/$gcloud_dir" "$install_dir" >/dev/null

  CLOUDSDK_CORE_DISABLE_PROMPTS=1 "$install_dir/$gcloud_dir/install.sh" \
    --quiet \
    --path-update false \
    --bash-completion false \
    --rc-path /dev/null >/dev/null

  ln -sf "$install_dir/$gcloud_dir/bin/gcloud" /usr/bin/gcloud
  ln -sf "$install_dir/$gcloud_dir/bin/gsutil" /usr/bin/gsutil
  ln -sf "$install_dir/$gcloud_dir/bin/bq" /usr/bin/bq

  rm -rf "$tmp_dir"
  printf '\e[32mInstalled Google Cloud CLI from tarball.\e[0m\n' >&2
}

REL="${1:-}"
if [ -z "$REL" ]; then
  REL="$(get_latest_gcloud_version)"
  if [ -z "$REL" ]; then
    printf "\e[31mFailed to get the latest version of $APP.\e[0m\n" >&2
    exit 1
  fi
fi
# return the release
echo "$REL"

if command -v "$BIN" &>/dev/null; then
  VER="$("$BIN" version 2>/dev/null | sed -En 's/Google Cloud SDK ([0-9\.]+).*/\1/p' | head -n 1 || true)"
  if [ "$REL" = "$VER" ]; then
    printf "\e[32m$APP v$VER is already latest\e[0m\n" >&2
    exit 0
  fi
fi

printf "\e[92minstalling \e[1m$APP\e[0m\n" >&2

pkg_install=false
binary_install=false

case "$SYS_ID" in
alpine)
  binary_install=true
  ;;
arch)
  if pacman -Sy --needed --noconfirm "$APP" >&2; then
    pkg_install=true
  else
    binary_install=true
  fi
  ;;
fedora)
  cat <<'EOF' >/etc/yum.repos.d/google-cloud-cli.repo
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el10-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key-v10.gpg
EOF
  if dnf makecache --refresh >&2 && dnf install -y "$APP" >&2; then
    pkg_install=true
  else
    [ -f /etc/yum.repos.d/google-cloud-cli.repo ] && rm -f /etc/yum.repos.d/google-cloud-cli.repo
    binary_install=true
  fi
  ;;
debian | ubuntu)
  export DEBIAN_FRONTEND=noninteractive
  apt-get update >&2
  if apt-get install -y apt-transport-https ca-certificates gnupg >&2; then
    install -d -m 0755 /usr/share/keyrings
    if [ ! -f /usr/share/keyrings/cloud.google.gpg ]; then
      curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    fi
    cat <<'EOF' >/etc/apt/sources.list.d/google-cloud-cli.list
deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main
EOF
    chmod 644 /usr/share/keyrings/cloud.google.gpg /etc/apt/sources.list.d/google-cloud-cli.list
    if apt-get update >&2 && apt-get install -y "$APP" >&2; then
      pkg_install=true
    else
      [ -f /etc/apt/sources.list.d/google-cloud-cli.list ] && rm -f /etc/apt/sources.list.d/google-cloud-cli.list
      binary_install=true
    fi
  else
    binary_install=true
  fi
  ;;
opensuse)
  # add repository with --no-check to disable metadata signature validation
  if zypper --non-interactive --quiet addrepo --no-check https://packages.cloud.google.com/yum/repos/cloud-sdk-el10-x86_64 "$APP" && \
     zypper --gpg-auto-import-keys --quiet refresh "$APP" && \
     zypper --non-interactive install -y "$APP" >&2 2>/dev/null; then
    pkg_install=true
  else
    [ -f /etc/zypp/repos.d/google-cloud-cli.repo ] && rm -f /etc/zypp/repos.d/google-cloud-cli.repo
    binary_install=true
  fi
  ;;
*)
  binary_install=true
  ;;
esac

if [ "$pkg_install" = true ]; then
  printf '\e[32mGoogle Cloud CLI installed via the system package manager.\e[0m\n' >&2
  exit 0
fi

if [ "$binary_install" = true ]; then
  install_from_tarball "$REL"
else
  printf '\e[31mUnable to determine an installation method for this distribution.\e[0m\n' >&2
  exit 1
fi
