# Nix Path Architectural Review

**Author:** Review of the Nix setup path for cross-platform (WSL, macOS, Coder) machine provisioning.
**Date:** April 2026
**Scope:** `nix/setup.sh`, flake architecture, scope system, and integration strategy for enterprise distribution.

---

## Executive Summary

**Verdict: Strong engineering. Enterprise distribution layer is the gap, not the code.**

Code quality is **8/10** - above-average for ops tooling with proper error handling, test coverage, explicit design trade-offs in `ARCHITECTURE.md`, and deliberate multi-language schema design (`scopes.json` consumed natively by bash/PowerShell/Python). Engineering decisions show genuine enterprise experience (MITM proxy handling, install provenance, managed blocks, portable bash 3.2). Ceiling is ~9/10 after end-to-end integration tests and phase extraction from `setup.sh`.

Enterprise fit is **6/10** because **the entire solution is contingent on Nix being approvable in the target organization**. Coder compatibility is validated (no-daemon CI matrix), macOS is validated (Determinate installer workflow), but the enterprise distribution layer - fleet pinning, unattended mode, MDM integration, telemetry contract - is absent by design (deferred to downstream fork per `enterprise_notes.md`). Reaches 7/10 after the four Must-do items, 8/10 after Phase 1 + MDM PoC. Ceiling is ~8/10 for the base repo; the enterprise fork is where 9-10 lives.

---

## Strengths

### Architecture & Documentation

- **`ARCHITECTURE.md` is exceptional.** File ownership is classified by runtime constraint (bash 3.2, bash 4+, nix-only), call tree is documented, runtime paths cataloged, design trade-offs with rejected alternatives (`pip-system-certs` vs `fixcertpy`, `NODE_OPTIONS` vs `NODE_EXTRA_CA_CERTS`). This is rare-most internal tooling lacks this rigor. The codebase is maintainable by someone other than the author.
- **Layering is clean.** Orchestration (`setup.sh`) → declarative package definition (`flake.nix`) → scope lists (`.nix` files) → tool-specific setup (`configure/*.sh`). Adding a new tool is low friction: one `.nix` file + optional `configure/tool.sh`.
- **Idempotent managed-block pattern** (`profile_block.sh`) is the correct solution vs. `grep -q && echo >>` append-spam. `uninstall.sh` actually works because configuration is regenerated, not deleted.
- **JSON as shared schema across three language runtimes.** `scopes.json` is consumed natively by bash (via `jq`), PowerShell (`ConvertFrom-Json`), and Python (stdlib `json`). This is the correct choice for the multi-language reality: a `.nix` source of truth would force PS and Python consumers to shell out to Nix or re-implement attrset parsing. The bootstrap cost of installing `jq` before the first scope resolution is bounded to ~13 lines in `base_init.nix` and documented in `ARCHITECTURE.md`.

### Operations & Observability

- **Provenance via EXIT trap** (`install_record.sh`) writes structured `install.json` with entry point, scopes, phase, and status. Enables fleet debugging that most internal tools lack.
- **Health surface with classification** (`nx doctor`): 8 checks with FAIL/WARN distinction. `# bins:` comments are the single source of truth-validated by pre-commit hook `validate_scopes.py`. Proper observability design.
- **Extension points are well-placed**: `$NIX_ENV_OVERLAY_DIR` for org customization, `pre-setup.d/` and `post-setup.d/` hooks for tool-specific setup, `pinned_rev` for fleet cohort pinning. The `enterprise_notes.md` roadmap is realistic and doesn't over-claim.

### Quality & Discipline

- **Bash 3.2 constraint enforced via pre-commit** (`check_bash32.py`). Most projects claim "portable bash" and drift silently. This one actually stays true.
- **Test coverage exists** (13 bats test files, 9 Pester suites). Uncommon for ops tooling. CI validates daemon + no-daemon on Linux, Determinate installer on macOS.
- **Explicit design rationale**: `set -eo pipefail` without `-u` (bash 3.2 array handling), dual prompt engines (oh-my-posh for latency-insensitive macOS/WSL, starship for Coder), dual Python managers (conda for binary packages, uv for venv workflows), corporate proxy MITM detection with tool-specific env vars.

