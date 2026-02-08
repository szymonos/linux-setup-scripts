# Linux Setup Scripts Repository

This repository contains automation scripts for provisioning and configuring Linux systems, with **primary focus on Windows Subsystem for Linux (WSL)** setup and management. Secondary functionality includes support for VMs (Vagrant), bare-metal installations, and distroboxes.

## Project Overview

**Primary Focus**: Windows Subsystem for Linux (WSL) setup and configuration  
**Main Orchestration Script**: `wsl/wsl_setup.ps1` - orchestrates the entire WSL setup process using scripts from `.assets/provision/`  
**Primary Languages**: Shell/Bash (93+ scripts), PowerShell 7.4+ (12+ scripts + 2 modules)  
**Supported Distros**: Fedora/RHEL, Debian/Ubuntu, Arch, OpenSUSE, Alpine  
**Deployment Targets**: WSL (primary), Vagrant (secondary), bare-metal Linux (secondary), distroboxes (secondary)  
**Key Features**: 60+ tool installation scripts, cross-platform PowerShell modules, oh-my-posh configurations

## Quick Reference

**WSL Setup**: Run `wsl/wsl_setup.ps1` to orchestrate complete WSL distro setup (see `docs/wsl_setup.md` for details)  
**When committing changes**: Run `prek run --all-files` to check for linting issues before committing  
**Common linting issues**: Add blank lines around markdown headings/lists/code fences, ensure proper spacing  
**Installation scripts**: Most `.assets/provision/install_*.sh` scripts require root and will install tools system-wide

## Repository Structure

```text
wsl/                # WSL-specific PowerShell management scripts (PRIMARY FOCUS)
├── wsl_setup.ps1     # MAIN ORCHESTRATION SCRIPT - orchestrates entire WSL setup
├── wsl_install.ps1   # Install WSL distros
├── wsl_*.ps1         # Other WSL management utilities (12 files total)
.assets/            # All helper scripts and assets
├── provision/      # Core provisioning scripts (60+ installation/setup scripts)
│                     # Used by wsl_setup.ps1 for installing tools and configuring system
├── config/         # Shell configurations (bash, pwsh, oh-my-posh)
├── scripts/        # Utility scripts (linux_setup.sh for bare-metal/VM setup)
├── docker/         # Dockerfiles (standard + Alpine)
├── playbooks/      # Ansible playbooks (4 files)
├── tools/          # Benchmarking tools
└── trigger/        # External trigger scripts
modules/            # PowerShell modules (InstallUtils, SetupUtils)
vagrant/            # Vagrant configurations (secondary functionality)
docs/               # Documentation (wsl_setup.md, vagrant.md, etc.)
```

## Build/Test Commands

**Note**: This repository uses pre-commit hooks configured in the `.pre-commit-config.yaml` file.  
You may get pre-commit hook errors while committing changes that need to be resolved before proceeding.  

### Pre-commit Hooks

The repository uses pre-commit hooks to enforce code quality and consistency. The hooks are defined in the `.pre-commit-config.yaml` file and include:

- [pre-commit/pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks)
  - check-executables-have-shebangs  
    Checks that non-binary executables have a proper shebang.
  - check-shebang-scripts-are-executable  
    Checks that scripts with shebangs are executable.
  - end-of-file-fixer  
    Makes sure files end in a newline and only a newline.
  - mixed-line-ending  
    Replaces or checks mixed line ending.
  - trailing-whitespace  
    Trims trailing whitespace.
    - exclude: `*.md` files (double trailing whitespace is used for line breaks in Markdown)
- [DavidAnson/markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2)
  - markdownlint-cli2  
    A fast, flexible, configuration-based command-line interface for linting Markdown/CommonMark files with the markdownlint library.
    - exclude: `/copilot-instructions.md`
