# setup.sh Phase Extraction Plan

**Target:** `nix/setup.sh` (590 lines) → slim orchestrator (~120 lines) + phase libraries.
**Primary driver:** Unit testability with `bats`. Current tests use `sed -n '/^fn()/,/^}/p'` to extract functions from `setup.sh` for testing - brittle and limits what can be tested.
**Secondary driver:** Maintainability once the script crosses ~600 lines.
**Constraint:** Bash 3.2 compatible (same as `scopes.sh`). No `declare -A`, no `mapfile`, no namerefs.

---

## Goals

1. Every phase function is sourceable in isolation by `bats` without executing `setup.sh`.
2. Side-effecting operations (`nix profile`, `cp`, `curl`) are isolated behind thin wrappers so tests can stub them.
3. The EXIT trap and `_ir_phase`/`_ir_error` provenance contract is preserved - phases remain in the same shell process.
4. No behavior change. This is a pure refactor; bats and CI matrix must pass unchanged before and after.

## Non-goals

- Porting to Go/Rust (separate decision).
- Removing globals entirely. Bash does not reward that; pragmatic shared state is fine if documented.
- Changing the public flag surface or exit codes.

---

## Current structure (line map)

| Lines   | Block                                                   | Phase label                 |
| ------- | ------------------------------------------------------- | --------------------------- |
| 34-91   | Guards, path resolution, helpers, EXIT trap             | `bootstrap` (pre-phase)     |
| 93-130  | `usage()`                                               | -                           |
| 132-278 | Arg parsing, jq bootstrap, sync to `ENV_DIR`            | `bootstrap`                 |
| 283-316 | Platform detect, pre-setup hooks, overlay discovery     | (pre-phase)                 |
| 318-378 | Load existing scopes, merge, remove, prompt exclusivity | `scope-resolve`             |
| 380-425 | Resolve deps, sort, write `config.nix`                  | `scope-resolve`             |
| 427-479 | Flake update logic, `nix profile upgrade`, MITM probe   | `nix-profile`               |
| 481-519 | `gh.sh`, `git.sh`, per-scope configure scripts          | `configure`                 |
| 521-549 | Shell profiles, post-setup hooks, `setup_common.sh`     | `profiles` + `post-install` |
| 551-589 | Mode detection, GC, summary                             | `complete`                  |

Each phase label already matches `_ir_phase` values - the script is logically already divided. The refactor just externalizes the division.

---

## Target layout

```text
nix/
  setup.sh                  # orchestrator (~120 lines)
  lib/
    phases/
      bootstrap.sh          # nix/jq detection, ENV_DIR sync, arg parsing
      platform.sh           # OS detect, overlay discovery, hooks
      scopes.sh             # merge + resolve + write config.nix
      nix_profile.sh        # flake update + profile upgrade + MITM probe
      configure.sh          # gh/git/per-scope dispatchers
      profiles.sh           # bash/zsh/pwsh profile setup
      post_install.sh       # setup_common.sh + GC
      summary.sh            # mode detection + final print
    io.sh                   # thin side-effect wrappers (run_nix, run_curl, ...)
```

### Why `nix/lib/phases/` (not `.assets/lib/phases/`)

The existing `.assets/lib/` contains cross-entry-point libraries (`scopes.sh`, `profile_block.sh`, `install_record.sh`) used by both legacy and nix paths. Phase files are Nix-path-specific. Keeping them under `nix/lib/` preserves the existing separation and avoids polluting `.assets/lib/` with files only one entry point uses.

---

## Shared state contract

To keep phases sourceable + independently testable, declare the shared variables explicitly at the top of `setup.sh` and document ownership:

