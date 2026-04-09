# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Universal, cross-platform system configuration and developer environment setup. Installs and configures base system tools (ripgrep, eza, bat, fzf), development toolchains (Python/uv, Node.js/Bun, shell scripting), shell prompt customization (oh-my-posh), and common aliases across shells.

**Platforms:**

- **macOS** - via `nix/setup.sh` (primary path)
- **Linux** (Debian/Ubuntu, Fedora/RHEL, OpenSUSE; Arch/Alpine have reduced support) - via `nix/setup.sh` or `linux_setup.sh`
- **WSL** (Windows Subsystem for Linux) - via `wsl/wsl_setup.ps1` on the Windows host
- **Coder / rootless environments** - `nix/setup.sh` works without root access

**Languages**: Bash 5.0+ (`.sh`), PowerShell 7.4+ (`.ps1`)

## Setup Paths

### Primary: Nix (`nix/setup.sh`)

The preferred path for all platforms. Uses a Nix buildEnv flake for **user-scope, rootless, idempotent** package management. Nix itself must be pre-installed once (requires root); everything after runs as the user.

- Durable config lives in `~/.config/nix-env/` - persists after the repo is removed
- Run without scope flags to upgrade existing packages; add flags to install new scopes
- Scope definitions: `nix/scopes/*.nix`; flake: `nix/flake.nix`
- Post-install configuration scripts: `nix/configure/`

```bash
nix/setup.sh                                        # upgrade existing
nix/setup.sh --shell --python --pwsh --oh-my-posh  # install scopes
nix/setup.sh --all                                  # install everything
nix/setup.sh --help                                 # list all scopes/options
```

### Legacy: Traditional scripts (`linux_setup.sh`)

Per-distro installers under `.assets/provision/install_*.sh` (most require root). Distro is detected at runtime from `os-release`. Used for bare-metal Linux and VM provisioning.

### WSL: Windows host orchestration (`wsl/wsl_setup.ps1`)

Runs on the Windows host; creates/configures WSL distros and calls either the Nix or traditional path inside WSL.

## Architecture

**Scope system**: users select feature sets (e.g., `shell`, `python`, `k8s_base`, `pwsh`). Scope logic and dependency resolution are in `.assets/lib/scopes.sh`; canonical definitions in `.assets/lib/scopes.json`. The Nix path uses the same scope names with package lists in `nix/scopes/*.nix`.

**Key shared files:**

- `.assets/lib/scopes.sh` - scope parsing, dependency resolution, `resolve_scope_deps` / `sort_scopes`
- `.assets/provision/source.sh` - shared Bash functions, dot-sourced by provision scripts
- `.assets/setup/setup_common.sh` - post-install setup (copilot, zsh plugins, PS modules, pixi)

**Testing**: Docker-based smoke tests in `.assets/docker/` run a full provisioning pass and verify key binaries exist in `$PATH`. End-to-end only - no unit tests.

## Key Entry Points

- `nix/setup.sh` - primary entry point (all platforms, user-scope, no root after Nix install)
- `wsl/wsl_setup.ps1` - WSL orchestration, runs on Windows host
- `.assets/scripts/linux_setup.sh` - legacy Linux provisioning (requires root)
- `.assets/provision/install_*.sh` - individual tool installers
- `.assets/setup/setup_*.sh` - user-level configuration scripts

## Common Commands

**IMPORTANT**: Always run `make lint` before every commit and fix any failures.

```bash
make lint          # Run pre-commit hooks on changed files (use before committing)
make lint-all      # Run pre-commit hooks on all files
make test          # Run all Docker smoke tests (legacy + nix)
make test-legacy   # Test .assets/scripts/linux_setup.sh in Docker
make test-nix      # Test nix/setup.sh in Docker
make help          # List all available make targets
```

**Tooling notes:**

- Pre-commit runner is `prek` (not `pre-commit`)
- Use `pwsh` for PowerShell 7.4+ (not `powershell`)
- Use `gh` CLI for GitHub operations

## Bash Style (`.sh`)

- Shebang: `#!/usr/bin/env bash`
- Indentation: **2 spaces**; line length: **120 chars max**
- Error handling: `set -euo pipefail`
- Command substitution: `$(...)`, never backticks
- Functions: `snake_case`, private: `_prefixed`; prefer `local` for function-scoped variables
- Variables: `snake_case` locals, `UPPERCASE` constants/env
- Color output: `\e[31;1m` red/error, `\e[32m` green, `\e[92m` bright green, `\e[96m` cyan/info

### Common Bash Patterns

```bash
# Distro detection
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

# Root check
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi
```

## PowerShell Style (`.ps1`)

- Indentation: **4 spaces**
- Brace style: **OTBS** - opening `{` on same line as statement, closing `}` on its own line, block body always on separate lines
- Functions: `Verb-Noun` PascalCase (approved verbs only); use parameter splatting for >3 parameters
- Parameters: `PascalCase`; local variables: `camelCase`
- Public functions require comment-based help: `.SYNOPSIS`, `.PARAMETER`, `.EXAMPLE`
- `wsl_setup.ps1` uses `$Script:rel_*` variables to cache release versions across distro loops
- For conditional/loop statements with multiple conditions, all conditions and the opening `{` must be on the same line
