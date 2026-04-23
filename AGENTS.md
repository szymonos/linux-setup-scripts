# Linux Setup Scripts Repository

Automation scripts for provisioning Linux systems, primarily **WSL** (Windows Subsystem for Linux).

- **Languages**: Bash 5.0+ (`.sh`), PowerShell 7.4+ (`.ps1`)
- **Supported distros**: Fedora/RHEL, Debian/Ubuntu, Arch, OpenSUSE, Alpine
- **Targets**: WSL (primary), VMs/bare-metal/distroboxes (secondary)
- **Architecture**: See `ARCHITECTURE.md` for file classification, dependency tree, and runtime layout

## Bash Portability

Scripts in the **Nix setup path** (`nix/setup.sh`, `.assets/lib/scopes.sh`, `.assets/config/bash_cfg/`) must be compatible with **bash 3.2** (macOS system default). This means:

- **No `mapfile`/`readarray`** - use `while IFS= read -r line; do arr+=("$line"); done < <(...)` instead
- **No `declare -A`** (associative arrays) - use space-delimited strings with helper functions (`scope_has`, `scope_add`, `scope_del` in `scopes.sh`)
- **No `${var,,}`/`${var^^}`** (case modification) - use `tr '[:upper:]' '[:lower:]'` instead
- **No `declare -n`** (namerefs), **no negative array indices** (`${arr[-1]}`)

Linux-only scripts (`.assets/scripts/linux_setup.sh`, `.assets/check/`, `.assets/provision/`, WSL scripts) may use bash 4+ features since they run on Linux where bash 5.x is standard.

## Key Entry Points

- `wsl/wsl_setup.ps1` - main orchestration script, runs on Windows host, calls `.assets/provision/` scripts inside WSL
- `.assets/scripts/linux_setup.sh` - provisioning from Linux host (bare-metal, VMs, WSL)
- `.assets/provision/install_*.sh` - individual tool installers (most require root)
- `.assets/setup/setup_*.sh` - configuration scripts (typically run as user)
- `.assets/provision/source.sh` - shared functions (dotsourced by other scripts)

## Tooling

- **GitHub**: `gh` CLI for PR management, issue tracking, etc.
- **Pre-commit runner**: `prek` (not `pre-commit`)
- **PowerShell**: 7.4+ - use `pwsh` command (not `powershell`)

## Before Committing

**IMPORTANT**: Always run `make lint` before every commit and fix any failures. Do not skip this step. Pre-commit hooks are configured in `.pre-commit-config.yaml`.

## Writing Style

- Never use em-dashes (U+2014) or double dashes (`--`) as punctuation; use a single dash (`-`) instead.
- The gremlins pre-commit hook rejects Unicode characters like em-dashes.

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

### Runnable examples block

Every executable `.sh` and `.zsh` script must have a `: '...'` block immediately after the shebang. This lets the user run any example with the IDE "run current line" shortcut. Rules:

- Use `# comment` lines to describe what the next example does
- The following line must be the bare runnable command - no `Usage:`, `Example:`, or any other prefix
- Never put prose descriptions or text with embedded single quotes inside the block (single quotes cannot be escaped inside `'...'`; move such text to `#` comments before the block)

```bash
#!/usr/bin/env bash
: '
# run as current user
.assets/setup/setup_foo.sh
# run with a specific option
.assets/setup/setup_foo.sh --option value
'
set -euo pipefail
```

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