- [koalaman/shellcheck-precommit](https://github.com/koalaman/shellcheck-precommit)
  - shellcheck  
    A static analysis tool for shell scripts. It provides warnings and suggestions for bash/sh shell scripts.
    - exclude: `*.zsh` files (ShellCheck doesn't support zsh)
- [hooks/gremlins](tests/hooks/gremlins.py):
  - gremlins-check  
    Detect gremlins / unwanted Unicode characters.  
    Inspired by [Gremlins tracker for Visual Studio Code](https://github.com/nhoizey/vscode-gremlins)

**Exclusions**:

- markdownlint: `/copilot-instructions.md`
- shellcheck: `*.zsh` files (ShellCheck doesn't support zsh)
- trailing-whitespace: `*.md` files

**Common fixes needed**:

- Markdownlint MD022: Add blank line before/after headings
- Markdownlint MD031: Add blank line before/after code fences
- Markdownlint MD032: Add blank line before/after lists
- Markdownlint MD040: Specify language for fenced code blocks

### Development Workflow

1. Make code changes following the style guidelines below
2. Run `prek run --all-files` to validate changes
3. Fix any reported issues (agents should fix these automatically)
4. Commit changes (pre-commit hooks will run automatically if installed)

### Docker Build

```bash
# Build Docker image
.assets/docker/build_docker.sh

# GitHub Actions handles automated Docker builds (see .github/workflows/build_docker.yml)
```

### Vagrant Testing

**Note**: Vagrant tests are not required as Vagrant development has been stopped.

### Shell Script Testing

```bash
# Test individual installation scripts (most require root)
sudo .assets/provision/install_kubectl.sh

# Test without output
sudo .assets/provision/install_kubectl.sh >/dev/null

# Test with specific version
sudo .assets/provision/install_terraform.sh 1.6.0
```

### PowerShell Module Testing

```powershell
# Import modules for testing
Import-Module ./modules/InstallUtils/InstallUtils.psd1
Import-Module ./modules/SetupUtils/SetupUtils.psd1

# Test specific functions
Get-Command -Module InstallUtils, SetupUtils
```

## Code Style Guidelines

### Shell/Bash Scripts (**.sh)

#### Formatting

- **Target**: Bash 5.0+, POSIX-compliant, cross-distro compatible
- **Shebang**: `#!/usr/bin/env bash`
- **Indentation**: 2 spaces (NO tabs)
- **Line length**: ≤ 120 characters
- **Error handling**: Use `set -euo pipefail` unless explicitly avoided
- **Spacing**: Spaces around operators and after commas
- **Command substitution**: Use `$(...)`, never backticks

#### Naming Conventions

- **Functions**: `snake_case` (e.g., `install_kubectl`, `setup_profile`)
- **Variables**: `snake_case` lowercase for locals, `UPPERCASE` for constants/env vars
- **Private functions**: Prefix with `_` (e.g., `_helper_function`)

#### Variable Handling

- **Always quote**: `"$var"` in command arguments
- **Local scope**: Prefer `local` for function variables
- **Arrays**: Use arrays for lists to avoid word splitting
- **Parameter forwarding**: Use `"$@"` to forward all arguments

#### Function Design

- Single responsibility per function
- Brief comment above each function explaining purpose
- Use `return` or exit codes for error signaling (NOT `echo`)
- Avoid global variables unless necessary
- Pass parameters explicitly

#### Common Patterns

```bash
# Distro detection (standard pattern)
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

# Root check (standard pattern)
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi

# Version checking with retry
retry_count=0
while [ -z "$REL" ]; do
  REL=$(curl -sLk https://example.com/latest)
  ((retry_count++))
  [ $retry_count -eq 10 ] && break
done

# Associative arrays for state
declare -A state=(
  ["key1"]="value1"
  ["key2"]=$(command)
)
```

### PowerShell Scripts (**.ps1)

#### Formatting

- **Target**: PowerShell 7.4+, cross-platform (testable on Linux)
- **Indentation**: 4 spaces (NO tabs)
- **Style**: One True Brace Style (OTBS)
  - Opening brace `{` on same line as statement
  - Closing brace `}` on own line
  - Multi-condition statements: all conditions + `{` on same line
  - Block body always on separate lines (never inline)
- **Long arrays**: Use `@(...)` with one element per line if >120 chars

#### Naming Conventions

- **Functions**: `Verb-Noun` PascalCase (use approved PowerShell verbs only)
- **Parameters**: `PascalCase` (e.g., `$TargetDir`, `$MaxRetries`)
- **Local variables**: `camelCase` (e.g., `$retryCount`, `$exit`)
- **Properties**: `camelCase`

#### Documentation

- Always include comment-based help with:
  - `.SYNOPSIS`
  - `.PARAMETER` (for each parameter)
  - `.EXAMPLE`
- Ensure `Get-Help` compatibility for all public functions

#### Function Design

- Single responsibility per function
- Use parameter splatting for >3 parameters
- Consistent error handling patterns
- Appropriate exception handling with try/catch

#### Common Patterns

```powershell
# Standard function template
function Invoke-SomeAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$TargetPath,

        [Parameter(HelpMessage = 'Number of retries')]
        [int]$MaxRetries = 10
    )

    # Use camelCase for local variables
    $retryCount = 0
    
    # OTBS style for conditionals
    if ($condition) {
        # code
    } elseif ($otherCondition) {
        # code
    } else {
        # code
    }
}
```

## Import Conventions

### Bash

- **Dotsource shared functions**: `. .assets/provision/source.sh`
- **Profile sourcing**: `. "$HOME/.bashrc"` or `. /etc/profile.d/script.sh`

### PowerShell

- **Module imports**: `Import-Module ./modules/ModuleName/ModuleName.psd1`
- **Dot-sourcing**: `. "$PSScriptRoot/Functions/common.ps1"`

## Error Handling

### Bash

- Use `set -euo pipefail` for strict error handling
- Check command success: `command || handle_error`
- Exit codes: Return 0 for success, non-zero for errors
- Error messages to stderr: `echo "error" >&2`
- Color-coded output: `\e[31;1m` (red), `\e[32m` (green), `\e[92m` (bright green)

### PowerShell

- Use try/catch for exception handling
- Check specific exception types (e.g., `[System.IO.IOException]`)
- Use `-ErrorAction Stop` to make cmdlets throw
- Write errors: `Write-Error`, verbose: `Write-Verbose`
- Retry pattern: See `Invoke-CommandRetry` in `modules/InstallUtils/Functions/common.ps1`

## Type Usage

### Bash

- Prefer typed declarations when possible: `declare -i` (integer), `declare -a` (array), `declare -A` (associative)
- Use `[[  ]]` for conditionals (more robust than `[  ]`)
- Regex matching: `[[ "$var" =~ ^pattern$ ]]`

### PowerShell

- Always specify parameter types: `[string]`, `[int]`, `[switch]`, etc.
- Use `[CmdletBinding()]` for advanced functions
- Output types: `[OutputType([string])]` when appropriate
- Generic collections: `[System.Collections.Generic.List[string]]::new()`

## Special Considerations

### WSL Primary Focus

- **Main script**: `wsl/wsl_setup.ps1` orchestrates complete WSL distro setup
- **Provisioning scripts**: Located in `.assets/provision/` are called by wsl_setup.ps1
- **WSL-specific features**: PowerShell scripts in `wsl/` manage WSL configuration, networking, systemd, certificates
- **Windows host interaction**: WSL scripts often bridge between Linux distro and Windows host

### Cross-Platform Compatibility

- Shell scripts must work across Fedora, Debian, Ubuntu, Arch, OpenSUSE, Alpine
- PowerShell must be testable on Linux (use cross-platform cmdlets)
- Avoid distro-specific commands without fallbacks

### Root vs User Context

- Most `.assets/provision/install_*.sh` scripts require root (check with `$EUID -ne 0`)
- Setup scripts (`setup_*.sh`) typically run as user
- WSL PowerShell scripts often interact with Windows host

### Path Conventions

- Scripts reference `.assets/` relative paths
- User-specific: `$HOME/.local/bin`, `$HOME/.config`
- System-wide: `/usr/bin`, `/usr/local/bin`, `/etc/profile.d`

## Enforcement

All guidelines are **mandatory requirements**. When modifying code:

1. Follow ALL standards without requiring explicit reminders
2. Update existing code to meet standards when modifying related sections
3. Flag potential violations in your responses

## Additional Documentation

- WSL setup: `docs/wsl_setup.md` (primary focus - comprehensive WSL setup guide)
- WSL scripts reference: `docs/wsl_scripts.md` (detailed WSL management scripts documentation)
- Vagrant provisioning: `docs/vagrant.md` (secondary functionality)
- Repository scoped instructions: `.github/copilot-instructions.md`