| Variable                                                                                                                                                                   | Owner                      | Readers                                  | Notes                                   |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------------------------------- | --------------------------------------- |
| `SCRIPT_ROOT`, `NIX_SRC`, `CONFIGURE_DIR`, `ENV_DIR`, `CONFIG_NIX`                                                                                                         | `setup.sh`                 | all phases                               | Constants, set once                     |
| `NIX_ENV_VERSION`, `NIX_ENV_PLATFORM`, `NIX_ENV_PHASE`, `NIX_ENV_SCOPES`                                                                                                   | `setup.sh`/platform/scopes | all phases + hooks                       | Exported for hooks                      |
| `_scope_set`, `sorted_scopes`                                                                                                                                              | `scopes.sh` (lib)          | scopes, configure, post_install, summary | Bash 3.2 space-delimited string + array |
| `_ir_phase`, `_ir_error`, `_ir_skip`                                                                                                                                       | setup.sh                   | all phases + EXIT trap                   | Phase tracking                          |
| `omp_theme`, `starship_theme`, `skip_gh_auth`, `skip_gh_ssh_key`, `skip_git_config`, `update_modules`, `upgrade_packages`, `quiet_summary`, `remove_scopes[]`, `any_scope` | bootstrap (arg parser)     | scopes, nix_profile, configure, summary  | CLI flag results                        |
| `PINNED_REV`, `OVERLAY_DIR`                                                                                                                                                | nix_profile, platform      | various                                  | Derived state                           |
| `_mode`, `platform`                                                                                                                                                        | summary, platform          | summary, trap                            | Mode/OS label                           |

Rule: each phase function documents its globals in a header comment. Example:

```bash
# phase_scopes_resolve
# Reads:  CONFIG_NIX, any_scope, remove_scopes, omp_theme, starship_theme
# Writes: _scope_set, sorted_scopes, NIX_ENV_SCOPES, _ir_phase
# Calls:  scope_add, scope_del, scope_has, resolve_scope_deps, sort_scopes
phase_scopes_resolve() {
  ...
}
```

---

## Per-phase extraction

### `lib/phases/bootstrap.sh`

Functions:

- `phase_bootstrap_check_root` - EUID guard.
- `phase_bootstrap_resolve_paths` - sets `SCRIPT_ROOT`, `NIX_ENV_VERSION`, `NIX_SRC`, `CONFIGURE_DIR`, `ENV_DIR`, `CONFIG_NIX`. Accepts `${BASH_SOURCE[0]}` via arg so tests can pass a fixture path.
- `phase_bootstrap_detect_nix` - sources `nix-daemon.sh` or `nix.sh`, fallback PATH add. Returns 0 if nix present, 1 otherwise (setter of `_ir_error`).
- `phase_bootstrap_verify_store` - `nix store info` probe.
- `phase_bootstrap_sync_env_dir` - `mkdir -p`, `cp` flake/scopes/nx_doctor.
- `phase_bootstrap_install_jq` - writes minimal `config.nix` with `isInit=true; scopes=[]`, runs `nix profile add` + `upgrade`. Only if `! command -v jq`.
- `phase_bootstrap_parse_args "$@"` - the big `while` loop. Sets all the flag globals. **Testable:** call with fixture args, inspect globals.

### `lib/phases/platform.sh`

- `phase_platform_detect` - sets `platform`, exports `NIX_ENV_PLATFORM`.
- `phase_platform_discover_overlay` - determines `OVERLAY_DIR`, copies overlay scopes.
- `phase_platform_run_hooks <dir>` - move `_run_hooks` here (tiny but cohesive).

### `lib/phases/scopes.sh` (orchestrator phase, not the library)

Distinct from `.assets/lib/scopes.sh` (the shared scope-set library). This wraps the library for the Nix path.

- `phase_scopes_load_existing` - `nix eval` on existing `config.nix`, populates `_scope_set`. Falls back to system detection when no config. **Testable:** inject `_run_nix_eval` stub.
- `phase_scopes_apply_removes` - iterates `remove_scopes[]`.
- `phase_scopes_enforce_prompt_exclusivity` - omp vs starship logic.
- `phase_scopes_resolve_and_sort` - wrapper around lib functions; exports `NIX_ENV_SCOPES`.
- `phase_scopes_write_config` - writes `config.nix` with resolved scopes + `isInit` detection. **Testable:** already has bats coverage via `generate_config_nix` helper; this just moves the logic into the script where tests can call it directly instead of duplicating it.
- `phase_scopes_detect_init` - extracts `has_system_cmd` + `is_init=true/false` logic.

### `lib/phases/nix_profile.sh`

