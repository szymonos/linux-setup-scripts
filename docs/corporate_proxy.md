# Corporate Proxy and Certificate Handling

Many enterprise environments use MITM (man-in-the-middle) TLS inspection proxies that replace upstream SSL certificates with ones signed by a corporate CA. This breaks TLS verification for most developer tools (curl, git, pip, npm, az, etc.) unless the proxy's root certificate is trusted by the system and individual toolchains.

This repository handles the problem automatically in most cases and provides manual tools for the rest.

## How it works

### Automatic detection (nix path)

When `nix/setup.sh` runs, it probes `https://www.google.com` with curl. If the connection fails due to SSL verification, it assumes a MITM proxy is present and runs `cert_intercept` automatically:

```text
nix/setup.sh
  -> curl -sS https://www.google.com fails
  -> sources .assets/config/bash_cfg/functions.sh
  -> calls cert_intercept
  -> extracts intermediate/root certs from TLS chain
  -> saves to ~/.config/certs/ca-custom.crt
```

After interception, the profile setup scripts (`nix/configure/profiles.sh`, `profiles.zsh`, `profiles.ps1`) automatically:

1. Create `~/.config/certs/ca-bundle.crt` - a full CA bundle (symlink to system bundle on Linux, merged nix CAs + custom certs on macOS)
2. Add environment variable exports to shell profiles so downstream tools trust the custom certificates

### WSL path

When provisioning WSL via PowerShell, pass `-AddCertificate` to intercept and install proxy certificates system-wide:

```powershell
wsl/wsl_setup.ps1 'Ubuntu' -AddCertificate
```

This installs the intercepted root cert into the distro's system CA store (`/usr/local/share/ca-certificates/` on Debian/Ubuntu, `/etc/pki/ca-trust/source/anchors/` on Fedora).

### CI / Docker builds

The `Makefile` handles cert interception for Docker-based tests automatically. It extracts the root cert from the TLS chain and injects it into the build context:

```bash
make test-nix    # auto-intercepts root cert, injects into Docker build
make test-legacy # same
```

## Certificate storage

| Location                                 | Purpose                                                              | Created by                  |
| ---------------------------------------- | -------------------------------------------------------------------- | --------------------------- |
| `~/.config/certs/ca-custom.crt`          | User-scope PEM bundle of intercepted proxy certs only                | `cert_intercept`            |
| `~/.config/certs/ca-bundle.crt`          | Full CA bundle (system CAs + custom certs) for tools needing a chain | `nix/configure/profiles.sh` |
| `/usr/local/share/ca-certificates/*.crt` | System CA store (Debian/Ubuntu)                                      | WSL setup or manual         |
| `/etc/pki/ca-trust/source/anchors/*.crt` | System CA store (Fedora/RHEL)                                        | WSL setup or manual         |

On Linux, `ca-bundle.crt` is a symlink to the system bundle (e.g. `/etc/ssl/certs/ca-certificates.crt`), which already includes any custom certs added via `update-ca-certificates`. On macOS, it is a merged file combining the nix-provided CA bundle with the intercepted proxy certs.

## Shell functions

After setup, two functions are available in your shell for ongoing cert management:

### `cert_intercept`

Connects to one or more hosts, extracts intermediate and root certificates from the TLS chain (skipping the leaf cert), deduplicates by serial number, and appends new certs to `~/.config/certs/ca-custom.crt`.

```bash
# intercept from default host (www.google.com)
cert_intercept

# intercept from specific hosts (useful when different proxies serve different chains)
cert_intercept login.microsoftonline.com pypi.org
```

### `fixcertpy`

Patches Python's `certifi` CA bundle(s) with certs from `~/.config/certs/ca-custom.crt`. This is needed because Python (pip, requests, azure-cli, etc.) uses its own CA bundle and ignores the system store.

