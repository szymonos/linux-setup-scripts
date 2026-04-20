# Architecture

Concise reference for repo structure, file ownership, and runtime layout. Read this before making global or
cross-cutting changes.

## Setup paths

| Path   | Entry point                      | Platforms                | Requirements                   |
| ------ | -------------------------------- | ------------------------ | ------------------------------ |
| Nix    | `nix/setup.sh`                   | macOS, Linux, WSL, Coder | User-scope, bash 3.2 + BSD sed |
| Legacy | `.assets/scripts/linux_setup.sh` | Linux                    | Root, bash 4+                  |
| WSL    | `wsl/wsl_setup.ps1`              | Windows host             | Admin, PowerShell 7.4+         |

## File classification

### nix-path (bash 3.2 + BSD compatible required)

Everything sourced or called by `nix/setup.sh`, plus shell config files that get sourced at login on macOS.

| File                                         | Role                                                           |
| -------------------------------------------- | -------------------------------------------------------------- |
| `nix/setup.sh`                               | Main entry point (slim orchestrator, sources phase libraries)  |
| `nix/lib/io.sh`                              | Side-effect wrappers + output helpers (tests override these)   |
| `nix/lib/phases/bootstrap.sh`                | Root guard, path resolution, nix/jq detection, arg parsing     |
| `nix/lib/phases/platform.sh`                 | OS detection, overlay discovery, hook runner                   |
| `nix/lib/phases/scopes.sh`                   | Load/merge scopes, resolve deps, write config.nix              |
| `nix/lib/phases/nix_profile.sh`              | Flake update, nix profile upgrade, MITM probe                  |
| `nix/lib/phases/configure.sh`                | GitHub CLI auth, git config, per-scope configure dispatch      |
| `nix/lib/phases/profiles.sh`                 | Bash/zsh/PowerShell shell profile setup                        |
| `nix/lib/phases/post_install.sh`             | Common post-install setup and nix garbage collection           |
| `nix/lib/phases/summary.sh`                  | Mode detection and final status output                         |
| `.assets/lib/scopes.sh`                      | Scope helpers (sourced by `nix/setup.sh` and `linux_setup.sh`) |
| `.assets/lib/scopes.json`                    | Scope definitions (read by `scopes.sh` via jq)                 |
| `.assets/lib/install_record.sh`              | Install provenance writer (sourced by all entry points)        |
| `nix/configure/az.sh`                        | Configure azure-cli                                            |
| `nix/configure/conda.sh`                     | Configure conda                                                |
| `nix/configure/docker.sh`                    | Configure docker                                               |
| `nix/configure/gh.sh`                        | Configure GitHub CLI                                           |
| `nix/configure/git.sh`                       | Configure git                                                  |
| `nix/configure/omp.sh`                       | Configure oh-my-posh                                           |
| `nix/configure/profiles.sh`                  | Copy bash configs to `~/.config/bash/`                         |
| `nix/configure/profiles.zsh`                 | Copy zsh configs (zsh, not bash, but runs on macOS)            |
| `nix/configure/profiles.ps1`                 | Copy PowerShell configs to `~/.config/powershell/`             |
| `nix/configure/starship.sh`                  | Configure starship prompt                                      |
| `.assets/lib/profile_block.sh`               | Managed block library (sourced by profiles.sh/.zsh, nx)        |
| `.assets/lib/env_block.sh`                   | Generic env block (sourced by profiles, setup_profile_user)    |
| `.assets/lib/certs.sh`                       | CA bundle builder + VS Code Server cert setup                  |
| `.assets/lib/nx_doctor.sh`                   | Health check script (`nx doctor`)                              |
| `.assets/config/bash_cfg/aliases_nix.sh`     | Shell config - nix aliases (copied to `~/.config/bash/`)       |
| `.assets/config/bash_cfg/aliases_git.sh`     | Shell config - git aliases                                     |
| `.assets/config/bash_cfg/aliases_kubectl.sh` | Shell config - kubectl aliases                                 |
| `.assets/config/bash_cfg/functions.sh`       | Shell config - shared functions (includes `devenv`)            |
| `.assets/setup/setup_common.sh`              | Post-install setup (called via `nix/setup.sh`)                 |
| `.assets/setup/setup_profile_user.ps1`       | PowerShell user profile (devenv, certs, local-path, etc.)      |
| `.assets/provision/install_copilot.sh`       | Post-install - GitHub Copilot CLI                              |
| `nix/uninstall.sh`                           | Removes nix-env environment, optionally Nix itself             |

