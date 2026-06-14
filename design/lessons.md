# Lessons

Postmortems for incidents that produced a durable rule. Each entry: **Symptom → Root cause → Rule**. Curate aggressively - every entry must encode a non-obvious lesson that prevents recurrence. Trivial fixes don't belong here.

When adding an entry, link the commit, the rule it produced (under `.claude/rules/`), and the file(s) affected.

---

## 2026-06 - `function` keyword in `/etc/profile.d/` breaks under dash

- **Commit:** `58649ce`
- **Symptom:** `sh: /etc/profile.d/aliases_git.sh: function: not found` / `Syntax error: "}" unexpected` during `nix/setup.sh` self-test inside a WSL distro this repo had provisioned.
- **Root cause:** `setup_profile_allusers.sh` installed bash-syntax files (`aliases_git.sh`, `functions.sh`) into `/etc/profile.d/`. On Debian/Ubuntu, `/bin/sh` is dash, and dash sources `/etc/profile.d/*.sh` from `/etc/profile` when invoked as a login shell (e.g., `sh -lc <build>` as used by the Determinate Nix installer). dash doesn't understand the `function` keyword.
- **Rule:** Any file installed into `/etc/profile.d/` must start with a POSIX-portable guard that no-ops under dash and proceeds under bash/zsh.

  ```bash
  [ -n "${BASH_VERSION:-}${ZSH_VERSION:-}" ] || return 0
  ```

  Verify with `dash -c '. <file>'`.

## 2026-06 - Bash SSH probe aborts pwsh provisioning on Windows hosts

- **Commit:** `dfb5943`
- **Symptom:** `wsl_setup.ps1` aborted partway through `pwsh` provisioning on Windows hosts after the envy-nx backport. No useful error - `$ErrorActionPreference = 'Stop'` swallowed the failing command's context.
- **Root cause:** `Invoke-GhRepoClone`'s SSH-first probe called bare `ssh -T git@github.com` from the `begin` block. On Windows PowerShell hosts where OpenSSH isn't on PATH, the missing command throws under `Stop` and aborts the whole script.
- **Rule:** Before calling a native binary that may not exist on the host (`ssh`, `git`, `gh`, ...), guard with `Get-Command <name> -ErrorAction SilentlyContinue`. Fall back to the HTTPS / non-binary path. PowerShell scripts that run on both Windows and Linux hosts cannot assume any guest-only binary is on PATH.

## 2026-06 - Windows-mount repo paths trigger git "dubious ownership"

- **Commit:** `cf3ba30`
- **Symptom:** Every git invocation from inside WSL against a repo under `/mnt/c/Users/<user>/source/repos/...` surfaced `fatal: detected dubious ownership in repository at '/mnt/c/...'`. Caught by envy-nx's `nix/setup.sh` self-test running git from `/mnt/c/`.
- **Root cause:** The `.git` directory's owner UID (Windows side) doesn't match the WSL user's UID. Git refuses to operate on repos it sees as owned by another user.
- **Rule:** WSL provisioning must register per-user `safe.directory` entries for the common Windows-mount repo layouts (`/mnt/<drive>/Users/<user>/source/repos/*`, `/mnt/<drive>/Users/<user>/source/repos/*/*`). Write to the WSL user's `~/.gitconfig` (per-user, not system-wide) and guard with `grep -qFx` for idempotency.

## 2026-06 - BSD grep silently fails empty-alternative regex

- **Commit:** `78b177d`
- **Symptom:** `git_resolve_branch ""` and `git_resolve_branch "d"` returned the literal regex pattern instead of resolving to `dev`/`devel`/`development`. Worked on Linux, failed silently on macOS. Surfaced by envy-nx's integration workflow running the full bats suite on `macos-15`.
- **Root cause:** Case-arm patterns like `(|el|elop|elopment)` use an empty alternative at the start. GNU grep matches it; BSD grep on macOS doesn't, and yields no match. The functions returned the unmatched pattern as a literal string.
- **Rule:** Never use empty-alternative regex (`(|foo|bar)`). Use the explicit-optional form `(foo|bar)?` - unambiguously correct on both GNU and BSD grep, and equivalent for purposes of "match nothing or one of the alternatives". This is also a useful test ground for the cross-platform bats suite: anything that worked on Linux but only Linux is an under-tested portability assumption.