```bash
# auto-discover and patch all certifi bundles (venv + system pip)
fixcertpy

# patch a specific cacert.pem
fixcertpy /path/to/venv/lib/python3.12/site-packages/certifi/cacert.pem
```

Idempotent - running it twice does not duplicate certificates.

## Environment variables

The profile setup scripts automatically export environment variables into bash, zsh, and PowerShell profiles so that tools which bypass the system CA store can still verify TLS connections through a MITM proxy. Each variable is added independently based on which cert files exist at setup time:

| Variable                             | Used by              | Cert file       | Added when                        | Shells                    |
| ------------------------------------ | -------------------- | --------------- | --------------------------------- | ------------------------- |
| `NODE_EXTRA_CA_CERTS`                | Node.js, npm         | `ca-custom.crt` | `ca-custom.crt` exists            | bash, zsh, PowerShell     |
| `REQUESTS_CA_BUNDLE`                 | Python requests, pip | `ca-bundle.crt` | `ca-bundle.crt` exists            | bash, zsh, PowerShell     |
| `SSL_CERT_FILE`                      | OpenSSL-based tools  | `ca-bundle.crt` | `ca-bundle.crt` exists            | bash, zsh, PowerShell     |
| `UV_SYSTEM_CERTS`                    | uv, uvx              | n/a             | uv installed                      | bash, zsh, PowerShell     |
| `CLOUDSDK_CORE_CUSTOM_CA_CERTS_FILE` | Google Cloud CLI     | `ca-bundle.crt` | `ca-bundle.crt` exists + `gcloud` | bash, zsh, PowerShell     |
| `PREK_NATIVE_TLS`                    | prek (pre-commit)    | n/a             | always                            | Makefile only (not shell) |

`NODE_EXTRA_CA_CERTS` points at `ca-custom.crt` (proxy certs only) because Node.js already trusts system CAs and only needs the additional proxy certs. `REQUESTS_CA_BUNDLE` and `SSL_CERT_FILE` point at `ca-bundle.crt` (the full bundle) because Python and OpenSSL-based tools replace - rather than extend - their default trust store with the value of these variables. `UV_SYSTEM_CERTS` tells uv/uvx to load TLS certificates from the platform's native certificate store, so it automatically trusts any certificates in the system CA store.

All exports are guarded at runtime: the variables are only set if the cert file still exists when the shell starts.

If for some reason you need to set these manually, add to `~/.bashrc` or `~/.zshrc`:

```bash
export NODE_EXTRA_CA_CERTS="$HOME/.config/certs/ca-custom.crt"
export REQUESTS_CA_BUNDLE="$HOME/.config/certs/ca-bundle.crt"
export SSL_CERT_FILE="$HOME/.config/certs/ca-bundle.crt"
```

## Troubleshooting

**"SSL certificate problem: unable to get local issuer certificate"** (curl/git)

The proxy cert is not in the system CA store. Run `cert_intercept` and check that the cert was added. For system-wide trust (requires root):

```bash
# Debian/Ubuntu
sudo cp ~/.config/certs/ca-custom.crt /usr/local/share/ca-certificates/proxy-ca.crt
sudo update-ca-certificates

# Fedora/RHEL
sudo cp ~/.config/certs/ca-custom.crt /etc/pki/ca-trust/source/anchors/proxy-ca.crt
sudo update-ca-trust
```

**"CERTIFICATE_VERIFY_FAILED"** (Python/pip/az)

Python ignores the system CA store. Run `fixcertpy` or check that `REQUESTS_CA_BUNDLE` is set:

```bash
# check if the variable is set
echo $REQUESTS_CA_BUNDLE

# if not set, re-run setup or set manually
fixcertpy
# or
export REQUESTS_CA_BUNDLE="$HOME/.config/certs/ca-bundle.crt"
```

### Pre-commit hooks fail with SSL errors

The `Makefile` sets `PREK_NATIVE_TLS=1` and `NODE_EXTRA_CA_CERTS` automatically. If running hooks outside of `make`, set these variables yourself.
