# Architecture

Single source of truth for how this repo is laid out, where the cross-platform/cross-shell seams are, and how to extend it. Read on demand from `AGENTS.md`.

## 1. Host vs guest split

The repo has two execution contexts. Knowing which side a script runs on is the first thing to check before editing.

| Side                | Path                             | Runs on                  | Invoked by                                    |
| ------------------- | -------------------------------- | ------------------------ | --------------------------------------------- |
| Windows host (PS)   | `wsl/*.ps1`                      | Windows PowerShell 7.4+  | User directly, from Windows                   |
| Guest provisioner   | `.assets/scripts/linux_setup.sh` | Linux/WSL (root)         | User on bare-metal, or `wsl_setup.ps1`        |
| Guest installers    | `.assets/provision/install_*.sh` | Linux/WSL (root)         | `linux_setup.sh`, `wsl_setup.ps1` via wsl.exe |
| Guest config (user) | `.assets/provision/setup_*.sh`   | Linux/WSL (user)         | `linux_setup.sh`, `wsl_setup.ps1` via wsl.exe |
| Guest config (PS)   | `.assets/provision/setup_*.ps1`  | Linux pwsh (user)        | `pwsh_setup.ps1` after pwsh install           |
| Shared functions    | `.assets/provision/source.sh`    | dot-sourced (no shebang) | other `.sh` provision scripts                 |
| Trigger one-shots   | `.assets/trigger/*.{sh,ps1}`     | either, varies           | Manual / scheduled                            |

**Crossing the boundary.** `wsl_setup.ps1` reaches into the guest by:

1. Copying repo files into the distro under `~/source/repos/szymonos/linux-setup-scripts/` (or the equivalent via `wsl_files_copy.ps1`).
2. Invoking `wsl.exe -d <distro> -u <root|user> -- <bash> <script>` to run provisioning.
3. Reading state back via stdout (captured as strings; mind UTF-16 vs UTF-8).

Anything `wsl.exe` writes from inside WSL is captured as text - preserve `\n` line endings, normalize with `.Replace("\`r\`n", "\`n")`.

## 2. Distro detection

Every installer that varies by distro starts with the same `SYS_ID` derivation:

```bash
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
case $SYS_ID in
alpine)   apk add --no-cache <pkg> ;;
arch)     pacman -Sy --needed --noconfirm <pkg> ;;
fedora)   dnf install -y <pkg> ;;
debian|ubuntu) apt-get install -y <pkg> ;;
opensuse) zypper install -y <pkg> ;;
esac
```

Notes:

- `SYS_ID` is empty on unsupported distros - installers should print a friendly error and `exit 0` (not `exit 1`) so orchestration doesn't abort the rest of the run.
- Use the BSD-compatible sed form (`-En` not `-rn`) so scripts can be sourced from macOS-hosted dev loops without rewriting.

## 3. Pre-commit hook inventory

Hooks are defined in `.pre-commit-config.yaml`. The runner is `prek` (not `pre-commit`). `make lint` runs hooks on changed files; `make lint HOOK=<id>` runs a single hook.