### linux-only (bash 4+ OK)

Scripts that only run on Linux where bash 5.x is the standard.

| File / Pattern                            | Role                                           |
| ----------------------------------------- | ---------------------------------------------- |
| `.assets/scripts/linux_setup.sh`          | Legacy entry point                             |
| `.assets/provision/source.sh`             | Shared functions for provision scripts         |
| `.assets/provision/install_*.sh`          | Individual tool installers (60+ scripts, root) |
| `.assets/provision/upgrade_system.sh`     | System upgrade                                 |
| `.assets/setup/setup_profile_allusers.sh` | Copies configs to `/etc/profile.d/`            |
| `.assets/setup/setup_profile_user.sh`     | User bash profile setup                        |
| `.assets/setup/setup_profile_user.zsh`    | User zsh profile setup                         |
| `.assets/setup/setup_*.sh`                | Other setup scripts                            |
| `.assets/check/*.sh`                      | System checks                                  |
| `.assets/fix/*.sh`                        | One-off fixes                                  |
| `.assets/config/bash_cfg/aliases.sh`      | Legacy aliases (copied to `/etc/profile.d/`)   |

### powershell

| File / Pattern                             | Role                          |
| ------------------------------------------ | ----------------------------- |
| `wsl/*.ps1`                                | WSL management (Windows host) |
| `.assets/config/pwsh_cfg/_aliases_nix.ps1` | PowerShell nix aliases        |
| `.assets/config/pwsh_cfg/profile_nix.ps1`  | Base profile template         |
| `modules/InstallUtils/`                    | Install utility module        |
| `modules/SetupUtils/`                      | Setup utility module          |

### nix declarations (not bash)

| File / Pattern     | Role                   |
| ------------------ | ---------------------- |
| `nix/flake.nix`    | buildEnv flake         |
| `nix/scopes/*.nix` | 19 scope package lists |

### tests

| File / Pattern                 | Role                                         |
| ------------------------------ | -------------------------------------------- |
| `tests/bats/*.bats`            | bats-core unit tests                         |
| `tests/pester/*.Tests.ps1`     | Pester unit tests                            |
| `tests/hooks/*.py`             | Pre-commit hook scripts                      |
| `.github/workflows/test_*.yml` | Integration tests (see "CI pipelines" below) |

## Nix-path call tree

```text
nix/setup.sh                                      (orchestrator, ~110 lines)
  sources nix/lib/io.sh                            (output helpers + side-effect wrappers)
  sources nix/lib/phases/bootstrap.sh              (root guard, paths, nix/jq detect, arg parse)
  sources nix/lib/phases/platform.sh               (OS detect, overlay, hooks)
  sources nix/lib/phases/scopes.sh                 (load/merge/resolve scopes, write config.nix)
  sources nix/lib/phases/nix_profile.sh            (flake update, profile upgrade, MITM probe)
  sources nix/lib/phases/configure.sh              (gh/git/per-scope configure dispatch)
  sources nix/lib/phases/profiles.sh               (bash/zsh/pwsh profile setup)
  sources nix/lib/phases/post_install.sh           (setup_common.sh + nix GC)
  sources nix/lib/phases/summary.sh                (mode detect + final output)
  sources .assets/lib/install_record.sh            (EXIT trap provenance)
  sources .assets/lib/scopes.sh -> reads .assets/lib/scopes.json
  calls (via _io_run):
    nix/configure/gh.sh
    nix/configure/git.sh
    nix/configure/docker.sh      (if scope: docker)
    nix/configure/conda.sh       -> sources functions.sh
    nix/configure/az.sh          -> calls install_azurecli_uv.sh
    nix/configure/omp.sh         -> reads .assets/config/omp_cfg/
    nix/configure/starship.sh    -> reads .assets/config/starship_cfg/
    nix/configure/profiles.sh    -> sources profile_block.sh + env_block.sh + certs.sh, copies bash_cfg/
    nix/configure/profiles.zsh   -> sources profile_block.sh + env_block.sh + certs.sh, copies bash_cfg/
    nix/configure/profiles.ps1   -> copies pwsh_cfg/ to ~/.config/powershell/
    .assets/setup/setup_common.sh
      calls install_copilot.sh
      calls setup_profile_user.zsh     (if scope: zsh)
      calls setup_profile_user.ps1     (if pwsh available, writes devenv + certs + local-path)
```

