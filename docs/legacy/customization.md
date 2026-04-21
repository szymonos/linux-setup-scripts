# Customization guide

How packages are organized, how to add your own, and how to manage
upgrades and rollbacks.

## Package layers

Packages are assembled from four layers, evaluated bottom-up by the
Nix flake. Each layer has a different purpose and audience:

```text
┌─────────────────────────────────────────────────┐
│  4. Extra packages  (packages.nix)              │  nx install / nx remove
│     Ad-hoc packages added by the user.          │  Quickest way to add a package.
├─────────────────────────────────────────────────┤
│  3. Overlay scopes  (local_*.nix)               │  nx scope add / overlay dir
│     Custom scope groups from an overlay dir.    │  For grouping packages or
│     Can be personal, team, or org-maintained    │  distributing to a team.
│     depending on where the overlay dir points.  │
├─────────────────────────────────────────────────┤
│  2. Repo scopes  (shell.nix, python.nix, ...)   │  nix/setup.sh --shell --python
│     Curated scope groups shipped with the repo. │  The standard dev environment.
├─────────────────────────────────────────────────┤
│  1. Base  (base.nix)                            │  Always included.
│     Core tools: git, jq, curl, coreutils, ...   │  Cannot be disabled.
└─────────────────────────────────────────────────┘
```

All four layers merge into a single `buildEnv` - one nix profile entry,
one `nix profile upgrade` to apply. No layer can shadow or break another.

Layer 3 serves different roles depending on who maintains the overlay
directory:

- **Solo user** - defaults to `~/.config/nix-env/local/`, personal tools
- **Team** - `NIX_ENV_OVERLAY_DIR` points to a shared git repo with
  team-specific scopes, aliases, and hooks
- **Organization** - same mechanism, org-maintained repo distributed
  via MDM or onboarding scripts

Currently one overlay directory is active at a time. Multi-tier stacking
(org + team + personal overlays simultaneously) is possible through the
hooks mechanism - an org-level pre-setup hook can copy org scopes before
the team overlay is processed - but first-class multi-tier support is
planned for the enterprise integration phase.

### Layer 1: Base (always installed)

`nix/scopes/base.nix` - core utilities (git, jq, curl, coreutils, etc.)
included in every installation. You don't interact with this layer.

### Layer 2: Repo scopes (the standard environment)

The built-in scopes shipped with the repo. Selected via `nix/setup.sh`
flags:

```bash
nix/setup.sh --shell --python --pwsh      # add scopes
nix/setup.sh --remove python              # remove a scope
nix/setup.sh                              # re-apply existing scopes
```

Each scope is a `.nix` file in `nix/scopes/` - e.g., `shell.nix` provides
fzf, eza, bat, ripgrep; `python.nix` provides uv. Scopes can depend on
each other (e.g., `k8s_dev` pulls in `k8s_base`).

See all available scopes with `nix/setup.sh --help`.

### Layer 3: Overlay scopes (custom groups)

For packages that don't belong in the upstream repo - personal tools,
team-specific CLIs, org-wide utilities. Overlay scopes live in a separate
directory and are copied into `~/.config/nix-env/scopes/` with a `local_`
prefix to avoid name collisions with repo scopes.

```bash
# Create a scope and add packages in one step (validates against nixpkgs)
nx scope add devtools httpie jq

# Add more packages to an existing scope
nx scope add devtools bat

# Open a scope in your editor for manual editing
nx scope edit devtools
```

Package names are validated against nixpkgs before being added - typos
and non-existent packages are caught immediately.

The scope file is standard Nix:

```nix
{ pkgs }: with pkgs; [
  bat
  httpie
  jq
]
```

After manual edits via `nx scope edit`, run `nx upgrade` to apply.

**Why a separate overlay directory?** The overlay dir is a *source* that
survives repo updates. When `nix/setup.sh` runs, it copies the repo's
scope files into `~/.config/nix-env/scopes/`, overwriting anything there.
Overlay scopes live outside the repo's scope directory (in `local/`) so
they are never overwritten, and the `local_` prefix ensures they never
collide with a repo scope of the same name.

### Layer 4: Extra packages (ad-hoc)

The simplest way to add a package - no scopes, no files to edit:

```bash
nx install httpie jq       # validates + adds packages
nx remove httpie           # remove a package
nx list                    # see everything installed, by layer
```

Package names are validated against nixpkgs before being added.
Packages are stored in `~/.config/nix-env/packages.nix` as a flat list.
Changes are applied immediately (no `nx upgrade` needed).

Use this for one-off tools. If you find yourself adding many related
packages, consider creating a scope instead (layer 3).

## Overlay directory

The overlay directory is where custom scopes, shell configs, and hooks
live. It is resolved in this order:

1. `NIX_ENV_OVERLAY_DIR` environment variable (if set and exists)
2. `~/.config/nix-env/local/` (default fallback)

### Structure

```text
~/.config/nix-env/local/          # or $NIX_ENV_OVERLAY_DIR
├── scopes/                       # custom scope files (→ local_*.nix)
│   └── devtools.nix
├── bash_cfg/                     # extra bash config (sourced on login)
│   └── aliases_custom.sh
└── hooks/
    ├── pre-setup.d/              # run before nix/setup.sh main logic
    │   └── check_vpn.sh
    └── post-setup.d/             # run after nix/setup.sh completes
        └── notify_slack.sh
```

