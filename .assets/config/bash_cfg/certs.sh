# Cert env vars for tools that bypass the system trust store.
# Bundle files are populated by `wsl/wsl_certs_add.ps1` (Windows host)
# or by the `cert_intercept` function in functions.sh (in-distro).
#
# - ca-custom.crt: MITM proxy / private CA certs only (additive)
# - ca-bundle.crt: symlink to the system CA bundle (full trust chain)
if [ -f "$HOME/.config/certs/ca-custom.crt" ]; then
  export NODE_EXTRA_CA_CERTS="$HOME/.config/certs/ca-custom.crt"
  export UV_SYSTEM_CERTS=true
fi
if [ -f "$HOME/.config/certs/ca-bundle.crt" ]; then
  export REQUESTS_CA_BUNDLE="$HOME/.config/certs/ca-bundle.crt"
  export SSL_CERT_FILE="$HOME/.config/certs/ca-bundle.crt"
fi
