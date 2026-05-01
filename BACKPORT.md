# Backporting from envy-nx

This repo (`linux-setup-scripts`) and [`envy-nx`](https://github.com/szymonos/envy-nx)
share a chunk of code: most of `modules/`, all of `wsl/`, large parts of
`.assets/config/` and `.assets/provision/`, and the `tests/` infrastructure.
envy-nx is the cross-platform Nix descendant and is in rapid (daily-ish)
development. This repo cherry-picks improvements that apply to its
**parallel functionality** - code that exists in both repos and serves the
same purpose.

This document is the procedure an agent (human or AI) follows when asked to
"backport recent envy-nx improvements." There is **no upstream marker** on
envy-nx commits or CHANGELOG entries - every candidate is evaluated at runtime
against the rules below.

## Last ported through

```text
envy-nx commit: c859bba    # bump on each backport PR; agent reads CHANGELOG entries newer than this
envy-nx tag:    v1.4.0     # nearest released tag for human readability
ported on:      2026-05-01
```

When you finish a backport PR, update all three lines and include the bump in
the final commit. The agent uses the SHA as the cut-off; everything before it
is already considered ported (or deliberately skipped).

## Procedure

1. **Verify envy-nx is checked out and current.** Default location is
   `~/source/repos/szymonos/envy-nx`. Run `git -C ~/source/repos/szymonos/envy-nx pull`
   before starting. If the repo isn't there, clone it first (read-only is fine).

2. **Baseline this repo.** Run `make lint && make test`. Do not start with a
   dirty or red baseline - finish open work first.

3. **Compute the candidate list.** Read envy-nx's `CHANGELOG.md` from the
   entry **after** the "Last ported through" SHA up to the unreleased section.
   Each bullet is a candidate. Aim for chronological order (oldest first) so
   later entries that build on earlier ones make sense.

4. **Evaluate each candidate** against the rules in
   *Eligibility* below. Sort into three buckets:
   - **Port** - applies to parallel functionality, no nix coupling
   - **Skip** - nix-only, refactor that doesn't apply, or removes something we still need
   - **Investigate** - touches a parallel file but the diff might mix nix-coupled
     code; read the actual file diff before deciding

5. **Group ports into logical PRs.** Bug fixes together; perf/quality together;
   net-new functionality on its own. Aim for 3-7 commits per PR, one logical
   change each. Use a branch named `chore/port-envy-nx-<topic>` (e.g.
   `chore/port-envy-nx-fixes-may`).

6. **Apply each change.** For each commit:
   - Read the corresponding envy-nx file fully
   - Read this repo's file fully
   - Identify the *delta* that's the improvement (vs the structural divergence)
   - Apply via the `Edit` tool - never overwrite a whole file unless it's a
     pure copy (e.g., a Pester test file)
   - For test files: copy the whole file, then adapt the dot-source / source
     paths via the path mapping
   - For envy-nx file headers that reference `nix/setup.sh` or `~/.nix-profile`,
     rewrite them to match this repo's entry points (`linux_setup.sh`,
     `wsl_setup.ps1`)

7. **Validate after each commit.**
   - `make lint` for any change
   - `make test` if you touched code under `modules/`, `.assets/config/`,
     or `tests/`
   - For shell config under `.assets/config/bash_cfg/`: run
     `dash -c '. <file>'` to confirm the POSIX-guard pattern still holds
     (these files are installed to `/etc/profile.d/` and sourced by dash)

8. **Bump the "Last ported through" pointer** in this file as the final
   commit of the PR.

9. **Open the PR with the integration test triggered.**

   ```bash
   gh pr create --title "..." --body "..."
   gh pr edit --add-label test:integration
   ```

## Eligibility

### Port if all of these are true

- The CHANGELOG entry mentions a file/function that maps to a path in the
  *Path mapping* table below
- The change is a bug fix, perf improvement, hardening, or quality fix to an
  existing parallel function
