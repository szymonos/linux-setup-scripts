#!/usr/bin/env bash
: '
.assets/provision/install_miniconda.sh
.assets/provision/install_miniconda.sh --fix_certify true
'
set -euo pipefail

if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

# parse named parameters
fix_certify=${fix_certify:-false}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="${2:-}"
  fi
  shift
done

# *conda init function.
function conda_init {
  __conda_setup="$("$HOME/miniconda3/bin/conda" 'shell.bash' 'hook' 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
      . "$HOME/miniconda3/etc/profile.d/conda.sh"
    else
      export PATH="$HOME/miniconda3/bin:$PATH"
    fi
  fi
  unset __conda_setup
}

# *Install conda.
if [ -x "$HOME/miniconda3/bin/conda" ]; then
  conda_init
else
  printf "\e[92minstalling \e[1mminiconda\e[0m\n"
  # dotsource file with common functions
  . .assets/provision/source.sh
  # create temporary dir for the downloaded binary
  TMP_DIR=$(mktemp -dp "$HOME")
  # calculate download uri
  URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
  # download and install file
  if download_file --uri "$URL" --target_dir "$TMP_DIR"; then
    bash -C "$TMP_DIR/$(basename $URL)" -u -b -p "$HOME/miniconda3" >/dev/null
  fi
  # remove temporary dir
  rm -fr "$TMP_DIR"

  # disable auto activation of the base conda environment
  conda_init
  # conda config --add channels defaults
  conda config --set auto_activate false
fi

# *Add certificates to conda base certifi.
if $fix_certify; then
  conda activate base
  .assets/provision/fix_certifi_certs.sh
  conda deactivate
fi

# *Update conda.
# accept Terms of Service for the default channel
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main >/dev/null
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r >/dev/null
# update conda and all packages in the base environment
conda update --name base --channel defaults conda --yes --update-all
conda clean --yes --all

# *Fix certificates after update.
if $fix_certify; then
  conda activate base
  .assets/provision/fix_certifi_certs.sh
  conda deactivate
fi