### Enterprise Readiness

- **MITM proxy handling** (`setup.sh:474-479`, `docs/corporate_proxy.md`) shows real corporate network experience. Intercepts certificates, sets `NODE_EXTRA_CA_CERTS`, `REQUESTS_CA_BUNDLE`, `SSL_CERT_FILE`, `UV_SYSTEM_CERTS`, and VS Code Server `~/.vscode-server/server-env-setup`.
- **Version identity** (`NIX_ENV_VERSION` from git tags → VERSION file in tarballs → `devenv` function) enables fleet tracking.
- **Structured planning** (`implementation_plan.md`) breaks remaining work (Distribution + Docs) into sized phases. Phase 3 (Enterprise/IDP) defers to downstream fork without over-engineering the base.

---

## Weaknesses

### Design

- **`setup.sh` is 590 lines.** Readable now but crossing 500-line threshold suggests extracting phases into `lib/phases/{bootstrap,scope,profile,post}.sh` or porting the orchestrator to a typed language (Go/Rust).

### Enterprise Distribution

- **`nixpkgs-unstable` by default.** The rationale in `ARCHITECTURE.md:279-298` is honest ("target audience values current tooling") but conflicts with "aimed for big company." Enterprise needs SBOMs, reproducibility, supply-chain attestation, staged upgrade cadences. The `pinned_rev` opt-in per-user is not a fleet-level control. **Recommendation:** Default to a pinned revision shipped in the repo; make `unstable` opt-in via `NIX_ENV_UNPIN=1`. Flip the current default.
- **No fleet-level pinning enforcement.** Each user can pin independently (`pinned_rev`), but there's no org-tier pinning. Enterprise rollouts need a "all machines on nixpkgs revision X until signed by IT" contract.
- **Mutation without version guard.** `setup.sh` copies repo files to `~/.config/nix-env/` via `cp` without checking if an older version is already installed. If two repo clones run on one machine, last one wins silently. `NIX_ENV_VERSION` is recorded but not compared on disk.
- **Interactive auth gates unattended rollout.** `gh.sh` and `git.sh` require TTY input by default. `--skip-gh-auth` and `--skip-git-config` exist but are not discoverable. **Recommendation:** Add `--unattended` flag that enables all `--skip-*` flags and fails loudly if anything requires TTY. This is table stakes for MDM/Ansible/Terraform rollouts.
- **No fleet telemetry scaffold.** `install.json` is per-machine. For corporate scale, document a standard `post-setup.d/99-report.sh` pattern that POSTs to an internal endpoint. Don't build telemetry, but make the contract explicit.

### Operations

- **MITM probe uses `curl https://www.google.com`** (`setup.sh:474`). Unreliable: google.com can be blocked independent of TLS inspection, DNS-dependent, ties behavior to a US public domain. **Recommendation:** Make it configurable via `NIX_ENV_TLS_PROBE_URL` with a fallback to `https://nixos.org` (functionally relevant to the user).
- **Silent flake-update failure on network issues** (`setup.sh:462`). Swallows `nix flake update` errors and uses stale lock in corporate networks with flaky egress. `nix profile upgrade` is fatal (correct). This inconsistency can produce mysterious scope-resolution bugs on first run.
- **Mutation of `~/.config/nix-env/` from transient repo.** If repo is deleted after setup, the user's environment is orphaned but `nx doctor` still works (provenance and uninstall.sh survive). This is actually fine once documented, but the "durable state in HOME" design choice should be explicit in README.

### Coverage & Clarity