- **Scopes** are copied with `local_` prefix during `nix/setup.sh` or
  `nx scope add`.
- **Shell configs** in `bash_cfg/` are sourced alongside the standard
  configs.
- **Hooks** run during `nix/setup.sh` at the indicated phase. They receive
  `NIX_ENV_PHASE`, `NIX_ENV_SCOPES`, and `NIX_ENV_PLATFORM` as environment
  variables.

### Managing overlays

```bash
nx overlay list      # show overlay directory contents
nx overlay status    # show sync status (synced / modified / source missing)
```

### Sharing with a team

Point everyone at a shared overlay directory (e.g., a separate git repo):

```bash
# In ~/.bashrc or ~/.zshenv, before the managed block
export NIX_ENV_OVERLAY_DIR="$HOME/src/team-nix-overlay"
```

The shared repo can contain team-specific scopes, shell aliases, and
setup hooks. Each user can still use `nx install` (layer 4) for personal
additions on top.

For multi-tier distribution (org + team + personal), the overlay hooks
mechanism can chain: an org-level hook can copy org scopes, then the
team overlay adds team scopes, and the user's `packages.nix` adds
individual packages.

## Pinning nixpkgs - coordinated package versions

### Why pin?

By default, `nx upgrade` pulls the latest `nixpkgs-unstable`. Despite the
name, `nixpkgs-unstable` is not random - it is a branch where every commit
is a deterministic snapshot of ~100k packages at specific versions. When your
`flake.lock` points to commit `abc123`, you get exactly `ripgrep 14.1.0`,
`python 3.12.3`, `bat 0.24.0` etc. - every time, on every machine.

Without a pin, each `nx upgrade` resolves to whatever the latest commit
happens to be at that moment. This is fine for solo use, but in a team it
causes "works on my machine" issues when people upgrade on different days.

**Pinning** locks `nx upgrade` to a specific nixpkgs commit. Everyone who
shares the same pin gets identical package versions, regardless of when
they upgrade.

### Typical workflow

```bash
# 1. Upgrade and verify everything works
nx upgrade

# 2. Pin the current (tested) revision
nx pin set

# 3. Future upgrades will stay on this revision until the pin is removed
nx upgrade   # uses the pinned rev, not latest

# 4. Remove the pin when ready to move forward
nx pin remove
```

### Commands

```bash
nx pin set          # Pin to the current flake.lock revision
nx pin set <rev>    # Pin to a specific nixpkgs commit SHA
nx pin show         # Show current pin (or "no pin set")
nx pin remove       # Remove the pin, go back to latest unstable
```

The pin is stored in `~/.config/nix-env/pinned_rev` - a single file
containing the commit SHA. No shell profile changes needed.

### How it works

When `~/.config/nix-env/pinned_rev` exists:

- `nx upgrade` and `nix/setup.sh --upgrade` use
  `nix flake lock --override-input` to lock nixpkgs to that exact commit
  instead of resolving the latest.
- Regular runs without `--upgrade` are unaffected - they use the existing
  `flake.lock` as-is.

When the file does **not** exist, upgrades resolve the latest
`nixpkgs-unstable` as before.

### Team-wide pinning

For a team, distribute the pin via a pre-setup hook in a shared overlay:

```bash
# overlay-dir/hooks/pre-setup.d/pin_nixpkgs.sh
# Write the team-wide pin before setup runs
echo "abc123..." > "$HOME/.config/nix-env/pinned_rev"
```

Or include `pinned_rev` directly in your shared overlay directory and
copy it during setup. When IT validates a new nixpkgs revision, they
update the hook - everyone gets the tested baseline on next upgrade.

## Rolling back

If an upgrade breaks something, roll back to the previous generation:

```bash
nx rollback
```

This wraps `nix profile rollback` and reverts to the previous set of
packages. Restart your shell after rolling back.

To inspect what changed between generations:

```bash
nix profile diff-closures
```

To clean up old generations after confirming the new one works:

```bash
nx gc
```

## Quick reference

| Task                       | Command                              |
| -------------------------- | ------------------------------------ |
| Add a package              | `nx install <pkg>`                   |
| Remove a package           | `nx remove <pkg>`                    |
| List all packages          | `nx list`                            |
| Search nixpkgs             | `nx search <term>`                   |
| Create a scope with pkgs   | `nx scope add <name> <pkg> [pkg...]` |
| Add packages to a scope    | `nx scope add <name> <pkg> [pkg...]` |
| Edit a scope file          | `nx scope edit <name>`               |
| List overlay contents      | `nx overlay list`                    |
| Check overlay sync status  | `nx overlay status`                  |
| Upgrade to latest packages | `nx upgrade`                         |
| Pin current revision       | `nx pin set`                         |
| Show / remove pin          | `nx pin show` / `nx pin remove`      |
| Roll back last upgrade     | `nx rollback`                        |
| See what changed           | `nix profile diff-closures`          |
| Clean up old generations   | `nx gc`                              |
| Run health checks          | `nx doctor`                          |