## Runtime file locations

### User-scope durable state (`~/.config/nix-env/`)

Persists after the repo is removed. This is the user's nix environment.

| Runtime file         | Source                                    | Created by                   |
| -------------------- | ----------------------------------------- | ---------------------------- |
| `flake.nix`          | `nix/flake.nix`                           | `nix/setup.sh`               |
| `scopes/*.nix`       | `nix/scopes/*.nix`                        | `nix/setup.sh`               |
| `config.nix`         | generated                                 | `nix/setup.sh` or `nx scope` |
| `packages.nix`       | generated                                 | `nx install` / `nx remove`   |
| `omp/theme.omp.json` | `.assets/config/omp_cfg/`                 | `nix/configure/omp.sh`       |
| `profile_base.ps1`   | `.assets/config/pwsh_cfg/profile_nix.ps1` | `nix/configure/profiles.ps1` |
| `nx_doctor.sh`       | `.assets/lib/nx_doctor.sh`                | `nix/setup.sh`               |

### Hook directories (`~/.config/nix-env/hooks/`)

Not created automatically. Users create these directories when they have hooks to run. Hook files (`*.sh`) are
sourced in lexical order.

| Directory       | When                    | Variables available                              |
| --------------- | ----------------------- | ------------------------------------------------ |
| `pre-setup.d/`  | Before scope resolution | `NIX_ENV_VERSION`, `NIX_ENV_PLATFORM`, `ENV_DIR` |
| `post-setup.d/` | After profile config    | All above + `NIX_ENV_SCOPES`                     |

`NIX_ENV_PHASE` is exported as `pre-setup` or `post-setup` so hooks can verify which phase they're running in.

### Overlay directory (`~/.config/nix-env/local/` or `$NIX_ENV_OVERLAY_DIR`)

Local customization layer. Discovery order: `$NIX_ENV_OVERLAY_DIR` (if set and exists), then
`~/.config/nix-env/local/`. Not created automatically.

| Path            | Purpose                                          |
| --------------- | ------------------------------------------------ |
| `scopes/*.nix`  | Extra nix packages (copied as `local_*.nix`)     |
| `bash_cfg/*.sh` | Extra shell config (copied to `~/.config/bash/`) |

Overlay scope files are prefixed with `local_` when copied to `~/.config/nix-env/scopes/` to avoid collisions with
base scope names. The flake reads all `*.nix` from the scopes directory, so overlay packages are included
automatically.

**CLI commands:**

- `nx overlay list` -- show active overlay directory and its contents (scopes, shell config, hooks).
- `nx overlay status` -- show sync status of overlay files (synced, modified, source missing) by comparing overlay
  source with installed copies.
- `nx scope add <name>` -- create a stub `.nix` file in the overlay directory, copy it to
  `scopes/local_<name>.nix`, and register it in `config.nix`.

### Shell config (`~/.config/bash/`)

Sourced by `~/.bashrc` and `~/.zshrc` on all platforms including macOS.

| Runtime file         | Source                                       |
| -------------------- | -------------------------------------------- |
| `aliases_nix.sh`     | `.assets/config/bash_cfg/aliases_nix.sh`     |
| `aliases_git.sh`     | `.assets/config/bash_cfg/aliases_git.sh`     |
| `aliases_kubectl.sh` | `.assets/config/bash_cfg/aliases_kubectl.sh` |
| `functions.sh`       | `.assets/config/bash_cfg/functions.sh`       |

### PowerShell config (`~/.config/powershell/`)

| Runtime file               | Source                                     |
| -------------------------- | ------------------------------------------ |
| `Scripts/_aliases_nix.ps1` | `.assets/config/pwsh_cfg/_aliases_nix.ps1` |