- The diff doesn't reference nix-only symbols (see *Nix coupling signals* below)
- If it adds something new (function, file, env var), it's additive and useful
  to a non-nix WSL/Linux user

### Skip if any of these are true

- The CHANGELOG entry's only touched files are in the *Skip-list* below
- The change is a refactor of an envy-nx-only structure (`nx.sh` family split,
  `nx_surface.json`, etc.)
- The change relies on `nix profile`, `flake.nix`, `~/.nix-profile/`, or any
  `nx` CLI verb
- The change removes something this repo still uses (e.g., envy-nx removed
  `install_pwsh.sh` because pwsh comes from nix; we still need the script)
- The change is macOS-specific (this repo targets Linux/WSL only)
- The change is purely cosmetic to envy-nx's CHANGELOG, docs, or release tooling

### Investigate (read the actual diff before deciding)

- File touched is in the path-mapping table BUT envy-nx may have nix-coupled
  helpers in the same file. Common in `wsl_setup.ps1`, `setup_common.sh`,
  `gh.sh`, `git.sh`, `functions.sh`. Extract the non-nix delta or skip if it's
  too entangled.

### Nix coupling signals

If the diff contains any of these, the relevant block is nix-coupled - exclude
it from the port even if surrounding code is shared:

| Signal                  | Examples                                                                                                                                                                                                 |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Path references         | `~/.nix-profile/`, `~/.config/nix-env/`, `/nix/store`, `nix/...`                                                                                                                                         |
| Env vars                | `NIX_*`, `NIX_SSL_CERT_FILE`, `NIX_ENV_*`                                                                                                                                                                |
| CLI calls               | `nix` (as command), `nx` (as command), `nix profile`, `nix flake`, `nix-env`, `nx_doctor.sh`                                                                                                             |
| Files / declarations    | `flake.nix`, `flake.lock`, `config.nix`, `*.nix`, `nx_surface.json`                                                                                                                                      |
| Module references       | `do-common`, `do-linux`, `do-az`, `psm-windows`, `aliases-git`, `aliases-kubectl` (envy-nx vendors these; this repo clones from `szymonos/ps-modules` at runtime - see *Module layout difference* below) |
| Phase-library structure | `nix/lib/io.sh`, `nix/lib/phases/*.sh`, `_io_run`, `_io_nix`, `phase_*` functions                                                                                                                        |
| Scope system            | `scopes.json`, `scopes.sh`, `resolve_scope_deps`, `sort_scopes`, scope `--` flags like `--shell`, `--python`                                                                                             |
| Managed-block pattern   | `manage_block`, `# >>> nix-env managed >>>`, `# >>> managed env >>>`                                                                                                                                     |

## Path mapping

envy-nx has a different module / asset layout. Translate paths via this table.
A blank "this repo" cell means **no equivalent - skip**.

### Modules

| envy-nx                                                    | this repo                                                                                                                                              |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `modules/InstallUtils/Functions/git.ps1`                   | `modules/InstallUtils/Functions/git.ps1`                                                                                                               |
| `modules/do-common/Functions/common.ps1`                   | `modules/SetupUtils/Functions/common.ps1`                                                                                                              |
| `modules/do-common/Functions/logs.ps1`                     | `modules/SetupUtils/Functions/logs.ps1`                                                                                                                |
| `modules/do-common/Functions/certs.ps1`                    | `modules/SetupUtils/Functions/certs.ps1`                                                                                                               |
| `modules/do-common/Functions/cli.ps1`                      | (no equivalent - evaluate on demand)                                                                                                                   |
| `modules/do-common/Functions/python.ps1`                   | (no equivalent)                                                                                                                                        |
| `modules/do-common/Functions/dotnet.ps1`                   | (no equivalent)                                                                                                                                        |
| `modules/do-common/Functions/net.ps1`                      | (no equivalent)                                                                                                                                        |
| `modules/psm-windows/Functions/common.ps1`                 | `modules/InstallUtils/Functions/common.ps1` (`Invoke-CommandRetry`, `Join-Str`, `Test-IsAdmin`, `Update-SessionEnvironmentPath`)                       |
| `modules/SetupUtils/Functions/wsl.ps1`                     | `modules/SetupUtils/Functions/wsl.ps1` (only `Get-WslDistro`, `Set-WslConf` - scope helpers are nix-only)                                              |
| `modules/{do-az,do-linux,aliases-git,aliases-kubectl}/...` | (no equivalent - these are vendored in envy-nx; this repo clones `szymonos/ps-modules` at runtime in `linux_setup.sh`. See *Module layout difference*) |

