# Linux Setup Scripts Repository

Automation scripts for provisioning Linux systems, primarily **WSL** (Windows Subsystem for Linux).

- **Languages:** Bash 5.0+ (`.sh`), PowerShell 7.4+ (`.ps1`)
- **Supported distros:** Fedora/RHEL, Debian/Ubuntu, Arch, OpenSUSE, Alpine
- **Targets:** WSL (primary), VMs / bare-metal / distroboxes (secondary)

## Compound knowledge

Read on demand, not upfront:

| Layer                                                                    | When to read                                                                                 | What it answers             |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------- | --------------------------- |
| [`ARCHITECTURE.md`](ARCHITECTURE.md)                                     | Adding a new installer, alias module, or WSL operation; touching pre-commit hooks or tests   | How things connect          |
| [`design/lessons.md`](design/lessons.md)                                 | Before "fixing" a guard, retry, or odd-looking conditional that has a commit hash next to it | What went wrong before      |
| [`.claude/rules/bash-style.md`](.claude/rules/bash-style.md)             | Editing `*.sh` / `*.bash` / `*.bats` / `*.zsh`                                               | Shell conventions + gotchas |
| [`.claude/rules/powershell-style.md`](.claude/rules/powershell-style.md) | Editing `*.ps1` / `*.psm1` / `*.psd1`                                                        | PowerShell conventions      |

Skip these for typo fixes, doc-only edits, and conversational questions.

## Key Entry Points

- `wsl/wsl_setup.ps1` - main orchestration script, runs on the Windows host, calls `.assets/provision/` scripts inside WSL via `wsl.exe`
- `.assets/scripts/linux_setup.sh` - provisioning from a Linux host (bare-metal, VMs, WSL guest)
- `.assets/provision/install_*.sh` - individual tool installers (most require root)
- `.assets/provision/setup_*.sh` / `setup_*.ps1` - configuration scripts (typically run as user)
- `.assets/provision/source.sh` - shared functions, dot-sourced by other scripts

`ARCHITECTURE.md` § 1 has the full host-vs-guest split.

## Tooling

- **GitHub:** `gh` CLI for PR / issue / release operations
- **Pre-commit runner:** `prek` (**not** `pre-commit`)
- **PowerShell:** 7.4+ - use `pwsh` (not `powershell`)
- **Search:** `rg` (ripgrep) instead of `grep`, `fd` instead of `find` - faster, respects `.gitignore` by default

## Common Commands

```bash
make lint              # Run pre-commit hooks on changed files - use before every commit
make lint-all          # Run all hooks on all files (slow)
make lint HOOK=<id>    # Run a single hook - seconds instead of minutes
make hooks             # List hook IDs
make test-unit         # bats + Pester, fast, no Docker - agent-runnable
make help              # All targets
```

**Run `make lint` and fix failures before every commit.** Pre-commit hooks are configured in `.pre-commit-config.yaml` (`ARCHITECTURE.md` § 3 lists each one and why it exists).

## Global Renames and Pattern Changes

Before fixing a pattern globally, run `rg <pattern>` or `git grep <pattern>` first to find **all** occurrences - don't start editing until the full scope is known. For bulk renames across many files, use `sed -i` rather than editing one at a time. Verify with another grep afterwards.