### Legacy system-scope (`/etc/profile.d/`, root required)

Used only by the legacy path (`setup_profile_allusers.sh`). Not used on macOS.

| Runtime file         | Source                                       |
| -------------------- | -------------------------------------------- |
| `aliases.sh`         | `.assets/config/bash_cfg/aliases.sh`         |
| `aliases_git.sh`     | `.assets/config/bash_cfg/aliases_git.sh`     |
| `aliases_kubectl.sh` | `.assets/config/bash_cfg/aliases_kubectl.sh` |
| `functions.sh`       | `.assets/config/bash_cfg/functions.sh`       |

### Installation provenance (`~/.config/dev-env/`)

Written on every setup run (success or failure) by an EXIT trap (bash) or `clean` block (PowerShell). Records entry
point, scopes, status, and phase.

| Runtime file   | Created by                                                          |
| -------------- | ------------------------------------------------------------------- |
| `install.json` | EXIT trap in `nix/setup.sh`, `linux_setup.sh`, or WSL `clean` block |

The `entry_point` field distinguishes how setup was invoked:

| Value        | Meaning                                      |
| ------------ | -------------------------------------------- |
| `nix`        | `nix/setup.sh` run directly                  |
| `legacy`     | `linux_setup.sh` with traditional installers |
| `legacy/nix` | `linux_setup.sh` delegating to nix           |
| `wsl/nix`    | `wsl_setup.ps1` using nix path               |
| `wsl/legacy` | `wsl_setup.ps1` using traditional path       |

### Certificate store (`~/.config/certs/`)

Created by the corporate proxy certificate interception flow. See `docs/corporate_proxy.md` for operational
details.

| Runtime file    | Created by                      | Purpose                          |
| --------------- | ------------------------------- | -------------------------------- |
| `ca-custom.crt` | `cert_intercept` (functions.sh) | Intercepted proxy certs only     |
| `ca-bundle.crt` | `build_ca_bundle` (certs.sh)    | Full CA bundle (system + custom) |

## Environment variables

Variables exported by `nix/setup.sh` for use by hooks, downstream scripts, and diagnostic tools (`nx doctor`).

| Variable                | Set by     | When                         | Purpose                                      |
| ----------------------- | ---------- | ---------------------------- | -------------------------------------------- |
| `NIX_ENV_VERSION`       | `setup.sh` | After script root resolution | Tool version (git tag/tarball)               |
| `NIX_ENV_SCOPES`        | `setup.sh` | After scope resolution       | Space-separated resolved scopes              |
| `NIX_ENV_TLS_PROBE_URL` | `certs.sh` | On source                    | TLS probe URL for MITM detection (see below) |

`NIX_ENV_VERSION` uses a three-step fallback: `git describe --tags --dirty`, then a `VERSION` file (present in
release tarballs, absent in the repo), then `"unknown"`. The same chain is used by `install_record.sh` for
provenance.

## Nixpkgs pinning (`nx pin`)

The file `~/.config/nix-env/pinned_rev` controls whether upgrades resolve the latest `nixpkgs-unstable` or lock to
a specific commit. Managed via `nx pin set <rev>`, `nx pin remove`, `nx pin show`.

When the file exists and contains a commit SHA, `setup.sh --upgrade` and `nx upgrade` use
`nix flake lock --override-input` to pin nixpkgs to that revision. When absent, upgrades resolve the latest
unstable HEAD as before.

Useful for reproducible builds or fleet-wide cohort pinning without shipping a repo-level `flake.lock`.

## Diagnostics (`nx doctor`)

`nx doctor` runs read-only health checks against the nix-env managed environment. Implemented in
`.assets/lib/nx_doctor.sh`, copied to `~/.config/nix-env/nx_doctor.sh` during setup so it remains available after
the repo is removed.

**Checks:**