| Hook                                                              | What it checks                                                                   | Why                                                              |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `gremlins-check`                                                  | Unwanted Unicode (zero-width, look-alikes) in any text file                      | Catches AI-introduced invisible chars before they reach a script |
| `align-tables`                                                    | Pads markdown tables to consistent column widths                                 | Stops diff noise from one-cell edits realigning every row        |
| `check-zsh-compat`                                                | Bash files under `.assets/config/bash_cfg/` parse cleanly under zsh              | These files are sourced from both bash and zsh user shells       |
| `bats-tests`                                                      | For each changed `.sh`, runs its matching `tests/bats/test_*.bats` if one exists | Per-file unit test, fast                                         |
| `pester-tests`                                                    | For each changed `.ps1`/`.psm1`, runs its matching `tests/pester/*.Tests.ps1`    | Per-file unit test, fast                                         |
| `shfmt`                                                           | Formats `.sh` (excluded: `.zsh` - shfmt's bash parser breaks on zsh-only syntax) | Consistent shell style                                           |
| `shellcheck`                                                      | Static analysis, severity `warning` and above                                    | Catches the common bash footguns                                 |
| `markdownlint-cli2`                                               | Markdown style                                                                   | (`copilot-instructions.md` excluded)                             |
| `check-{executables,shebang}-*`                                   | Executable bit ↔ shebang consistency                                             | Prevents non-executable scripts being invoked directly           |
| `end-of-file-fixer` / `trailing-whitespace` / `mixed-line-ending` | Whitespace hygiene                                                               | Reduces diff churn                                               |

If a hook fires that you don't recognize, look it up here before "fixing" it by editing the hook config.

## 4. Test layout

```text
tests/
├── bats/        # Bash unit tests (one test_<file>.bats per shell file)
├── pester/      # PowerShell unit tests (one <Function>.Tests.ps1 per public function)
└── hooks/       # Python pre-commit hook implementations
    ├── gremlins.py
    ├── align_tables.py
    ├── check_zsh_compat.py
    ├── run_bats.py
    └── run_pester.py
```

- `make test-unit` runs both bats and Pester. Fast, no Docker, agent-runnable.
- `make test` is an alias for `test-unit` today; if a future `test-nix` target is added it must NOT be run from an agent session.
- Hooks under `tests/hooks/` are plain Python modules invoked by prek via `python3 -m tests.hooks.<name>`. They must run with the system Python - no third-party deps.

## 5. Recipes

### 5.1 Add a new tool installer

1. Create `.assets/provision/install_<tool>.sh` from this skeleton:

   ```bash
   #!/usr/bin/env bash
   : '
   # install <tool>
   sudo .assets/provision/install_<tool>.sh
   '
   if [ "$EUID" -ne 0 ]; then
     printf '\e[31;1mRun the script as root.\e[0m\n' >&2
     exit 1
   fi

   SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"
   case $SYS_ID in
   # ...per-distro install...
   esac
   ```

2. `chmod +x` the new file (the `check-executables-have-shebangs` hook will catch this).
3. If `wsl_setup.ps1` should install it as part of a scope, add a call site (search existing `install_*.sh` invocations for the pattern).
4. Add a bats test at `tests/bats/test_install_<tool>.bats` if the installer has parseable logic (distro switch, version detection). Skip the test for pure `apt-get install` wrappers - they offer nothing to test.
5. `make lint` and commit.

### 5.2 Add a PowerShell module function

1. Drop the function in `modules/<module-name>/Functions/<Verb-Noun>.ps1`.
2. Re-export from the module manifest if it's public: edit `modules/<module-name>/<module-name>.psd1`, add to `FunctionsToExport`.
3. Add Pester test at `tests/pester/<Verb-Noun>.Tests.ps1`.
4. Public functions require comment-based help (`.SYNOPSIS`, `.PARAMETER`, `.EXAMPLE`) - see `.claude/rules/powershell-style.md`.
5. `make lint` (runs the pester hook for the changed file) and commit.

### 5.3 Add a WSL operation (host-side)

1. New top-level operation → new `wsl/wsl_<verb>.ps1` script with `#Requires -PSEdition Core -Version 7.3` and comment-based help.
2. Integration into the main orchestrator → add a region in `wsl/wsl_setup.ps1` and gate it on the relevant `-Scope` value.
3. If it shells out to `wsl.exe`, splat args via `[System.Collections.Generic.List[string]]` and check `$LASTEXITCODE` after the call.
4. Add a Pester test for any non-trivial logic in `tests/pester/`.

### 5.4 Add an alias / function to user shells

Aliases that should appear in every shell the user opens go in `.assets/config/bash_cfg/*.sh` (bash and zsh both source these - see hook `check-zsh-compat`) or `.assets/config/pwsh_cfg/*.ps1`.

For functions installed system-wide via `/etc/profile.d/`, the file MUST start with a POSIX-portable guard (dash will source `/etc/profile.d/*.sh` from `/etc/profile` and choke on bash syntax):

```bash
[ -n "${BASH_VERSION:-}${ZSH_VERSION:-}" ] || return 0
```

See `design/lessons.md` for the incident this guard prevents.