- `should_update_flake <env_dir> <upgrade_flag>` - already a function, move as-is. bats already tests this via sed extraction; after this refactor it sources cleanly.
- `phase_nix_profile_load_pinned_rev` - reads `pinned_rev`.
- `phase_nix_profile_print_mode` - the info/warn messages before the update.
- `phase_nix_profile_update_flake` - calls `nix flake update` or `nix flake lock --override-input` based on `PINNED_REV`.
- `phase_nix_profile_apply` - `nix profile add` + `upgrade`.
- `phase_nix_profile_mitm_probe` - the `curl google.com` check + `cert_intercept` call. Extract the probe URL as `NIX_ENV_TLS_PROBE_URL` (ties into the earlier review recommendation; zero extra work if done here).

### `lib/phases/configure.sh`

- `phase_configure_gh <skip_auth> <skip_ssh>` - invokes `gh.sh`, exports `GITHUB_TOKEN`.
- `phase_configure_git <skip>` - conditional `git.sh`.
- `phase_configure_per_scope` - the `case` dispatch loop over `sorted_scopes[]`.

### `lib/phases/profiles.sh`

- `phase_profiles_bash` - `profiles.sh`.
- `phase_profiles_zsh` - conditional on `command -v zsh`.
- `phase_profiles_pwsh` - conditional on `command -v pwsh`.

### `lib/phases/post_install.sh`

- `phase_post_install_common <update_modules> <scopes...>` - invokes `setup_common.sh` with or without `--update-modules`.
- `phase_post_install_gc` - `wipe-history` + `store gc`.

### `lib/phases/summary.sh`

- `phase_summary_detect_mode` - sets `_mode` from flag state.
- `phase_summary_print` - the final coloured output + shell-specific restart hint.

### `lib/io.sh` (side-effect wrappers)

Thin shims that tests can override by redefining the function before sourcing the phase:

```bash
_io_nix()        { nix "$@"; }
_io_nix_eval()   { nix eval --impure --raw --expr "$1"; }
_io_curl_probe() { curl -sS "$1" >/dev/null 2>&1; }
_io_run()        { "$@"; }                 # for configure/*.sh invocations
```

Phases call `_io_nix profile upgrade nix-env` instead of `nix profile upgrade nix-env`. Tests define `_io_nix() { echo "nix $*" >>"$TEST_LOG"; }` before sourcing to assert the right commands are issued without executing them.

This replaces the current bats approach (stubbing via PATH) with a cleaner in-process hook.

---

## Slim `setup.sh` (target)

```bash
#!/usr/bin/env bash
# (runnable examples block unchanged)
set -eo pipefail

# ---- resolve paths ----
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="$SCRIPT_ROOT/nix/lib"

# ---- source libraries ----
# shellcheck source=nix/lib/io.sh
source "$LIB_DIR/io.sh"
for p in bootstrap platform scopes nix_profile configure profiles post_install summary; do
  # shellcheck source=/dev/null
  source "$LIB_DIR/phases/$p.sh"
done
# shellcheck source=.assets/lib/install_record.sh
source "$SCRIPT_ROOT/.assets/lib/install_record.sh"
# shellcheck source=.assets/lib/scopes.sh
source "$SCRIPT_ROOT/.assets/lib/scopes.sh"

# ---- trap + provenance ----
_IR_ENTRY_POINT="nix"
_IR_SCRIPT_ROOT="$SCRIPT_ROOT"
_ir_phase="bootstrap"
_ir_skip=false
trap _on_exit EXIT  # _on_exit stays in setup.sh (needs all globals)

# ---- run phases ----
phase_bootstrap_check_root
phase_bootstrap_resolve_paths
phase_bootstrap_parse_args "$@"       # handles --help by setting _ir_skip + exit
phase_bootstrap_detect_nix
phase_bootstrap_verify_store
phase_bootstrap_sync_env_dir
phase_bootstrap_install_jq

phase_platform_detect
_ir_phase="pre-setup"
phase_platform_run_hooks "$ENV_DIR/hooks/pre-setup.d"
phase_platform_discover_overlay

_ir_phase="scope-resolve"
phase_scopes_load_existing
phase_scopes_apply_removes
phase_scopes_enforce_prompt_exclusivity
phase_scopes_resolve_and_sort
phase_scopes_detect_init
phase_scopes_write_config

_ir_phase="nix-profile"
phase_nix_profile_load_pinned_rev
phase_nix_profile_print_mode
phase_nix_profile_update_flake
phase_nix_profile_apply
phase_nix_profile_mitm_probe

_ir_phase="configure"
phase_configure_gh "$skip_gh_auth" "$skip_gh_ssh_key"
phase_configure_git "$skip_git_config"
phase_configure_per_scope

_ir_phase="profiles"
phase_profiles_bash
phase_profiles_zsh
phase_profiles_pwsh
_ir_phase="post-setup"
phase_platform_run_hooks "$ENV_DIR/hooks/post-setup.d"

_ir_phase="post-install"
phase_post_install_common "$update_modules" "${sorted_scopes[@]}"

_ir_phase="complete"
phase_post_install_gc
phase_summary_detect_mode
phase_summary_print
```

