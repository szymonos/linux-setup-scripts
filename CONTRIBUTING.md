# Contributing

Development workflow, tooling, and conventions for working on this repo. For architecture and runtime layout, see
`ARCHITECTURE.md`.

## Prerequisites

| Tool         | Version | Purpose                                   |
| ------------ | ------- | ----------------------------------------- |
| `bash`       | 3.2+    | Scripts (macOS system default is 3.2)     |
| `prek`       | latest  | Pre-commit hook runner (not `pre-commit`) |
| `bats`       | 1.5+    | Bash unit tests                           |
| `pwsh`       | 7.4+    | PowerShell scripts and Pester tests       |
| `jq`         | any     | Scope resolution (`scopes.sh`)            |
| `python3`    | 3.10+   | Pre-commit hook scripts                   |
| `shellcheck` | 0.9+    | Shell linting                             |
| `docker`     | any     | Smoke tests (optional)                    |

## Quick start

```bash
make install     # install pre-commit hooks via prek
make lint        # run hooks on changed files (do this before every commit)
make test-unit   # run bats + Pester unit tests (fast, no Docker)
make test        # run all tests including Docker smoke tests
make help        # list all targets
```

## Development loop

1. Make changes.
2. Run `make lint`. This stages all changes and runs pre-commit hooks.
3. Fix any failures. Re-run `make lint` until clean.
4. Commit.

`make lint` runs `git add --all && prek run`, so it always checks the current working tree. Use `make lint-all` to
check every file in the repo, or `make lint-diff` to check only files changed since `main`.

## Pre-commit hooks

Configured in `.pre-commit-config.yaml`, run via `prek`.

### Local hooks (`tests/hooks/`)

| Hook              | Script               | What it checks                                                |
| ----------------- | -------------------- | ------------------------------------------------------------- |
| `gremlins-check`  | `gremlins.py`        | Unwanted Unicode characters (zero-width spaces, smart quotes) |
| `align-tables`    | `align_tables.py`    | Auto-aligns markdown tables on save                           |
| `validate-scopes` | `validate_scopes.py` | `scopes.json` and `nix/scopes/*.nix` are consistent           |
| `check-bash32`    | `check_bash32.py`    | Nix-path `.sh` files avoid bash 4+ constructs                 |
| `bats-tests`      | `run_bats.py`        | Runs bats unit tests when relevant files change               |
| `pester-tests`    | `run_pester.py`      | Runs Pester unit tests when relevant files change             |

### External hooks

| Hook                                   | What it checks                             |
| -------------------------------------- | ------------------------------------------ |
| `check-executables-have-shebangs`      | Executable files have a shebang line       |
| `check-shebang-scripts-are-executable` | Files with shebangs are `chmod +x`         |
| `end-of-file-fixer`                    | Files end with exactly one newline         |
| `mixed-line-ending`                    | No mixed LF/CRLF                           |
| `trailing-whitespace`                  | No trailing whitespace (except `.md`)      |
| `ruff-check` / `ruff-format`           | Python lint + format (`tests/` only)       |
| `markdownlint-cli2`                    | Markdown lint                              |
| `shellcheck`                           | Shell static analysis (severity: warning+) |

ShellCheck global excludes: `SC1090` (non-constant source), `SC2139` (expand at define time), `SC2148` (missing
shebang on sourced files), `SC2155` (declare and assign separately), `SC2174` (mkdir mode).

## File rules

### Which bash version?

| Files matching                                                                                         | Bash version | `set` flags         |
| ------------------------------------------------------------------------------------------------------ | ------------ | ------------------- |
| `nix/**/*.sh`, `.assets/lib/{scopes,profile_block,nx_doctor,certs}.sh`, `.assets/config/bash_cfg/*.sh` | 3.2          | `set -eo pipefail`  |
| `.assets/provision/*.sh`, `.assets/scripts/*.sh`, `.assets/check/*.sh`                                 | 5.x (Linux)  | `set -euo pipefail` |

Nix-path files must avoid: `mapfile`, `declare -A`, `declare -n`, `${var,,}`, negative array indices, `sed -i ''`,
`sed -r`, `grep -P`. Full list in `ARCHITECTURE.md` under "Bash 3.2 / BSD sed constraints". Enforced by the
`check-bash32` pre-commit hook.

### Sourced libraries vs executable scripts