### Shell config

| envy-nx                                           | this repo                                    |
| ------------------------------------------------- | -------------------------------------------- |
| `.assets/config/shell_cfg/functions.sh`           | `.assets/config/bash_cfg/functions.sh`       |
| `.assets/config/shell_cfg/aliases.sh`             | `.assets/config/bash_cfg/aliases.sh`         |
| `.assets/config/shell_cfg/aliases_git.sh`         | `.assets/config/bash_cfg/aliases_git.sh`     |
| `.assets/config/shell_cfg/aliases_kubectl.sh`     | `.assets/config/bash_cfg/aliases_kubectl.sh` |
| `.assets/config/shell_cfg/certs.sh`               | `.assets/config/bash_cfg/certs.sh`           |
| `.assets/config/shell_cfg/aliases_nix.sh`         | (skip - nix-only)                            |
| `.assets/config/shell_cfg/completions.{bash,zsh}` | (skip - `nx` CLI completions)                |
| `.assets/config/pwsh_cfg/_aliases_nix.ps1`        | (skip - nix-only)                            |
| `.assets/config/pwsh_cfg/profile_nix.ps1`         | (skip - nix-only)                            |
| `.assets/config/omp_cfg/`                         | `.assets/config/omp_cfg/`                    |
| `.assets/config/starship_cfg/`                    | (skip - this repo uses oh-my-posh only)      |

### WSL orchestration

| envy-nx                    | this repo                  |
| -------------------------- | -------------------------- |
| `wsl/wsl_setup.ps1`        | `wsl/wsl_setup.ps1`        |
| `wsl/wsl_certs_add.ps1`    | `wsl/wsl_certs_add.ps1`    |
| `wsl/wsl_distro_move.ps1`  | `wsl/wsl_distro_move.ps1`  |
| `wsl/wsl_files_copy.ps1`   | `wsl/wsl_files_copy.ps1`   |
| `wsl/wsl_flags_manage.ps1` | `wsl/wsl_flags_manage.ps1` |
| `wsl/wsl_install.ps1`      | `wsl/wsl_install.ps1`      |
| `wsl/wsl_network_fix.ps1`  | `wsl/wsl_network_fix.ps1`  |
| `wsl/wsl_restart.ps1`      | `wsl/wsl_restart.ps1`      |
| `wsl/wsl_systemd.ps1`      | `wsl/wsl_systemd.ps1`      |
| `wsl/wsl_win_path.ps1`     | `wsl/wsl_win_path.ps1`     |
| `wsl/wsl_wslg.ps1`         | `wsl/wsl_wslg.ps1`         |
| `wsl/pwsh_setup.ps1`       | `wsl/pwsh_setup.ps1`       |

The `wsl_setup.ps1` files are highly divergent (envy-nx delegates to nix, this
repo runs the per-tool installers). Only port surgical line-level fixes; never
copy whole sections.

### Provision / setup scripts

envy-nx has restructured provisioning into `.assets/{provision,setup,check,fix}/`.
This repo keeps them all flat under `.assets/provision/`.