Result: ~120 lines, reads as a phase-by-phase narrative. Each line is one unit.

---

## Unit testability

### Before (current state)

```bash
_load_should_update_flake() {
  eval "$(sed -n '/^should_update_flake()/,/^}/p' "$REPO_ROOT/nix/setup.sh")"
}
```

This only works for self-contained functions with no dependencies. `phase_scopes_write_config`, `phase_bootstrap_parse_args`, etc. cannot be extracted this way because they reference other functions defined elsewhere in the file.

### After

```bash
setup() {
  export REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  export ENV_DIR="$(mktemp -d)"
  export CONFIG_NIX="$ENV_DIR/config.nix"

  # stub side effects
  _io_nix() { echo "nix $*" >>"$BATS_TEST_TMPDIR/nix.log"; }
  _io_nix_eval() { cat "$BATS_TEST_TMPDIR/nix_eval_fixture"; }

  # shellcheck source=../../nix/lib/io.sh
  source "$REPO_ROOT/nix/lib/io.sh"
  source "$REPO_ROOT/.assets/lib/scopes.sh"
  source "$REPO_ROOT/nix/lib/phases/scopes.sh"
}

@test "phase_scopes_write_config: produces isInit=true when jq not system-installed" {
  _scope_set=" shell "
  sorted_scopes=(shell)
  # fake: no system jq
  has_system_cmd() { return 1; }
  phase_scopes_detect_init
  phase_scopes_write_config
  grep -q 'isInit = true' "$CONFIG_NIX"
}

@test "phase_nix_profile_apply: runs profile add + upgrade" {
  phase_nix_profile_apply
  grep -q 'nix profile add path:' "$BATS_TEST_TMPDIR/nix.log"
  grep -q 'nix profile upgrade nix-env' "$BATS_TEST_TMPDIR/nix.log"
}
```

### New tests unlocked

| Test                                                                               | Not possible today              | Possible after                                                                 |
| ---------------------------------------------------------------------------------- | ------------------------------- | ------------------------------------------------------------------------------ |
| Arg parser handles `--remove a b c` without swallowing next flag                   | No (requires full setup.sh run) | Yes (call `phase_bootstrap_parse_args --remove a b c --pwsh`, inspect globals) |
| `phase_scopes_load_existing` falls back to system detection when `nix eval` fails  | No                              | Yes (stub `_io_nix_eval` to return error)                                      |
| `phase_nix_profile_update_flake` uses `--override-input` when `pinned_rev` present | No                              | Yes (create `pinned_rev` file, assert log)                                     |
| `phase_nix_profile_mitm_probe` skips when probe succeeds                           | No                              | Yes (stub `_io_curl_probe` to return 0)                                        |
| `phase_summary_print` emits correct restart hint per shell                         | No                              | Yes (stub `$PPID`/`ps`, inspect stdout)                                        |
| `phase_configure_per_scope` invokes `omp.sh` only when `oh_my_posh` in scopes      | No                              | Yes (stub `_io_run`, inspect log)                                              |
| `phase_bootstrap_install_jq` no-ops when `jq` present                              | No                              | Yes                                                                            |

### Tests preserved

All existing `test_nix_setup.bats` tests keep working. The `_load_should_update_flake` helper becomes a trivial `source "$REPO_ROOT/nix/lib/phases/nix_profile.sh"`.

---

## Migration steps (in order, each a separate commit)