- **Coder coverage is implicit via the `no-daemon` CI matrix** (`.github/workflows/test_linux.yml`). The rootless single-user Nix install is exactly the Coder/devcontainer scenario (no systemd, no root in the runtime image), so passing that job implies Coder compatibility. A comment has been added to the workflow making this explicit. No dedicated Coder runner is needed - this was initially flagged as a gap in the first-pass review and is retracted.
- **Platform matrix (WSL/macOS/Coder) + Language matrix (bash/PowerShell/Nix) + Constraint matrix (bash 3.2/4+/5+) is high cognitive load.** The `ARCHITECTURE.md` mitigates this, but the matrix itself is the real risk. Simplifying would help (e.g., "bash 5+ everywhere except macOS system sh," "PowerShell only on WSL host").
- **Legacy path still shipped.** Coexistence increases surface. The `entry_point` taxonomy (`legacy/nix`, `wsl/legacy`) signals it will live longer than "until migrated." Every month it lives doubles the test matrix and maintenance burden.

### Testing

- **No "happy path" integration test spanning all 3 platforms.** bats unit tests validate functions, but the trap/phase/profile-block interactions are integration-level. CI should run `nix/setup.sh --all` end-to-end on macOS-latest, ubuntu-latest, and one WSL image.
- **PowerShell tests (9 Pester suites) but unclear coverage of `profiles.ps1` + profile block injection.** Does it test the `Update-ProfileRegion` idempotence across re-runs?

---

## Risks for Enterprise Distribution

### Risk 1: Nix Adoption (Highest Impact)

**If Nix is not approvable in your organization, this entire path is moot.** This is not a code risk; it's a strategic risk. The determinate-systems installer URL alone may be blocked by firewalls. Security teams may reject Nix for supply-chain concerns (Nix builds are hermetic but not auditable at the package level; nixpkgs has 80k+ packages with minimal CNA coverage).

**Mitigation:** Validate Nix approval with InfoSec/Platform first. If rejected, pivot to `mise`, `devbox`, or static tarballs before further investment.

### Risk 2: macOS Security & MDM

Nix on managed macOS (Jamf/Kandji) requires special handling: SIP (System Integrity Protection) restrictions, Gatekeeper notarization, daemon vs. single-user install trade-offs. Not shown in this repo; every org I've seen needed custom PKG wrapping.

**Mitigation:** Early PoC on your MDM. Contact determinate-systems for MDM guidance.

### Risk 3: Upstream Drift

`nixpkgs-unstable` + post-install scripts that call `gh auth`, `git config`, `az login`, etc. Any upstream CLI option change breaks you. No pinning on tool behavior.

**Mitigation:** Vendor a snapshot of critical tool configs into the overlay. Pre-commit hooks to validate gh/git/az --help output doesn't change in ways we depend on.

### Risk 4: WSL Distro Diversity

Supporting Fedora/Debian/Ubuntu/Arch/OpenSUSE/Alpine is generous but pays a maintenance tax for optionality most corporate WSL fleets won't use. WSL community officially supports Ubuntu and Debian.

**Mitigation:** Pick one primary distro for corporate rollout. Keep code generality but test only 1-2 distros in CI.

### Risk 5: No Rollback Story

`nx rollback` only rolls back nix profiles. Configuration changes (profile blocks, certs, VS Code server env) aren't snapshotted. A failed setup run can leave the shell in an inconsistent state.

**Mitigation:** Document the recovery procedure (which phase failed, restore from install.json, re-run). Consider versioning the profile block format.

### Risk 6: Docs Gap

`customization.md` exists but doesn't answer "how do I distribute a pre-configured overlay via our MDM?" Developers deploying to 500 machines need an answer to that.

**Mitigation:** Prioritize `docs/ops/` tier in Phase 2. Include MDM examples (Jamf, Kandji, Intune) even if they're off-repo.

---

## Specific Recommendations

### Must-do (blocks enterprise use)

1. **Validate Nix assumption.** Confirm with InfoSec/Platform that Nix is acceptable and `install.determinate.systems` is reachable. Nothing else matters if this fails.
2. **Default to pinned nixpkgs.** Add `nix/default_rev` (or bake the SHA into `flake.nix`). Make unstable opt-in via flag. Flip the current default.
3. **First-class `--unattended` mode.** Sets all `--skip-*`, fails on TTY requirement. Required for MDM/Ansible/Terraform.
4. **Replace MITM probe URL.** Make `NIX_ENV_TLS_PROBE_URL` configurable; default to a functionally relevant target (not google.com).

