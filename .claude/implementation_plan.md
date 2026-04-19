# Implementation plan

Remaining work for the nix-env setup tool. Organized by independence from
enterprise infrastructure. Each phase is self-contained; phases can be
done in any order but are listed by priority.

## Completed

All standalone tool improvements are implemented and tested.

| Area             | What was done                                                           |
| ---------------- | ----------------------------------------------------------------------- |
| Version identity | CHANGELOG.md, `NIX_ENV_VERSION`/`NIX_ENV_SCOPES` exports, VERSION file  |
| Upgrade control  | `--upgrade` flag, `should_update_flake()`, `nx upgrade`                 |
| Provenance       | `install.json` EXIT trap across all entry points, `devenv`/`nx version` |
| Diagnostics      | `nx doctor` (8 checks, `--json`), `# bins:` as binary source of truth   |
| Hook system      | `pre-setup.d/` and `post-setup.d/` hook directories in `setup.sh`       |
| Overlay system   | Overlay directory discovery, scope copy with `local_` prefix            |
| Overlay CLI      | `nx overlay list`, `nx overlay status`, `nx scope add`                  |
| Shell profiles   | Managed block pattern, `nx profile doctor/migrate/uninstall`            |
| CI               | Linux (daemon + no-daemon matrix), macOS (Determinate installer)        |
| Testing          | bats (5 test files, 60+ tests), Pester, pre-commit hooks                |
| Validation       | `validate_scopes.py` (scopes + bins), `check_bash32.py` (bash 3.2 lint) |
| Docs             | ARCHITECTURE.md, SUPPORT.md, CHANGELOG.md                               |

---

## Phase 1: Distribution

**Goal:** Versioned release artifacts so the tool can be consumed without
`git clone`. Makes the tool shareable, forkable, and artifact-store-ready.

### 1a. Release tarball builder

`scripts/build_release.sh` stamps a `VERSION` file from the git tag into
a minimal archive. Only runtime files are included (nix/, .assets/lib/,
.assets/config/, setup_common.sh, install_copilot.sh). Excludes tests,
Docker, Vagrant, legacy scripts, docs. Generates `CHECKSUMS.sha256`.

```bash
scripts/build_release.sh              # version from git tag
VERSION=1.0.0 scripts/build_release.sh  # explicit override
```

**Files:**

- `scripts/build_release.sh` (new)
- `Makefile` (add `release` target)
- `.gitignore` (add `lss-v*.tar.gz`)

### 1b. Release CI workflow

`.github/workflows/release.yml` triggered on `v*` tags:

1. Run test matrix (Linux + macOS).
2. Build tarball via `build_release.sh`.
3. Create GitHub Release with attached artifact + checksums.
4. (Optional, env-gated) Sign with `minisign` if `MINISIGN_KEY` secret
   is configured. Off by default upstream; forks enable it.

**Files:**

- `.github/workflows/release.yml` (new)

**Effort:** ~1.5 days

---

## Phase 2: Documentation

**Goal:** User-facing docs for day-1 onboarding and ops reference.

### 2a. Documentation structure

- `docs/user/` - quickstart ("I'm a new hire on macOS, what do I run?"),
  scope catalog, troubleshooting guide.
- `docs/ops/` - overlay authoring guide, air-gapped install, corporate
  proxy setup (move existing `docs/corporate_proxy.md` here).
- `docs/contrib/` - architecture reference, testing guide, release
  process (complement to ARCHITECTURE.md).

### 2b. README update

Restructure README to lead with the Nix path. Point to `docs/` for
details. De-emphasize legacy Linux scripts.

**Files:**

- `docs/` directory (new)
- `README.md` (update)

**Effort:** ~1 day

---

## Phase 3: Enterprise integration (reference only)

**Not implemented in this repo.** This repo stays generic and
IDP-agnostic. Enterprise-specific integration (IDP catalog, signed
overlay fetch, telemetry, policy enforcement) is deferred to a company
organization fork after legacy path cleanup.

See `enterprise_notes.md` for the full design and the decision checklist
for the platform/IDP team.

**Building blocks already in place** (no enterprise code, but the seams
exist):

| Building block     | Enterprise use case                          |
| ------------------ | -------------------------------------------- |
| Hook directories   | Org hooks without forking                    |
| Overlay skeleton   | `NIX_ENV_OVERLAY_DIR` for org customization  |
| `nx doctor --json` | Machine-readable health for fleet monitoring |
| Install provenance | `install.json` for audit / compliance        |
| Version identity   | `NIX_ENV_VERSION` for fleet version tracking |
| Release tarball    | Distributable artifact for artifact stores   |
| Managed env vars   | `NIX_ENV_*` namespace reserved               |

---

## Effort summary

| Phase | What              | Effort | Status    |
| ----- | ----------------- | ------ | --------- |
| --    | Standalone (w1-4) | 4.5 d  | DONE      |
| 1     | Distribution      | 1.5 d  | --        |
| 2     | Documentation     | 1 d    | --        |
| 3     | Enterprise / IDP  | TBD    | reference |