| Check            | Pass                                          | Fail/Warn                        |
| ---------------- | --------------------------------------------- | -------------------------------- |
| `nix_available`  | `nix` in PATH                                 | FAIL: nix not found              |
| `flake_lock`     | `flake.lock` exists, nixpkgs node valid       | FAIL: missing; WARN: unreadable  |
| `install_record` | `install.json` exists, status=success         | WARN: missing or last run failed |
| `scope_binaries` | All `# bins:` binaries from scope files found | WARN: lists missing binaries     |
| `shell_profile`  | Exactly 1 managed block per rc file           | FAIL: zero or duplicates         |
| `cert_bundle`    | Custom CA bundle + VS Code env OK             | FAIL: bundle or env missing      |
| `nix_profile`    | `nix-env` in `nix profile list`               | FAIL: not found                  |
| `overlay_dir`    | `NIX_ENV_OVERLAY_DIR` readable (if set)       | FAIL: not a readable directory   |

**Binary names** are declared in each scope's `.nix` file via a `# bins:` comment (e.g. `# bins: rg yq fzf`). This
is the single source of truth - `validate_scopes.py` enforces that every scope file has one.

## CI pipelines and validated targets

GitHub Actions workflows under `.github/workflows/` encode which deployment targets are actually tested. Each
matrix entry maps to a real-world install scenario; passing the job is the compatibility guarantee for that
scenario.

| Workflow           | Runner / Matrix            | Scenario it validates                                                                           |
| ------------------ | -------------------------- | ----------------------------------------------------------------------------------------------- |
| `test_linux.yml`   | `ubuntu-slim`, `daemon`    | Multi-user Nix install (WSL, bare-metal Linux, managed macOS via equivalent path).              |
| `test_linux.yml`   | `ubuntu-slim`, `no-daemon` | Single-user rootless Nix install. Covers Coder / devcontainer (no systemd, no root at runtime). |
| `test_macos.yml`   | `macos-14` (default), `15` | Apple Silicon macOS via Determinate installer. Validates bash 3.2 + BSD sed constraints.        |
| `repo_checks.yml`  | pre-commit hooks           | `check_bash32`, `validate_scopes`, ShellCheck, lint.                                            |
| `build_docker.yml` | container build            | Docker image for legacy path (not nix).                                                         |

**Test-per-run assertions** (both integration workflows):

- `setup.sh` completes with requested scope flags (`--shell --python` default).
- Core binaries (`git`, `gh`, `jq`, `curl`, `openssl`) resolve on PATH.
- Scope-specific binaries resolve (mapped from scope flags).
- `# >>> nix-env managed >>>` block exists in `~/.bashrc` exactly once.
- Second `setup.sh` invocation produces exactly one managed block (idempotency).
- `install.json` written with `status = "success"`.
- `bats tests/bats/test_nix_setup.bats` passes.
- `nix/uninstall.sh --env-only` removes nix-env state, preserves generic
  `managed env` block, leaves `/nix/store` intact.

**Triggers:** manual (`workflow_dispatch` with scope override), PR label (`test:linux` / `test:macos`), or push to
an already-labeled PR.

**WSL end-to-end testing (intentionally omitted):** `wsl_setup.ps1` orchestration is not tested in CI. GitHub-hosted Windows runners only support WSL1 (no nested virtualization for WSL2), which lacks systemd and behaves differently from production WSL2 environments. A self-hosted Windows runner with WSL2 would work but cannot be ephemeral, making the maintenance cost disproportionate to the coverage gained. The orchestration logic is already validated by Pester unit tests (`tests/pester/WslSetup.Tests.ps1`) that mock `wsl.exe` and verify script dispatch for all scope/mode combinations.

## Design decisions

### nixpkgs-unstable with explicit upgrade semantics

The flake input is `nixpkgs-unstable` - intentional, not an oversight. The target audience values "reasonably
current" tooling over point-in-time reproducibility. The binary cache GCs old revisions, so a pinned lock older
than ~6 weeks risks cold source builds anyway.

To avoid silent breakage, `setup.sh` does **not** implicitly run `nix flake update` on scope-only changes. The
upgrade path is explicit:

- `nix/setup.sh` (first run) - resolves `unstable` HEAD, writes `$ENV_DIR/flake.lock`.
- `nix/setup.sh` (subsequent) - re-uses existing lock, applies scope changes only.
- `nix/setup.sh --upgrade` - explicit: updates `flake.lock` to latest nixpkgs, then upgrades.
- `nx upgrade` - same as above but from the shell alias (runs `nix flake update` + `nix profile upgrade`).
- `nx rollback` - wraps `nix profile rollback`.

