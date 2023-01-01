#!/bin/bash
: '
# https://github.com/ryanoasis/nerd-fonts/
sudo .assets/provision/install_fonts_nerd.sh --help
sudo .assets/provision/install_fonts_nerd.sh "RobotoMono"
sudo .assets/provision/install_fonts_nerd.sh --uninstall "RobotoMono"
sudo .assets/provision/install_fonts_nerd.sh --version
'
__ScriptVersion='0.1'

if [[ $EUID -ne 0 ]]; then
  echo -e '\e[91mRun the script as root!\e[0m' >&2
  exit 1
fi

# usage info
usage() {
  cat <<EOF
Usage: ./install.sh [-u -v -h] FONT

General options:
  -v, --version                 Print version number and exit.
  -h, --help                    Display this help and exit.
  -u, --uninstall               Uninstall font.
EOF
}

# Print version
version() {
  echo "Nerd fonts installer v$__ScriptVersion"
}

# Parse options
optspec=":vhu-:"
while getopts "$optspec" optchar; do
  case "${optchar}" in
  # Short options
  v)
    version
    exit 0
    ;;
  h)
    usage
    exit 0
    ;;
  u)
    UNINSTALL_FONT=true
    ;;
  -)
    case "${OPTARG}" in
    # Long options
    version)
      version
      exit 0
      ;;
    help)
      usage
      exit 0
      ;;
    uninstall)
      UNINSTALL_FONT=true
      ;;
    *)
      echo "Unknown option --${OPTARG}" >&2
      usage >&2
      exit 1
      ;;
    esac
    ;;
  *)
    echo "Unknown option -${OPTARG}" >&2
    usage >&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

if [[ -n "$1" ]]; then
  font=$1
  if [ "true" = "$UNINSTALL_FONT" ]; then
    echo "uninstalling '$font' font..." >&2
    rm -fr /usr/share/fonts/${font,,}-nf
    # rebuild font information caches
    fc-cache -f /usr/share/fonts
  else
    echo "installing '$font' font..." >&2
    TMP_DIR=$(mktemp -dp "$PWD")
    http_code=$(curl -Lo /dev/null --silent -Iw '%{http_code}' "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip")
    if [[ $http_code -eq 200 ]]; then
      while [[ ! -f $TMP_DIR/$font.zip ]]; do
        curl -Lsk -o $TMP_DIR/$font.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
      done
      unzip -q $TMP_DIR/$font.zip -d $TMP_DIR
      rm -f $TMP_DIR/*Compatible.ttf
      mkdir -p /usr/share/fonts/${font,,}-nf
      cp -rf $TMP_DIR/*.ttf /usr/share/fonts/${font,,}-nf/
      rm -fr $TMP_DIR
      # build font information caches
      fc-cache -f /usr/share/fonts/${font,,}-nf
    else
      echo -e '\e[91mFont "'$font'" not found on GitHub!\e[0m' >&2
      exit 1
    fi
  fi
else
  echo -e '\e[91mProvide font name!\e[0m' >&2
  exit 1
fi
