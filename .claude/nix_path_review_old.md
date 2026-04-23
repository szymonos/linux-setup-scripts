# Nix-path solution review

Cross-platform dev environment setup (WSL, macOS, Coder) - brutally honest evaluation.

## TL;DR verdict

**Solid personal/team tool, enterprise-ready for standalone use.** Architecture is sound and above average for shell-based dotfiles automation. All critical weaknesses resolved: managed block profile injection, explicit upgrade semantics, hidden sudo removed, bash 3.2 lint enforcement, error handling, macOS + Linux CI, config overlay system, `nx doctor` diagnostics. Remaining gaps: release distribution (tarball + CI), user-facing documentation, external dep pinning. ~92/100.

---

## Strengths (genuinely good)

1. **Right core choice.** Nix + a generated `flake.nix` + `buildEnv` per scope is the correct backbone for cross-platform (macOS/Linux/WSL/Coder) reproducibility. Most "company setup scripts" reach for Homebrew + apt + chocolatey wrappers; you skipped that swamp.
2. **Clean separation of durable state vs. transient repo** (`~/.config/nix-env/` survives repo deletion). This is the single best architectural decision in the repo.
3. **Scope abstraction with JSON-defined deps + install order** (`scopes.json` + `scopes.sh`) is a nice declarative kernel inside an otherwise imperative codebase. Bash 3.2 / BSD compat discipline is documented and enforced - genuinely rare.
4. **Deliberate `set -eo pipefail` (no `-u`) in nix-path scripts.** Bash 3.2 treats empty arrays as unset under `set -u`, causing spurious failures. ShellCheck catches uninitialized variables at lint time - a stronger guard. Documented as a design decision in `ARCHITECTURE.md`.
5. **MITM/corporate proxy story is unusually thoughtful.** `cert_intercept`, `fixcertpy`, the `NODE_EXTRA_CA_CERTS` / `REQUESTS_CA_BUNDLE` / `CLOUDSDK_*` matrix, auto-detection on connection failure, Linux symlink vs. macOS merged-bundle - this is the part most enterprise scripts get badly wrong, and you got it right.
6. **No-root by default** for the Nix path. Critical for managed corporate machines and Coder workspaces.
7. **`nx` CLI** (apt-like wrapper around `nix profile` + `packages.nix`) is a real productivity win and a smart way to give users an escape hatch without breaking the declarative model.
8. **Tests exist** (bats + Pester + Docker smoke for both legacy and nix paths). Above-average for this category of repo.
9. **Idempotent, additive scope merging** with explicit `--remove`. Most setup scripts are write-once disasters.

---

## Weaknesses (the brutal part)

### 1. ~~The bash configurators are a footgun at scale~~ - RESOLVED

Managed block pattern implemented. See `ARCHITECTURE.md` "Managed block pattern".
Files rewritten: `profiles.sh`, `profiles.zsh`, `profiles.ps1`. Library:
`.assets/lib/profile_block.sh`. CLI: `nx profile doctor/migrate/uninstall`.
Tests: `test_profile_block.bats` (23), `test_profile_migration.bats` (14).

### 2. Three competing prompts and two competing python managers in the same scope graph

`oh_my_posh` vs `starship`, `conda` vs `uv`, optional pwsh vs bash vs zsh, plus `aliases_kubectl.sh` is 52 KB. This is a personal dotfiles taste tree, not a company baseline. For "big company distributable" you need:

- A **base profile** that's enforced and minimal.
- Optional **personality scopes** that users can opt into.
- Right now base + opinions are tangled.

### 3. Personal-repo coupling

`setup_common.sh` clones `szymonos/ps-modules` from GitHub at install time. For a company tool this is unacceptable: pinning, auditing, mirroring, and offline installs all break. Same for the live `https://search.nixos.org/backend/...` call hard-coded in `nx search` (will break the day they version-bump the index).

### 4. ~~Bash 3.2 + BSD constraint applied unevenly~~ - RESOLVED