No repo-level `flake.lock` is shipped. The per-user lock in `$ENV_DIR` gives run-to-run reproducibility on one
machine. Enterprise pinning via `NIX_ENV_PINNED_REV` env var when/if an SBOM requirement appears.

### Dual prompt engines (oh-my-posh + starship)

Both are kept intentionally - they serve different environments:

- **oh-my-posh** (Go, more mature, richer themes) - default for macOS and WSL where startup latency is less
  critical.
- **starship** (Rust, faster cold-start) - preferred on Coder where container startup time matters and resource
  budgets are tighter.

The scopes are mutually exclusive at runtime (`--omp-theme` removes starship and vice versa) but both remain
available as opt-in choices.

### Dual Python managers (conda + uv)

Both are kept - conda is required by many data science and ML teams (binary package ecosystem, environment
isolation), while uv is the modern replacement for pip/venv workflows. They coexist without conflict: conda manages
its own environments, uv manages `$HOME/.local/bin` and venvs.

### `set -eo pipefail` without `-u` (nix-path files)

Nix-path scripts use `set -eo pipefail` deliberately omitting `-u` (nounset). Bash 3.2 (macOS system default)
treats `arr=()` as unset when `-u` is active, so `${#arr[@]}` on an empty array causes an "unbound variable" error.
This forced ugly counter-variable workarounds throughout the codebase.

Dropping `-u` is the right trade-off because:

- ShellCheck (run via pre-commit) already catches uninitialized variable references at lint time - a stronger guard
  than runtime `-u`.
- The counter-variable pattern actively harmed readability and introduced its own bug surface.
- `set -e` still catches most real errors from commands receiving empty args.

Linux-only scripts may use `set -euo pipefail` since they run bash 5.x where empty arrays are handled correctly.

### Corporate proxy and SSL inspection

Many enterprise environments use MITM TLS inspection proxies that replace upstream certificates. The solution
intercepts proxy certificates at setup time and configures tools via environment variables (`NODE_EXTRA_CA_CERTS`,
`REQUESTS_CA_BUNDLE`, `SSL_CERT_FILE`, `UV_SYSTEM_CERTS`). See `docs/corporate_proxy.md` for operational details.

**TLS probe URL** (`NIX_ENV_TLS_PROBE_URL`, default `https://www.google.com`): used by MITM detection
(`phase_nix_profile_mitm_probe`), SSL connectivity checks (`check_ssl.sh`), and certificate interception
(`cert_intercept`). The default is defined in `.assets/lib/certs.sh` as the single source of truth. Override via
environment variable to use an internal endpoint. The default was chosen because `www.google.com` is (a) reachable
from virtually every network that has internet access, (b) almost universally subject to MITM TLS inspection when a
proxy is present, and (c) does not depend on any project-specific infrastructure (e.g. `nixos.org` could be
allowlisted or unreachable on air-gapped networks that still have filtered internet).

Alternatives considered and why they were not adopted:

- **`pip-system-certs`** (auto-patches certifi at import time) - rejected. Must be installed in every virtualenv,
  breaks isolation guarantees, and interacts poorly with uv-managed environments where the package may not be
  present. The `fixcertpy` shell function patches certifi on demand instead - explicit, idempotent, and works
  across any Python installation.
- **`NODE_OPTIONS='--use-system-ca'`** - not adopted yet. Requires Node.js 22+ (experimental in earlier versions)
  and is not yet stable across all Node consumers (bundlers, test runners). `NODE_EXTRA_CA_CERTS` works reliably
  across all supported Node versions. Will revisit when Node 22 becomes the minimum supported LTS.
- **`UV_SYSTEM_CERTS`** - adopted (replaced deprecated `UV_NATIVE_TLS`). Tells uv/uvx to use the platform's native
  certificate store, avoiding the need to point at a specific PEM bundle.
- **System CA store installation** - handled by `wsl/wsl_certs_add.ps1` (WSL) and `cert_intercept` + manual
  `update-ca-certificates` (Linux). Not automated in the nix path because it requires root; the env-var approach
  covers user-scope tools without privilege escalation.

### Bootstrap dependency (base_init.nix)