Sourced library files (e.g. `nix/lib/io.sh`, `nix/lib/phases/*.sh`, `.assets/lib/*.sh`) must **not** have a shebang
and must **not** be executable. They are loaded via `source` by the calling script.

Executable scripts must have `#!/usr/bin/env bash` and be `chmod +x`. The `check-executables-have-shebangs` and
`check-shebang-scripts-are-executable` hooks enforce this.

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

## Testing

### Unit tests (bats)

Test files live in `tests/bats/*.bats`. Run with `bats tests/bats/` or `make test-unit`.

Phase functions from `nix/lib/phases/` are tested by sourcing them directly and overriding `_io_*` wrappers from
`nix/lib/io.sh`:

```bash
setup() {
  # source libraries
  source "$REPO_ROOT/nix/lib/io.sh"
  source "$REPO_ROOT/nix/lib/phases/nix_profile.sh"
  source "$REPO_ROOT/.assets/lib/scopes.sh"

  # override side effects AFTER sourcing
  _io_nix() { echo "nix $*" >>"$BATS_TEST_TMPDIR/nix.log"; }
  _io_run() { echo "run $*" >>"$BATS_TEST_TMPDIR/run.log"; }
}

@test "nix_profile: apply runs profile add and upgrade" {
  phase_nix_profile_apply
  grep -q 'nix profile add' "$BATS_TEST_TMPDIR/nix.log"
  grep -q 'nix profile upgrade nix-env' "$BATS_TEST_TMPDIR/nix.log"
}
```

The `_io_*` convention: phases call `_io_nix`, `_io_nix_eval`, `_io_curl_probe`, `_io_run` instead of the raw
commands. Tests redefine these to capture calls without executing them. Define stubs **after** sourcing `io.sh`
(sourcing redefines the defaults).

### Unit tests (Pester)

Test files live in `tests/pester/*.Tests.ps1`. Run with `make test-unit` or invoke Pester directly:

```powershell
$pesterCfg = @{
    Run    = @{ Path = 'tests/pester/'; Exit = $true }
    Output = @{ Verbosity = 'Detailed' }
}
Invoke-Pester -Configuration @pesterCfg
```

### Smoke tests (Docker)

`make test-nix` and `make test-legacy` build throwaway Docker images that run a full provisioning pass and verify
key binaries. Slower but catches integration issues that unit tests miss.

### CI workflows

| Workflow          | What it tests                                        |
| ----------------- | ---------------------------------------------------- |
| `test_linux.yml`  | `setup.sh` on Linux: daemon + no-daemon (Coder) mode |
| `test_macos.yml`  | `setup.sh` on macOS 14/15 (bash 3.2 + BSD sed)       |
| `repo_checks.yml` | Pre-commit hooks (same as `make lint-diff`)          |

Trigger CI via PR labels `test:linux` / `test:macos`, or `workflow_dispatch` for manual runs.

## Adding a new scope

1. Create `nix/scopes/<name>.nix` with the package list and a `# bins:` comment.
2. Add the scope to `.assets/lib/scopes.json` (`valid_scopes`, `install_order`, and `dependency_rules` if needed).
3. Add a `--<name>` case to `phase_bootstrap_parse_args` in `nix/lib/phases/bootstrap.sh`.
4. If the scope needs post-install configuration, add `nix/configure/<name>.sh` and a `case` entry in
   `phase_configure_per_scope` in `nix/lib/phases/configure.sh`.
5. Run `make lint` (triggers `validate-scopes` + `bats-tests`).

## Adding a new phase function

1. Add the function to the appropriate file in `nix/lib/phases/`.
2. Document globals in the header comment (`# Reads:` / `# Writes:`).
3. Call it from `nix/setup.sh` at the right point in the phase sequence.
4. Use `_io_*` wrappers for any external commands (`nix`, `curl`, script invocations).
5. Add bats tests that stub `_io_*` and verify behavior.

## Style reference

Bash and PowerShell style guides are in `CLAUDE.md`. Key points:

- **Bash**: 2-space indent, 120-char lines, `snake_case` functions, `UPPERCASE` constants, `local` for function
  variables.
- **PowerShell**: 4-space indent, OTBS braces, `Verb-Noun` functions, `PascalCase` parameters, `camelCase` locals.
- Prefer no comments. Add one only when the *why* is non-obvious.