| envy-nx                                    | this repo                                                                                                                             |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| `.assets/provision/install_base.sh`        | `.assets/provision/install_base.sh` (very different - envy-nx defers most to nix; ours installs the full set. Only port narrow fixes) |
| `.assets/provision/install_gh.sh`          | `.assets/provision/install_gh.sh`                                                                                                     |
| `.assets/provision/install_copilot.sh`     | `.assets/provision/install_copilot.sh`                                                                                                |
| `.assets/provision/install_distrobox.sh`   | `.assets/provision/install_distrobox.sh`                                                                                              |
| `.assets/provision/install_docker.sh`      | `.assets/provision/install_docker.sh`                                                                                                 |
| `.assets/provision/install_podman.sh`      | `.assets/provision/install_podman.sh`                                                                                                 |
| `.assets/provision/install_zsh.sh`         | `.assets/provision/install_zsh.sh`                                                                                                    |
| `.assets/provision/install_azurecli_uv.sh` | `.assets/provision/install_azurecli_uv.sh`                                                                                            |
| `.assets/provision/install_nix.sh`         | (skip - nix only)                                                                                                                     |
| `.assets/provision/upgrade_system.sh`      | `.assets/provision/upgrade_system.sh`                                                                                                 |
| `.assets/check/check_distro.sh`            | `.assets/provision/check_distro.sh`                                                                                                   |
| `.assets/check/check_dns.sh`               | `.assets/provision/check_dns.sh`                                                                                                      |
| `.assets/check/check_ssl.sh`               | `.assets/provision/check_ssl.sh`                                                                                                      |
| `.assets/fix/fix_azcli_certs.sh`           | `.assets/provision/fix_azcli_certs.sh`                                                                                                |
| `.assets/fix/fix_gcloud_certs.sh`          | `.assets/provision/fix_gcloud_certs.sh`                                                                                               |
| `.assets/fix/fix_no_file.sh`               | `.assets/provision/fix_no_file.sh`                                                                                                    |
| `.assets/fix/fix_nodejs_certs.sh`          | `.assets/provision/fix_nodejs_certs.sh`                                                                                               |
| `.assets/fix/fix_secure_path.sh`           | `.assets/provision/fix_secure_path.sh`                                                                                                |
| `.assets/setup/setup_gh_https.sh`          | `.assets/provision/setup_gh_https.sh`                                                                                                 |
| `.assets/setup/setup_gh_repos.sh`          | `.assets/provision/setup_gh_repos.sh`                                                                                                 |
| `.assets/setup/setup_ssh.sh`               | `.assets/provision/setup_ssh.sh`                                                                                                      |
| `.assets/setup/set_authorized_keys.sh`     | `.assets/provision/set_authorized_keys.sh`                                                                                            |
| `.assets/setup/set_ulimits.sh`             | `.assets/provision/set_ulimits.sh`                                                                                                    |
| `.assets/setup/setup_profile_user.zsh`     | `.assets/provision/setup_profile_user.zsh`                                                                                            |
| `.assets/setup/setup_profile_user.ps1`     | (no equivalent - envy-nx-specific pwsh provenance)                                                                                    |
| `.assets/setup/setup_common.sh`            | (no direct equivalent - this repo inlines its logic in `linux_setup.sh`'s tail)                                                       |
| `.assets/setup/autoexec.sh`                | `.assets/provision/autoexec.sh`                                                                                                       |
| `.assets/setup/update_psresources.ps1`     | `.assets/provision/update_psresources.ps1`                                                                                            |

This repo also has many `install_*.sh` scripts that envy-nx removed (because
nix replaces them). Don't port "removed" entries - those scripts are still
in active use here.

### Tests / hooks

| envy-nx                                                                                                                                                                                                                                                    | this repo                                                                                                                       |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `tests/pester/{ConvertCfg,ConvertPEM,GetLogLine,InvokeCommandRetry,JoinStr}.Tests.ps1`                                                                                                                                                                     | same paths (dot-source paths differ - see below)                                                                                |
| `tests/pester/NxCompleter.Tests.ps1`                                                                                                                                                                                                                       | (skip - `nx` CLI)                                                                                                               |
| `tests/pester/Scopes.Tests.ps1`                                                                                                                                                                                                                            | (skip - scope system)                                                                                                           |
| `tests/pester/WslSetup.Tests.ps1`                                                                                                                                                                                                                          | `tests/pester/WslSetup.Tests.ps1` (envy-nx version mocks nix-mode dispatch - substantive rewrite needed; investigate carefully) |
| `tests/bats/{test_functions,test_fixcertpy_discovery,test_git_aliases,test_gh_helpers}.bats`                                                                                                                                                               | same paths (source paths differ)                                                                                                |
| `tests/bats/test_nix_setup.bats`, `test_nx_*.bats`, `test_overlay.bats`, `test_profile_block.bats`, `test_profile_migration.bats`, `test_pwsh_nop.bats`, `test_install_record.bats`, `test_uninstaller.bats`, `test_conda_remove.bats`, `test_scopes.bats` | (skip - all nix/scope-specific)                                                                                                 |
| `tests/hooks/run_pester.py`                                                                                                                                                                                                                                | `tests/hooks/run_pester.py`                                                                                                     |
| `tests/hooks/run_bats.py`                                                                                                                                                                                                                                  | `tests/hooks/run_bats.py`                                                                                                       |
| `tests/hooks/check_zsh_compat.py`                                                                                                                                                                                                                          | `tests/hooks/check_zsh_compat.py`                                                                                               |
| `tests/hooks/check_bash32.py`                                                                                                                                                                                                                              | (skip - bash 3.2 is for macOS)                                                                                                  |
| `tests/hooks/check_changelog.py`                                                                                                                                                                                                                           | (skip - this repo has no CHANGELOG.md)                                                                                          |
| `tests/hooks/check_nx_*.py`, `gen_nx_completions.py`, `nix_closure_to_spdx.py`                                                                                                                                                                             | (skip - nix/nx)                                                                                                                 |
| `tests/hooks/validate_scopes.py`                                                                                                                                                                                                                           | (skip - scope system)                                                                                                           |
| `tests/hooks/gremlins.py`                                                                                                                                                                                                                                  | `tests/hooks/gremlins.py`                                                                                                       |
| `tests/hooks/align_tables.py`                                                                                                                                                                                                                              | (currently skipped - could port if markdown table maintenance becomes a pain)                                                   |
| `tests/hooks/validate_docs_words.py`                                                                                                                                                                                                                       | (skip - needs cspell + docs/ structure)                                                                                         |

When porting Pester tests, adapt the dot-source path:

```text
envy-nx:    . $PSScriptRoot/../../modules/do-common/Functions/common.ps1
this repo:  . $PSScriptRoot/../../modules/SetupUtils/Functions/common.ps1
```

When porting bats tests, adapt the source directive:

```text
envy-nx:    source "$BATS_TEST_DIRNAME/../../.assets/config/shell_cfg/functions.sh"
this repo:  source "$BATS_TEST_DIRNAME/../../.assets/config/bash_cfg/functions.sh"
```

### CI

| envy-nx                               | this repo                                                                                                  |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `.github/workflows/repo_checks.yml`   | `.github/workflows/repo_checks.yml`                                                                        |
| `.github/workflows/test_linux.yml`    | `.github/workflows/test_linux.yml` (very different - envy-nx exercises nix matrix, ours builds Dockerfile) |
| `.github/workflows/tests.yml`         | `.github/workflows/tests.yml` (envy-nx may not have this; we added on bootstrap)                           |
| `.github/workflows/test_macos.yml`    | (skip - Linux/WSL only)                                                                                    |
| `.github/workflows/release.yml`       | (skip - no signed releases here)                                                                           |
| `.github/workflows/docs-gh-pages.yml` | (skip - no docs site)                                                                                      |

## Skip-list (never eligible)

| Path                                                                                                              | Reason                                                                                      |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `nix/` (entire dir)                                                                                               | Nix path entry point                                                                        |
| `.assets/lib/` (entire dir)                                                                                       | envy-nx-only restructure (helpers, scopes, profile_block, env_block, certs, nx_doctor, nx*) |
| `.assets/config/shell_cfg/aliases_nix.sh`                                                                         | nix aliases                                                                                 |
| `.assets/config/shell_cfg/completions.{bash,zsh}`                                                                 | `nx` CLI tab completion                                                                     |
| `.assets/config/pwsh_cfg/_aliases_nix.ps1`                                                                        | nix aliases (pwsh)                                                                          |
| `.assets/config/pwsh_cfg/profile_nix.ps1`                                                                         | nix profile template                                                                        |
| `.assets/config/starship_cfg/`                                                                                    | starship prompt (this repo uses oh-my-posh)                                                 |
| `console/`                                                                                                        | envy-nx maintainer tooling                                                                  |
| `design/`                                                                                                         | envy-nx design notes                                                                        |
| `docs/`                                                                                                           | envy-nx mkdocs site (this repo's `docs/` is separate)                                       |
| `mkdocs.yml` (envy-nx)                                                                                            | docs site config                                                                            |
| `pyproject.toml` (envy-nx)                                                                                        | nix path packaging - this repo doesn't need one                                             |
| `uv.lock`                                                                                                         | docs site dependency lock                                                                   |
| `tests/bats/test_{nix_setup,nx_*,overlay,profile_*,pwsh_nop,install_record,uninstaller,conda_remove,scopes}.bats` | nix/scope tests                                                                             |
| `tests/pester/{NxCompleter,Scopes}.Tests.ps1`                                                                     | `nx` CLI / scope tests                                                                      |
| `tests/hooks/{check_bash32,check_changelog,check_nx_*,gen_nx_completions,nix_closure_to_spdx,validate_scopes}.py` | nix/scope/changelog hooks                                                                   |
| `.github/workflows/{test_macos,release,docs-gh-pages}.yml`                                                        | macOS / release / docs                                                                      |

## Hard rules

- **Never copy nix-coupled code** even if it lives in a path-mapped file. Use
  the *Nix coupling signals* table to identify, then exclude that block.
- **Tests come first** when porting a function fix. Port the test for the
  function in the same commit. The test validates the port worked.
- **One logical change per commit.** Don't bundle unrelated fixes. Reviewer
  and `git bisect` need them separable.
- **Adapt comments and headers.** envy-nx file headers reference `nix/setup.sh`
  and `~/.nix-profile`; rewrite them to reference this repo's entry points
  (`linux_setup.sh`, `wsl_setup.ps1`).
- **Ports are additive by default.** If envy-nx removed something we still
  need (e.g., `install_pwsh.sh`), don't remove it here.
- **A ported test that fails on this repo's code is a real bug.** Fix the bug,
  don't disable the test. (Bootstrap example: porting `JoinStr.Tests.ps1`
  surfaced a missing `DefaultParameterSetName='None'` on `Join-Str` - fixed
  in the same commit.)
- **POSIX-guard new bash files** that get installed to `/etc/profile.d/`. If
  the file uses bash-only syntax (`function`, `[[ ]]`, `local`, `+=`), add
  `[ -n "${BASH_VERSION:-}${ZSH_VERSION:-}" ] || return 0` at the top so dash
  no-ops cleanly when sourcing it. Verify with `dash -c '. <file>'`. (See
  `aliases_git.sh`, `functions.sh`.)
- **Don't add nix-only directories.** No `nix/`, `.assets/lib/`, scope files.
  These belong only in envy-nx.

## Module layout difference

envy-nx vendors several PowerShell modules under `modules/` (`do-common`,
`do-az`, `do-linux`, `psm-windows`, `aliases-git`, `aliases-kubectl`). This
repo does **not** vendor them - `linux_setup.sh`'s tail clones
[`szymonos/ps-modules`](https://github.com/szymonos/ps-modules) at runtime
and installs the relevant ones via `module_manage.ps1`.

Practical implication: when envy-nx changes a function in `modules/do-common/`,
the actual fix lives upstream in `szymonos/ps-modules`. envy-nx's vendored
copy is a snapshot. To port the fix to this repo:

1. Apply it to the corresponding function in `modules/SetupUtils/` or
   `modules/InstallUtils/` (the module names this repo uses pre-clone), AND
2. Optionally raise the same fix in `szymonos/ps-modules` (out of scope for
   this doc; mention in the PR body if relevant)

## Examples

### Example 1: pure copy with path adaptation (Pester test)

envy-nx CHANGELOG entry: *added Pester tests for `Get-LogLine` covering the
`$ctx` regression*

1. Read `~/source/repos/szymonos/envy-nx/tests/pester/GetLogLine.Tests.ps1`
2. Copy to `tests/pester/GetLogLine.Tests.ps1`
3. Change the dot-source line:
   `. $PSScriptRoot/../../modules/do-common/Functions/logs.ps1`
   → `. $PSScriptRoot/../../modules/SetupUtils/Functions/logs.ps1`
4. Run `pwsh -nop -c 'Invoke-Pester tests/pester/GetLogLine.Tests.ps1'`
5. Commit

### Example 2: substantive port of a function (cert_intercept)

envy-nx CHANGELOG entry: *added `cert_intercept` shell function for capturing
MITM proxy certs from TLS chain*

1. Read `~/source/repos/szymonos/envy-nx/.assets/config/shell_cfg/functions.sh`
2. Locate the `cert_intercept` function definition + its dependencies
3. Verify it has no nix coupling (greps for `~/.nix-profile`, `nix` calls,
   `NIX_*` come up clean - only `NIX_ENV_TLS_PROBE_URL` reference, which is
   optional via `${VAR:-default}` fallback)
4. Add the function to `.assets/config/bash_cfg/functions.sh` after the
   existing `fixcertpy` definition; keep the envy-nx version verbatim
5. Wire any new state into consumers - e.g., the function writes to
   `~/.config/certs/ca-custom.crt`; verify `setup_profile_user.sh` sources
   `certs.sh` so env vars get exported
6. Run `bats tests/bats/test_functions.bats` (which covers `cert_intercept`)
7. Commit

### Example 3: surgical line fix in a divergent file

envy-nx CHANGELOG entry: *quiet `apt` output during system upgrade*

1. Read `~/source/repos/szymonos/envy-nx/.assets/provision/upgrade_system.sh`
2. Read this repo's `.assets/provision/upgrade_system.sh`
3. The two files are otherwise identical - the only delta is the `-qq` flag
   on `apt-get update` and `-qqy` on `dist-upgrade`
4. Apply the one-line edit via `Edit` tool
5. Commit

### Example 4: skip - nix-only refactor

envy-nx CHANGELOG entry: *split `nx.sh` into family files (`nx_pkg.sh`,
`nx_scope.sh`, `nx_profile.sh`, `nx_lifecycle.sh`)*

1. The touched files are all in `.assets/lib/` (envy-nx-only)
2. The `nx` CLI doesn't exist in this repo
3. Skip. No port action; no entry in the PR.

### Example 5: investigate - divergent file with mixed-coupling diff

envy-nx CHANGELOG entry: *`wsl_setup.ps1`: pre-populate gh config from default
distro via direct `cat` of hosts.yml*

1. Read both `wsl_setup.ps1` files
2. The diff has two clusters: (a) the `cat ~/.config/gh/hosts.yml` line -
   shared, pure win, port; (b) restructured nix-arg-building blocks - nix-only,
   skip
3. Apply only (a) via `Edit` tool - replace one line in this repo's
   `wsl_setup.ps1`. Leave (b) alone.
4. Verify by reading the surrounding code in this repo to confirm the new
   line slots in cleanly
5. Commit

## When in doubt

- Read the actual envy-nx file, not just the CHANGELOG entry
- Skip > break. A missed port can be picked up next time; a broken port
  costs the user a setup re-run
- Run the tests. If a ported test fails on this repo's code, that's a
  signal to fix something - not to drop the test
- When the layout diverges (envy-nx has `tests/pester/Scopes.Tests.ps1`,
  this repo doesn't have a scope system), don't reinvent infrastructure to
  make the test fit - skip the test
