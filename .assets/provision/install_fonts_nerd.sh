#!/usr/bin/env bash
: '
# https://github.com/ryanoasis/nerd-fonts/
sudo .assets/provision/install_fonts_nerd.sh --help
sudo .assets/provision/install_fonts_nerd.sh "RobotoMono"
sudo .assets/provision/install_fonts_nerd.sh --uninstall "RobotoMono"
sudo .assets/provision/install_fonts_nerd.sh --version
'
__ScriptVersion='0.1'

if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
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

if [ -n "$1" ]; then
  font=$1
  if [ "true" = "$UNINSTALL_FONT" ]; then
    echo "uninstalling '$font' font..." >&2
    rm -fr /usr/share/fonts/${font,,}-nf
    # rebuild font information caches
    fc-cache -f /usr/share/fonts
  else
    echo "installing '$font' font..." >&2
    # dotsource file with common functions
    . .assets/provision/source.sh
    # create temporary dir for the downloaded binary
    TMP_DIR=$(mktemp -dp "$HOME")
    # calculate download uri
    URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
    # download and install file
    if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
      unzip -q "$TMP_DIR/$(basename $URL)" -d "$TMP_DIR"
      rm -f "$TMP_DIR/*Compatible.ttf"
      mkdir -p /usr/share/fonts/${font,,}-nf
      find "$TMP_DIR" -type f -name "*.ttf" -exec cp {} /usr/share/fonts/${font,,}-nf/ \;
      # build font information caches
      fc-cache -f /usr/share/fonts/${font,,}-nf
    fi
    # remove temporary dir
    rm -fr "$TMP_DIR"
  fi
else
  printf '\e[31;1mProvide font name.\e[0m\n' >&2
  exit 1
fi
