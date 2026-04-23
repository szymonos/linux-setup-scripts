# Enterprise integration notes

Reference document for future enterprise/IDP integration. **Nothing here
is implemented in this repo.** This repo stays generic and IDP-agnostic.
Enterprise-specific work belongs in a company organization fork.

## Three-tier config composition

Inspired by Kubernetes Kustomize, Nix overlays, and systemd drop-ins.

```text
Base (this repo, immutable)
  + Org overlay (distributed by IT, read-only to user)
    + User overlay (writable, ~/.config/nix-env/local/)
```

The base repo provides the overlay skeleton (directory discovery, scope
copy with `local_` prefix, hook directories). The org tier and its
distribution/signing infrastructure are enterprise-specific.

### Extension points (already working for base + user tiers)

| Extension point | Base location              | Overlay location                |
| --------------- | -------------------------- | ------------------------------- |
| Nix scopes      | `nix/scopes/*.nix`         | `<overlay>/scopes/*.nix`        |
| Shell aliases   | `.assets/config/bash_cfg/` | `<overlay>/bash_cfg/`           |
| Post-install    | `nix/configure/*.sh`       | `<overlay>/hooks/post-setup.d/` |

### What the org tier adds (not implemented)

- Signed overlay tarballs distributed via artifact store
- `overlay.yaml` metadata (name, version, min-core-version)
- `policy.yaml` (ban/require scopes)
- `scopes.json` deep-merge (arrays unioned, dependency_rules appended)
- Multi-tier hook ordering (base -> org -> user, lexical within tier)

## IDP consumption model

The tool modeled as a first-class catalog entity in the IDP:

- **Discovery** via catalog search
- **Onboarding** via self-service template emitting a personalized,
  pinned bootstrap command
- **Day-two** via `nx upgrade` or IDP-emitted upgrade commands
- **Fleet visibility** via aggregated opt-in telemetry from `nx doctor`

The IDP is a **control plane**, not a runtime. The laptop must never
hard-depend on IDP reachability to install, upgrade, or self-heal.

### Consumption tiers

| Tier            | Who                       | How                                     |
| --------------- | ------------------------- | --------------------------------------- |
| Individual      | Personal macOS/Linux      | `git clone` or release tarball          |
| Corporate fleet | Coder, WSL, managed macOS | Artifact store + org overlay + env vars |
| Contributor     | Repo maintainer           | `git clone` + `make test`               |

## Reserved environment variables

These are **not wired up** in the upstream repo. Semantics depend on
enterprise decisions.

| Variable                       | Purpose                      | Decided by |
| ------------------------------ | ---------------------------- | ---------- |
| `NIX_ENV_OVERLAY_URL`          | Signed overlay fetch URL     | IDP team   |
| `NIX_ENV_OVERLAY_PUBKEY`       | Overlay signature public key | IDP team   |
| `NIX_ENV_TELEMETRY_URL`        | Opt-in telemetry endpoint    | IDP team   |
| `NIX_ENV_TELEMETRY`            | `off` (default) / `on`       | IDP team   |
| `NIX_ENV_DISABLE_USER_OVERLAY` | Disable user-scope overlay   | IT policy  |
| `NIX_ENV_CACHE_DIR`            | Override `~/.cache/nix-env`  | user       |

## Decision checklist for IDP/platform team

Before implementing enterprise integration in the fork:

1. **Catalog schema** -- which IDP (Backstage, Port, other)? Determines
   `metadata.yaml` / `catalog-info.yaml` shape.
2. **Overlay distribution** -- artifact store URL? OCI registry? Git
   submodule? Determines `NIX_ENV_OVERLAY_URL` semantics.
3. **Signing infrastructure** -- minisign, Sigstore, or corp CA?
   Determines `NIX_ENV_OVERLAY_PUBKEY` format.
4. **Telemetry contract** -- what data, where it goes, privacy
   guarantees, mandatory vs. opt-in. Determines telemetry variables.
5. **Policy enforcement** -- can org overlays ban/require scopes? What
   is the override model? Determines `policy.yaml` schema.

## Implementation items (all in company fork)

| Item                      | Blocked on      | Notes                              |
| ------------------------- | --------------- | ---------------------------------- |
| `metadata.yaml`           | Decision 1      | Shape depends on IDP choice        |
| Reserved env var warnings | All 5 decisions | Can't warn on undefined semantics  |
| `dist/fetch_overlay.sh`   | Decisions 2 + 3 | Download + verify org overlay      |
| `nx overlay fetch`        | Decisions 2 + 3 | CLI command to refresh org overlay |
| Telemetry reporting       | Decision 4      | `nx` commands emit events          |
| Policy enforcement        | Decision 5      | `policy.yaml` in org overlay       |
| `scopes.json` deep-merge  | Decision 2      | jq-based merge of base + org       |
| Multi-tier hook ordering  | Decision 2      | Base -> org -> user hook execution |

## What the upstream repo already provides

These are the building blocks the enterprise fork will consume:

- **Version identity** -- git tags, `NIX_ENV_VERSION`, VERSION file in
  release tarballs
- **Health checks** -- `nx doctor --json` usable by any monitoring
- **Hook directories** -- org customization without forking
- **Overlay skeleton** -- `NIX_ENV_OVERLAY_DIR` for org scope/config
  injection
- **Install provenance** -- `install.json` for audit trails
- **Release tarballs** -- versioned artifacts for any artifact store
- **Managed env var namespace** -- `NIX_ENV_*` reserved for future use

## Scenarios

### A: Small team pilot

Catalog entry + TechDocs + static bootstrap pointing at artifact store.
Hours of work. No custom plugin, no telemetry.

### B: Enterprise rollout

Custom IDP surface, mandatory telemetry on company-owned devices, fleet
dashboard, staged rollouts via release labels.

### C: No IDP

The tool works fine standalone. Catalog + docs + scaffolder is enough for
discoverability. Everything above is optional.

### D: Another org adopts without Backstage

Plain `install.sh` + artifact mirror. The upstream repo must stay
IDP-agnostic; all IDP integration lives downstream.
