# Linux Setup Scripts Repository

Automation scripts for provisioning Linux systems, primarily **WSL** (Windows Subsystem for Linux).

- **Languages**: Bash 5.0+ (`.sh`), PowerShell 7.4+ (`.ps1`)
- **Supported distros**: Fedora/RHEL, Debian/Ubuntu, Arch, OpenSUSE, Alpine
- **Targets**: WSL (primary), VMs/bare-metal/distroboxes (secondary)

## Key Entry Points

- `wsl/wsl_setup.ps1` - main orchestration script, runs on Windows host, calls `.assets/provision/` scripts inside WSL
- `.assets/scripts/linux_setup.sh` - provisioning from Linux host (bare-metal, VMs, WSL)
- `.assets/provision/install_*.sh` - individual tool installers (most require root)
- `.assets/provision/setup_*.sh` - configuration scripts (typically run as user)
- `.assets/provision/source.sh` - shared functions (dotsourced by other scripts)

## Tooling

- **GitHub**: `gh` CLI for PR management, issue tracking, etc.
- **Pre-commit runner**: `prek` (not `pre-commit`)
- **PowerShell**: 7.4+ - use `pwsh` command (not `powershell`)

## Before Committing

Run `make lint` and fix any failures. Pre-commit hooks are configured in `.pre-commit-config.yaml`.

## Bash Style (`.sh`)

- Shebang: `#!/usr/bin/env bash`
- Indentation: **2 spaces**
- Line length: **120 chars max**
- Error handling: `set -euo pipefail`
- Command substitution: `$(...)`, never backticks
- Functions: `snake_case`, private: `_prefixed`
- Variables: `snake_case` locals, `UPPERCASE` constants/env
- PowerShell local variables use `camelCase` (see below)
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
- Brace style: **OTBS** (opening `{` on same line, closing `}` on own line, block body always on separate lines)
- Functions: `Verb-Noun` PascalCase (approved verbs only)
- Parameters: `PascalCase`; local variables: `camelCase`
- Public functions require comment-based help (`.SYNOPSIS`, `.PARAMETER`, `.EXAMPLE`)
- `wsl_setup.ps1` uses `$Script:rel_*` variables to cache release versions across distro loops