`scopes.json` is the single source of truth for scope metadata (valid names, install order, dependency rules). It
is consumed by three runtimes:

| Consumer   | Parser                                             | Native? |
| ---------- | -------------------------------------------------- | ------- |
| bash       | `jq` via `.assets/lib/scopes.sh`                   | No      |
| PowerShell | `ConvertFrom-Json` (`modules/SetupUtils/`, `wsl/`) | Yes     |
| Python     | `json` stdlib (`tests/hooks/validate_scopes.py`)   | Yes     |

JSON was chosen because it is the only format all three parse without a custom parser. Alternatives
(bash-sourceable data, TSV, INI) would force either a fragile parallel parser in PowerShell/Python or a
source-of-truth split between bash-data and JSON-data.

The only cost is that bash 3.2 on bare macOS has no JSON parser, so jq must be bootstrapped before scope resolution
can run. This is handled by:

1. `nix/scopes/base_init.nix` - minimal package list (jq, curl) included only during bootstrap.
2. `isInit` flag in `config.nix` - set to `true` on first run when the system has no jq/curl outside Nix.
3. `flake.nix` - conditionally includes `base_init.nix` packages when `cfg.isInit` is true.
4. `nix/setup.sh:183-197` - on first run (jq not found), writes a bootstrap `config.nix` with `isInit = true` and
   empty `scopes`, then runs `nix profile add` + `nix profile upgrade` to install jq. Subsequent runs find jq and
   skip the bootstrap block entirely.

The bootstrap is ~13 lines of `setup.sh`, one `.nix` file, and one config flag. It runs once per machine (seconds),
after which jq is an ordinary Nix package and `isInit` flips to `false`.

Alternatives considered:

- **Vendored jq binary** - supply-chain concerns, per-arch packaging (macOS ARM/x86, Linux ARM/x86), not acceptable
  for corporate repos.
- **Pure-bash JSON parser** - maintenance burden, fragile on edge cases, more code than the data it would parse.
- **Different data format** (TSV, bash-sourceable, YAML) - would force the PowerShell and Python consumers to use
  non-native parsers, or split the source of truth.

### VS Code Server certificate environment

VS Code Server (remote-SSH, WSL) does not source `~/.bashrc` on startup, so shell-profile environment variables
like `NODE_EXTRA_CA_CERTS` are invisible to extensions. This causes `SELF_SIGNED_CERT_IN_CHAIN` errors in
extensions that call HTTPS APIs (GitHub Actions, GitHub Pull Requests, etc.).

The fix is `~/.vscode-server/server-env-setup` - a file VS Code Server sources before launching.
`setup_vscode_certs` in `.assets/lib/certs.sh` writes `NODE_EXTRA_CA_CERTS` there, creating the directory and file
if they don't exist. This handles the bootstrapping problem where setup runs before the first VS Code remote
session creates `~/.vscode-server/`.

This is tool-specific but VS Code is the standard editor in corporate environments where MITM proxies are common.
The same pattern applies to both WSL and remote-SSH connections.

## Phase library and test stubs (`nix/lib/`)

`nix/setup.sh` is a slim orchestrator (~110 lines) that sources phase libraries from `nix/lib/phases/`. Each phase
file exports functions prefixed with `phase_<name>_` (e.g. `phase_bootstrap_parse_args`,
`phase_scopes_write_config`).

Side-effecting operations (`nix`, `curl`, external script invocations) are called through thin wrappers defined in
`nix/lib/io.sh`:

| Wrapper          | Wraps                            |
| ---------------- | -------------------------------- |
| `_io_nix`        | `nix`                            |
| `_io_nix_eval`   | `nix eval --impure --raw --expr` |
| `_io_curl_probe` | `curl -sS <url>`                 |
| `_io_run`        | Direct command execution         |

Tests override these before sourcing phase files to assert commands without executing them:

```bash
setup() {
  _io_nix() { echo "nix $*" >>"$BATS_TEST_TMPDIR/nix.log"; }
  source "$REPO_ROOT/nix/lib/io.sh"
  source "$REPO_ROOT/nix/lib/phases/nix_profile.sh"
}
```

Shared state between phases is documented in each phase file's header comment (`# Reads:` / `# Writes:` lines).