Pre-commit hook `tests/hooks/check_bash32.py` now statically enforces bash 3.2 /
BSD sed rules on all nix-path files **and bats tests** (which also run on macOS CI).
Includes BSD sed grouped-command rule (`sed { cmd }` on one line). All `.ps1` shebangs
fixed to `#!/usr/bin/env pwsh` for macOS portability; bash callers use `pwsh -nop`
explicitly. Wired in `.pre-commit-config.yaml`.

### 5. ~~Nix daemon bootstrapping with `sudo setsid` (setup.sh:124-125)~~ - RESOLVED

Removed entirely. The script now fails with a diagnostic message if `nix store info`
is unreachable. WSL has systemd, macOS uses Determinate installer (launchd), Coder
uses `--no-daemon`. No scenario requires runtime daemon start from the setup script.

### 6. ~~Error handling is inconsistent~~ - PARTIALLY RESOLVED

`|| true` instances audited. Four problematic cases (silent `nix flake update` failure,
`fixcertpy` failure, `conda init` failure) replaced with `|| warn "..."` to surface errors
without killing the script. Remaining `|| true` instances are legitimate `set -e` guards
(e.g., `[ -x ] && alias || true`, `grep -c` returning 1 on no match).
Installation provenance (`install.json`) now captures failure state, phase, and error via
EXIT trap across all entry points. Full `nx doctor` still TODO.

### 7. ~~No explicit upgrade control or rollback path~~ - RESOLVED

`setup.sh` no longer runs `nix flake update` implicitly. New `--upgrade` flag and
`should_update_flake()` function gate updates on first run or explicit request.
`nx upgrade` available as shell alias. Per-user `flake.lock` in `$ENV_DIR`.
Tested in `test_nix_setup.bats` (4 tests). Documented in `ARCHITECTURE.md`
under "Design decisions".

### 8. Distribution model is unclear

How does Acme Corp consume this? Fork the repo? Vendor it? `curl | bash` an installer? Right now the answer is "git clone and run `nix/setup.sh`". For an enterprise tool you need:

- A versioned release artifact (tag + explicit upgrade semantics).
- A one-line bootstrap (`curl ... | sh` that clones a pinned tag).
- An override mechanism for org-specific scopes/configs without forking.

### 9. ~~Config layering missing~~ - RESOLVED

Overlay system implemented: `NIX_ENV_OVERLAY_DIR` or `~/.config/nix-env/local/`
for scope and shell config overlays. Overlay scopes copied with `local_` prefix
to avoid collisions. Hook directories (`pre-setup.d/`, `post-setup.d/`) for
customization without forking. CLI: `nx overlay list`, `nx overlay status`,
`nx scope add`. 18 bats tests. Full org-tier signing/fetch deferred to
enterprise fork.

### 10. ~~Tests don't actually test setup~~ - RESOLVED

**macOS CI** (`test_macos.yml`) passing green. Triggers: `workflow_dispatch`, PR label
`test:macos`, push to labeled PRs (`synchronize`). E2E: Determinate Nix installer,
`setup.sh --shell --python`, core + scope binary verification, managed block check,
idempotency (second run), bats tests, install provenance, uninstaller (`--env-only`).

**Linux CI** (`test_linux.yml`) passing green. Matrix: `ubuntu-latest` (Determinate
daemon) + `ubuntu-slim` (upstream `--no-daemon`). Same E2E pipeline as macOS.
Both workflows have `concurrency` with `cancel-in-progress: true`. Copilot CLI
install skipped in CI (`$CI` env var check) to avoid GitHub API rate limits.

### 11. Documentation is internal-developer-oriented

`ARCHITECTURE.md` and `AGENTS.md` are excellent for contributors. There is **no user-facing "Day 1" doc**: "I'm a new hire on macOS, what do I run?" The README still describes the legacy Linux scripts.

---

## Risks for the "big company" use case

