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

## 2026-07 - Synced-module parameter rename broke external call sites

- **Commit:** `632d7f7` (follow-up to the `do-common` v2.0.0 sync)
- **Symptom:** After syncing `do-common` v2.0.0 from `ps-modules`, `wsl_certs_add.ps1`, `vg_cacert_fix.ps1`, and `vg_certs_add.ps1` still called `Get-Certificate -BuildChain`, a parameter the new module version had renamed to `-PresentedChain`. The scripts throw at runtime because the old parameter no longer binds.
- **Root cause:** Synced modules (see `ARCHITECTURE.md` § 6.1) are mirrored wholesale from upstream, so a renamed/removed public parameter or function lands here with no local diff to flag it. Consumers *outside* the module directory - provisioning scripts, other modules - keep the old call and break silently until run.
- **Rule:** When a `modules_update.ps1` sync changes a synced module's **public surface** (renamed/removed parameter, function, or alias), grep the whole repo for call sites *outside* `modules/<name>/` and update them in the same branch. `rg -F '<OldName>'` across `.assets`, `wsl`, and sibling `modules/` is the completeness check. A synced version bump is a consumer-migration task, not just a file copy.

## 2026-07 - MSAL browser auth hangs at "Working…" - Windows process shadows the fixed reply port

- **Commit:** `069187b` (PR #259)
- **Symptom:** `Connect-AzAccount` / `Connect-MgGraph` from bare WSL opened the browser, accepted the account pick, then hung forever at "Working…" on `login.microsoftonline.com` (URL bar never advancing to `localhost`). `az login` worked; the same commands worked in a devcontainer on the *same* WSL distro; it "worked a few hours ago." Clearing the MSAL token cache, toggling IPv6, and re-checking WSL networking all did nothing.
- **Root cause:** Az.Accounts 5.x pins a **fixed** OAuth reply port - `redirect_uri=http://localhost:8400/` (not a random port) - and uses `response_mode=form_post`. A **Windows-side** VS Code utility process (a second window connected to another Coder workspace) was already `LISTENING` on `127.0.0.1:8400`. Under WSL2 NAT + `localhostForwarding`, Windows loopback delivers `localhost:8400` to the **Windows** listener, so AAD's `form_post` callback POSTed the auth code into VS Code (piling up `CLOSE_WAIT`s) and never reached the WSL listener. The devcontainer has its own network namespace, so its 8400 wasn't shadowed; `az` uses a different reply port; the collision only appeared once the other VS Code instance grabbed 8400.
- **Diagnosis technique:** Prove the leg, don't theorize. A GET/POST from Windows (`Invoke-WebRequest`) to a *fresh* WSL port round-tripped 200, but to `8400` it timed out - isolating the fault to the port, not the method/firewall/networking. `netstat -ano | findstr :8400` (or `Get-NetTCPConnection -LocalPort 8400`) on the **Windows** side then named the owning PID.
- **Rule:** When a WSL browser-auth flow hangs *after* account selection but *before* the `localhost` redirect, suspect a **Windows-side listener on the tool's fixed reply port** before touching anything in WSL (cache, IPv6, shim, modules, networkingMode). The blank/"Working…" page is Windows↔AAD traffic that never enters WSL, so no WSL-internal change can fix it. Az PowerShell's port is 8400; check it with `Get-NetTCPConnection -State Listen -LocalPort 8400` on Windows and free it (close/restart the offending app). Unrelated aside confirmed here: `wslview` is a binary name hardcoded in MSAL.NET (`NetCorePlatformProxy.cs`), **not** a wslu dependency - wslu's 2025-03 archival does not affect the shim.

## 2026-07 - Provisioning step gated on a not-yet-installed module silently no-ops

- **Commit:** `25324b5` (PR #259)
- **Symptom:** `EnableLoginByWam` was never disabled on a fresh WSL setup, so Az PowerShell interactive login kept failing - even though `setup_profile_user.ps1` contained a block that ran `Update-AzConfig -EnableLoginByWam $false`. It appeared to work when re-running on an already-provisioned machine.
- **Root cause:** The block was gated on `Get-Module Az.Accounts -ListAvailable`, but `setup_profile_user.ps1` runs **before** the Az modules are installed - deliberately, because it first sets `Set-PSResourceRepository -Name PSGallery -Trusted` so the later `Install-PSResource Az` runs unattended. On a fresh box Az.Accounts doesn't exist yet, the gate is false, and the whole block is skipped with no error (`$ErrorActionPreference = 'SilentlyContinue'`). It only *looked* correct on a rerun, where Az was already present from the previous run.
- **Rule:** A provisioning step that depends on a tool/module installed *later in the same run* must live **after** that install, not be guarded by an availability check in an earlier script - the guard turns a hard ordering bug into a silent no-op that only a fresh run exposes. When adding config that needs module X, place it in the orchestrator (`linux_setup.sh` / `wsl_setup.ps1`) right after X is installed, and test on a **fresh** target, not a rerun. Reruns mask install-order bugs because prior state satisfies the guard.
