---
repo: szymonos/linux-setup-scripts
---

# Review brief - linux-setup-scripts

Curated context for a heterogeneous-model reviewer (`/second-opinion`).
You are reviewing a code diff. Read this brief first, then the diff, then any files needed for context.

## Project

Automation scripts for provisioning Linux systems, primarily **WSL** (Windows Subsystem for Linux).

- **Languages:** Bash 5+ (`.sh`), PowerShell 7.4+ (`.ps1`), Python 3 (pre-commit hooks under `tests/hooks/`).
- **Supported distros:** Fedora/RHEL, Debian/Ubuntu, Arch, OpenSUSE, Alpine.
- **Two execution contexts:** Windows host (`wsl/*.ps1`) drives WSL guests via `wsl.exe`; guest scripts (`.assets/scripts/`, `.assets/provision/`) run inside the distro.

See `ARCHITECTURE.md` for the full host/guest split, distro detection pattern, pre-commit hook inventory, test layout, and recipes.

## Focus areas (ordered by importance)

1. **Correctness** - logic errors, missed edge cases, off-by-one, race conditions, exit-code handling. Distro-detection branches that silently skip a supported distro.
2. **Cross-platform shell portability** - the `.assets/config/bash_cfg/*` files are sourced from both bash and zsh user shells. Anything installed to `/etc/profile.d/` is also sourced by dash. Watch for:
   - `function` keyword, bash arrays, `[[ ]]`, `${var,,}` in files that might run under dash.
   - Empty-alternative regex `(|foo|bar)` (BSD grep silently fails to match the empty alternative) - use `(foo|bar)?`.
   - GNU sed/grep extensions: `-P`, `-r` (use `-E`), `\s`, `\w` - macOS dev loops use BSD tools.
   - See `design/lessons.md` for the four documented postmortems (POSIX guard, SSH probe, safe.directory, BSD regex).
3. **Cross-host PowerShell guards** - `wsl/*.ps1` runs on Windows hosts where guest binaries (`ssh`, `gh`, etc.) may not exist. Calling them under `$ErrorActionPreference = 'Stop'` without a `Get-Command <name> -ErrorAction SilentlyContinue` guard aborts orchestration. See `design/lessons.md` (commit `dfb5943`).
4. **Idempotency** - provisioning scripts are re-run during upgrade. Writes to `~/.gitconfig`, `/etc/profile.d/`, and similar must guard with `grep -qFx`, atomic append, or equivalent. Don't append the same line twice.
5. **Error handling** -
   - Bash: missing `set -euo pipefail` on executable scripts (note: files sourced into the user's shell or installed to `/etc/profile.d/` should drop `-u`).
   - PowerShell: missing `$ErrorActionPreference = 'Stop'` in `begin` block; unchecked `$LASTEXITCODE` after `wsl.exe` or native binary invocations.
6. **WSL boundary** - `wsl.exe` output crosses Windows/Linux line-ending boundaries. Strings captured from inside WSL should be normalized with `.Replace("\`r\`n", "\`n")`.

## Known patterns - do NOT flag

These are deliberate. Flagging them is noise - they're documented project decisions:

- **`prek` instead of `pre-commit`** - `prek` is the pre-commit wrapper used in this project.
- **`--no-verify` in skill instructions** - per-commit hooks are skipped during branch consolidation and validated once via `make lint-diff` after all commits.
- **`--force-with-lease` in skill instructions** - deliberate; the skill rewrites branch history during consolidation.
- **`set -eo pipefail` without `-u` in files sourced into user shells** (under `.assets/config/bash_cfg/`, `/etc/profile.d/`) - intentional. `nounset` breaks shell-init files that source optional env vars.
- **POSIX guard `[ -n "${BASH_VERSION:-}${ZSH_VERSION:-}" ] || return 0` at the top of files installed to `/etc/profile.d/`** - intentional; prevents dash from choking on bash syntax.
- **BSD-compatible regex** (`sed -En`, no `\s`/`\w`/`-P`) in shell files - intentional for macOS dev-loop compatibility.
- **`Write-Host` in PowerShell** - intentional; bypasses the pipeline for colored console output.
- **Symlinked `CLAUDE.md` → `AGENTS.md`** - single source of truth, two lookup paths.
- **`REVIEW-BRIEF.md` with `repo:` frontmatter tag** - portability mechanism; not stale metadata.
- **`ubuntu-slim` as a GitHub Actions runner** - valid GitHub-hosted runner, used intentionally.
- **OpenWolf files under `.wolf/` and `.claude/rules/openwolf.md`** - gitignored personal context management system, not stale dead code.
- **`disable-model-invocation: true` in some skill frontmatter** - controls whether a skill can be invoked programmatically; deliberate per-skill setting.

## Output format

Produce a single markdown response with this structure:

```text
## Findings

### F-001 - <severity> - <file>:<line>
<one-paragraph description; reference the constraint being violated; be specific>

**Suggestion:** <concrete fix direction, NOT a patch>

### F-002 - <severity> - <file>:<line>
...
```

Severities:

- **`bug`** - correctness or security defect; the code is wrong.
- **`warning`** - likely issue, needs judgment; the code might be wrong under conditions you can't fully verify.
- **`nit`** - style or clarity; the code works but could be clearer.

If zero findings, output exactly: `No findings.`

## Bias-control rules

- Speculate carefully. If you suspect a bug but can't verify the call site, mark `warning` not `bug`.
- Don't pad with `nit` findings to look productive. Five `nit` items on a 200-line diff is fine; thirty is noise.
- If several findings share the same root cause, consolidate into one finding with multiple `<file>:<line>` references.