| Risk                                             | Severity   | Notes                                              |
| ------------------------------------------------ | ---------- | -------------------------------------------------- |
| ~~Implicit `flake update` on every run~~         | ~~Medium~~ | RESOLVED - explicit `--upgrade` flag               |
| ~~Hidden `sudo` in no-root script~~              | ~~High~~   | RESOLVED - removed, fail with diagnostic           |
| External GitHub fetches mid-install              | High       | Air-gapped/proxied envs, supply chain              |
| ~~No macOS CI~~                                  | ~~High~~   | RESOLVED - `test_macos.yml` passing green          |
| ~~No Linux CI~~                                  | ~~High~~   | RESOLVED - `test_linux.yml` passing green (matrix) |
| ~~Profile injection cannot be cleanly reverted~~ | ~~Medium~~ | RESOLVED - managed block + `nx profile uninstall`  |
| ~~No org-level config overlay~~                  | ~~Medium~~ | RESOLVED - overlay skeleton + CLI + hooks          |
| ~~`nx search` hits hard-coded NixOS API URL~~    | ~~Low~~    | RESOLVED - uses `nix search nixpkgs` (offline)     |
| 52 KB kubectl aliases                            | Low        | Cosmetic, but signals "personal dotfiles"          |

---

## Recommendations (prioritized)

**Must-do before calling it "company-grade":**

1. ~~**Explicit upgrade semantics.**~~ DONE - `--upgrade` flag, `should_update_flake()`, `nx upgrade`.
2. ~~**Replace shell-rc append-pattern with a single managed block.**~~ DONE - managed block pattern.
3. ~~**Eliminate hidden `sudo`.**~~ DONE - removed, fail with diagnostic.
4. ~~**macOS CI**~~ DONE - `test_macos.yml` passing green. Triggers on `workflow_dispatch`, PR label `test:macos`, and push to labeled PRs. Concurrency cancels stale runs. E2E: nix install, setup.sh, binary verification, managed block check, idempotency, bats tests.
5. **Vendor or pin** `ps-modules` and any other live git fetches; provide an offline mode.
6. ~~**Add a config overlay mechanism.**~~ DONE - overlay skeleton (`NIX_ENV_OVERLAY_DIR` / `local/`), scope copy with `local_` prefix, hook directories, `nx overlay list/status`, `nx scope add`. 18 bats tests.
7. ~~**Add a `nx doctor` / `verify` command.**~~ DONE - 8 health checks, `--json` output, `# bins:` as binary source of truth, 13 bats tests.
8. **Separate "base" from "opinions"**: kubectl aliases / oh-my-posh / zsh plugins move to optional scopes; default install is minimal.
9. **Document a distribution model**: tagged releases + a 1-line bootstrap. Decide whether downstream orgs fork or overlay.

**Should-do:**

1. ~~Static enforcement of bash-3.2 rules.~~ DONE - `check-bash32` pre-commit hook.
2. ~~Replace marker-grep idempotency with deterministic state files.~~ DONE - managed block.
3. Reduce surface: drop unused legacy scripts from contributor cognitive load now, don't wait for "after migration."
4. ~~Telemetry-free, but **structured logs** (JSON option).~~ DONE - `install.json` provenance + `nx doctor --json`.

**Nice-to-have:**

Replace bash configurators with `home-manager` (Nix-native) for the shell-config layer. You're 80% reinventing it. This is the **one decision worth seriously reconsidering**: home-manager would eliminate weaknesses #1 and #6 partially, and give you proper rollback / generations. Cost: zsh/bash dotfile users see a Nix-store path in their `~/.bashrc` source line, which is fine.

---

## Is it the wrong tool?

**No.** Nix is the right tool for the cross-platform package layer. Bash is the right tool for the bootstrap (you can't assume anything else exists). The mismatch is in the **middle layer** (shell-rc / profile configuration) where you're hand-rolling what `home-manager`, `chezmoi`, or even a templated systemd-style drop-in dir would do better. That's a refactor, not a rewrite.

## One-line summary

Architecturally above average, operationally enterprise-ready for standalone use; all critical issues resolved (profile injection, upgrade control, hidden sudo, bash 3.2 lint, error handling, CI, config overlays, diagnostics); remaining work is distribution (release tarball + CI), documentation, and external dep pinning.