1. **Create `nix/lib/io.sh`** with the side-effect wrappers. No callers yet. (zero risk)
2. **Create `nix/lib/phases/` directory** with empty stub files. Wire them into `setup.sh` via `source` but keep all logic inline for now. Verify CI passes. (zero risk)
3. **Extract `should_update_flake` + `has_system_cmd`** into `nix_profile.sh` / `scopes.sh`. Update `test_nix_setup.bats` to source the file instead of `sed`-extracting. Verify. (low risk - already tested)
4. **Extract `phase_bootstrap_parse_args`**. Add bats tests for every flag. High value: arg parsing has zero tests today. (medium risk, highest test payoff)
5. **Extract `phase_scopes_*` group.** The `generate_config_nix` helper in bats becomes a direct call to `phase_scopes_write_config`. (medium risk)
6. **Extract `phase_nix_profile_*` group.** Introduce `_io_nix`/`_io_nix_eval`/`_io_curl_probe` calls. This is the phase with the most side effects; test via stubbed io.sh. (medium risk)
7. **Extract `phase_configure_*`, `phase_profiles_*`, `phase_post_install_*`, `phase_summary_*`.** Smaller cohesive chunks; bulk of line-count reduction. (low risk per step)
8. **Move `phase_platform_*` and the pre/post-hook runners.** (low risk)
9. **Final pass:** verify `setup.sh` is ~120 lines, run full CI matrix (linux daemon, linux no-daemon, macOS, WSL where applicable), confirm `install.json` output unchanged on a real run.
10. **Update `ARCHITECTURE.md`**: add phase library to runtime layout section, document the `_io_*` stub convention for tests.

Each step is individually revertable. No step requires simultaneous changes to `setup.sh` + tests + CI.

---

## Risks & mitigations

| Risk                                                            | Mitigation                                                                                                                                                   |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| EXIT trap loses variables when phases `return` non-zero         | Keep `set -eo pipefail` (no `-u`), keep trap in `setup.sh`. Phases that expect failure must explicitly `                                                     |
| Sourcing order matters (later phases depend on earlier globals) | Document in header comment of each phase file. Add a `check_deps` hook that asserts required globals are set (can be noop in production, validated in test). |
| Bash 3.2: `local -n` namerefs unavailable for passing arrays    | Phases that need arrays read `sorted_scopes` global directly (already the pattern). Document as part of the state contract.                                  |
| Cross-platform `source` path differences                        | Use `${BASH_SOURCE[0]}` resolution consistently. `scopes.sh` already does this.                                                                              |
| Hidden dependency on function ordering in `setup.sh`            | Run full bats suite after each migration step. CI already covers daemon/no-daemon/macOS.                                                                     |
| Increased file count hurts discoverability                      | `ARCHITECTURE.md` runtime layout table lists every phase file with purpose. Grep for `phase_` finds all entry points.                                        |

---

## What this does NOT do

- Does not change behavior, flags, or exit codes.
- Does not add `--unattended` mode. Separate work item from the review's Must-do list.
- Does not pin nixpkgs by default. Separate work item.
- Does not add fleet telemetry. Separate work item.
- Does not port to Go/Rust. If the answer becomes "rewrite," the phase boundaries drawn here become the module boundaries there. Either way, this refactor is not wasted.

---

## Effort estimate

| Step                                        | Effort                |
| ------------------------------------------- | --------------------- |
| 1-2 (scaffolding)                           | 0.5 h                 |
| 3 (nix_profile extraction + test cleanup)   | 1 h                   |
| 4 (arg parser + new tests)                  | 3 h                   |
| 5 (scopes phase)                            | 2 h                   |
| 6 (nix_profile phase + io stubs)            | 2 h                   |
| 7 (configure/profiles/post_install/summary) | 2 h                   |
| 8 (platform + hooks)                        | 1 h                   |
| 9 (CI validation, fix fallout)              | 1.5 h                 |
| 10 (ARCHITECTURE.md update)                 | 0.5 h                 |
| **Total**                                   | **~13.5 h (~2 days)** |

Net new test surface: ~20-30 bats tests covering paths that today are completely untested (arg parser, config loading with corrupt config.nix, MITM probe behavior, per-scope dispatch correctness).

---

## Recommendation

Execute this before the `--unattended` and pinned-nixpkgs work items. Reason: those items will add flag-handling and state branches. Refactoring first means those features land in a structure that supports test coverage from day one, rather than being added to a 700+ line script and retrofitted with tests later.