## Bash 3.2 / BSD sed constraints (nix-path files)

All nix-path `.sh` files must avoid:

- `mapfile` / `readarray` - use `while IFS= read -r; do arr+=(); done < <(...)`
- `declare -A` (assoc arrays) - use space-delimited strings with helpers
- `${var,,}` / `${var^^}` - use `tr '[:upper:]' '[:lower:]'`
- `declare -n` (namerefs) - pass variable name as string
- Negative array index `${arr[-1]}` - use `${arr[$((${#arr[@]}-1))]}`
- `sed \s` - use `[[:space:]]`
- `sed` BRE `\+` or alternation - use `sed -E` with bare `+` or alternation
- `sed -i ''` - write to temp file + `mv`
- `sed -r` - use `sed -E`
- `grep -P` (PCRE) - use `grep -E` or `sed`
- `grep \S` / `\w` / `\d` - use `[^[:space:]]` / `[a-zA-Z0-9_]` / `[0-9]`

These constraints are enforced by the `check-bash32` pre-commit hook (`tests/hooks/check_bash32.py`).

## Managed block pattern

Shell profile injection (`~/.bashrc`, `~/.zshrc`, PowerShell `$PROFILE`) uses a **managed block** pattern instead
of `grep -q && echo >>` append. This gives idempotent, fully-regenerated, removable config injection.

**Bash/Zsh** (`profile_block.sh` - `manage_block` function):

Two blocks are written to each rc file:

- `nix-env managed` - nix-specific: PATH, nix aliases, completions, prompt init. Removed by `nix/uninstall.sh`.
- `managed env` - generic env (local PATH, cert env vars, generic aliases/functions). Not nix-specific, survives
  uninstall.

Alias files are assigned to the correct block based on how the tool was installed:

- `functions.sh` - always in `managed env` (purely generic, includes `devenv`).
- `aliases_git.sh` - in `nix-env managed` if git is from nix (`~/.nix-profile/bin/git` exists), otherwise in
  `managed env`.
- `aliases_kubectl.sh` - same logic: nix block if kubectl is from nix, otherwise generic.
- `aliases_nix.sh` - always in `nix-env managed` (nix-specific by definition).

```text
# >>> nix-env managed >>>
# :path
export PATH="$HOME/.nix-profile/bin:$PATH"
# :aliases
. "$HOME/.config/bash/aliases_nix.sh"
# :oh-my-posh
[ -x "$HOME/.nix-profile/bin/oh-my-posh" ] && eval "$(oh-my-posh init bash ...)"
# <<< nix-env managed <<<

# >>> managed env >>>
# :local path
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi
# :certs
export NODE_EXTRA_CA_CERTS="$HOME/.config/certs/ca-custom.crt"
# <<< managed env <<<
```

**PowerShell** (`profiles.ps1` - `Update-ProfileRegion` function):

Nix-managed regions use the `nix:` prefix. Generic regions (certs, conda, make completer) use unprefixed names and
are written by `setup_profile_user.ps1`. The uninstaller only removes `nix:`-prefixed regions.

```text
#region nix:base
. "$HOME/.config/nix-env/profile_base.ps1"
#endregion

#region nix:path
...
#endregion

#region certs
...
#endregion
```

Key properties:

- Block is **fully regenerated** each run (content is rendered fresh, not appended).
- `manage_block upsert` / `Update-ProfileRegion` replaces old content atomically.
- `manage_block remove` / `nx profile uninstall` cleanly removes the block.
- `nx profile doctor` detects duplicate blocks and legacy (pre-managed-block) lines.
- `nx profile migrate` converts legacy append-style injections to managed blocks.
- `nix/uninstall.sh` removes only nix-specific blocks/regions, preserving generic config.

### `devenv` command

Shows installation provenance from `~/.config/dev-env/install.json`. Available in all shells, independent of nix:

- **bash/zsh**: `devenv` function in `functions.sh` (bash 3.2 compatible, jq with `cat` fallback). Also accessible
  as `nx version`.
- **PowerShell**: `devenv` function written to `$PROFILE.CurrentUserAllHosts` by `setup_profile_user.ps1`. Returns
  a `PSCustomObject` with ANSI-colored values. Also accessible as `nx version`.
