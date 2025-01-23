#!/usr/bin/env bash
: '
.assets/provision/install_azurecli_uv.sh
.assets/provision/install_azurecli_uv.sh --fix_certify true
'
if [ $EUID -eq 0 ]; then
  printf '\e[31;1mDo not run the script as root.\e[0m\n' >&2
  exit 1
fi

# parse named parameters
fix_certify=${fix_certify:-false}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# check if uv installed
[ -x "$HOME/.local/bin/uv" ] || exit 0

# create pyproject.toml in the $HOME/.azure directory
mkdir -p "$HOME/.azure"
cat <<EOF >$HOME/.azure/pyproject.toml
[project]
name = "azurecli"
version = "1.0.0"
requires-python = ">=3.12.8,<3.13"
dependencies = [
  "azure-cli",
  "certifi",
  "idna",
  "oauthlib",
  "pip",
  "pycparser",
  "requests_oauthlib",
  "setuptools",
  "wrapt",
]

[tool.uv]
prerelease = "allow"
compile-bytecode = true
EOF

# install azure-cli
$HOME/.local/bin/uv sync --no-cache --upgrade --directory "$HOME/.azure"

# add certificates to azurecli certify
if $fix_certify; then
  .assets/provision/fix_azcli_certs.sh
fi

# make symbolic link to az cli
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/.azure/.venv/bin/az" "$HOME/.local/bin/"

# set dynamic install to allow preview extensions
az config set extension.dynamic_install_allow_preview=true 2>/dev/null