### Should-do (unblocks enterprise patterns)

1. **Add fleet telemetry scaffold.** Document `post-setup.d/99-report.sh` pattern. Don't implement, but standardize the contract.
2. **Version-on-disk check.** Refuse to overwrite `~/.config/nix-env/` from an older `NIX_ENV_VERSION` without `--force-downgrade`.
3. **Extract `setup.sh` phases.** Once crossing 600 lines, move to `lib/phases/{bootstrap,scope,profile,post}.sh` or typed language.
4. **End-to-end integration test.** CI should run `nix/setup.sh --all` across macOS, Linux, and WSL.

### Nice-to-have (quality)

1. **Simplify the platform/language matrix.** Document which combinations are actually tested: macOS via Determinate installer, Linux daemon mode, Linux no-daemon mode (which covers Coder / rootless containers). PowerShell only on WSL host. Kill unnecessary branches.
2. **Migrate legacy path to separate repo or tag it for deletion.** Every month it lives doubles maintenance.
3. **Close the WSL-from-Windows end-to-end gap.** `test_linux.yml` already validates Linux daemon + rootless/Coder; macOS has its own workflow. The remaining untested path is `wsl_setup.ps1` orchestrating from a Windows host.

---

## What's Already Right

Do not change these:

- **Managed-block pattern.** It's correct. Don't revert to append-style.
- **Explicit EXIT trap for provenance.** This is good observability.
- **Overlay skeleton + hook directories.** These are the right extension points.
- **Platform-specific prompt engines.** Both oh-my-posh and starship serve real use cases.
- **`nx doctor` health checks.** The FAIL/WARN classification and `# bins:` as source of truth are solid.
- **Bash 3.2 discipline with pre-commit enforcement.** Rare and valuable.

---

## Implementation Roadmap

Based on `implementation_plan.md`, the path to enterprise readiness is:

| Phase    | Work                                                            | Effort | Blocker?                         |
| -------- | --------------------------------------------------------------- | ------ | -------------------------------- |
| Pre-work | Validate Nix approval                                           | 0.5 d  | YES                              |
| 1        | Release tarball + CI                                            | 1.5 d  | No (but needed for distribution) |
| 2        | User/ops docs + README                                          | 1 d    | No (helps adoption)              |
| 3        | Enterprise fork work (IDP, overlay fetch, telemetry, policy)    | TBD    | No (deferred to downstream)      |
| Gaps     | Fleet pinning, unattended mode, MITM URL, version-on-disk guard | ~2 d   | No (but improves enterprise UX)  |

**Recommended order:**

1. Nix approval validation (decision-gate)
2. Gaps above (enterprise UX improvements, ~2 days)
3. Phase 1 (distribution, ~1.5 days)
4. Phase 2 (docs, ~1 day)
5. Enterprise fork starts (reference implementation in `enterprise_notes.md`)

Total: ~5.5 days of work if Nix is approved.

---

## Bottom Line

**The engineering is good. The architecture is thoughtful. The documentation is exemplary.**

The success of this tool is **not** determined by code quality-it's determined by whether your organization approves Nix and invests in the enterprise integration layer (fleet pinning, overlay distribution, telemetry, unattended deployment). The base repo doesn't need major refactoring, but it does need:

- **Decision gates** (Nix approval, MDM PoC)
- **Enterprise defaults** (pinned nixpkgs, unattended mode, fleet telemetry)
- **Distribution infrastructure** (Phase 1-2, then downstream fork)

If Nix is approved: **Invest in the gaps above, build Phase 1-2, then fork.** This is worth the effort.

If Nix is not approved: **Evaluate `mise`, `devbox`, or static tarball approaches instead.** No refactor to this code saves you if the foundational assumption fails.
