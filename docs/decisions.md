# Design Decisions

Every tool makes architectural choices that shape what it can and cannot do. This page explains the four most consequential decisions in this project - not just what was chosen, but why the obvious alternatives were rejected.

## Why Nix, not Homebrew

**The objection:** "Homebrew works fine, everyone knows it, and it's already installed on most Macs."

Homebrew is an excellent macOS package manager. It is not a cross-platform environment provisioning tool. The differences matter at scale:

| Capability               | Homebrew                         | Nix                                       |
| ------------------------ | -------------------------------- | ----------------------------------------- |
| Atomic rollback          | No                               | Yes (`nix profile rollback`)              |
| Reproducible pins        | No lock file, no version pinning | `flake.lock` + `nx pin set <rev>`         |
| Cross-platform           | macOS-first, Linux second-class  | macOS, Linux, WSL, containers - identical |
| User-scope after install | Requires sudo for updates        | No root after initial install             |
| Package composition      | Flat list, no grouping           | `buildEnv` merges scopes atomically       |
| Binary cache             | Bottles (limited arch coverage)  | 100k+ cached packages, multi-arch         |

Homebrew installs packages. Nix provisions environments - declaratively, atomically, and reproducibly.

**The enterprise off-ramp:** Nix adoption carries organizational risk. [Determinate Systems](https://determinate.systems/nix/macos/mdm/) provides a commercially supported Nix installer with MDM integration (Jamf, Intune), enterprise support contracts, and managed fleet deployment. If the organization decides to formalize Nix adoption, the transition from the open-source installer to the enterprise offering is a configuration change, not a rewrite. The tool is already built on the Determinate Systems installer as its recommended installation method.

## Why not golden images

**The objection:** "Just bake a VM image or container with everything pre-installed, push it to developers."

Golden images are the default enterprise answer to environment standardization. They fail in developer workstation contexts for several reasons:

**WSL cannot be golden-imaged.** Microsoft does not support creating or distributing custom WSL disk images through MDM. WSL is the most popular development environment on enterprise Windows - any solution that cannot provision it is incomplete by definition.

**Images go stale immediately.** A golden image is a snapshot. The day after distribution, packages are outdated. Every update requires a new build-test-distribute cycle through the MDM pipeline. Developers either wait for the next image refresh or install tools manually on top - re-creating the inconsistency the image was supposed to prevent.

**Images cannot handle MITM proxy certificates.** Corporate TLS inspection proxies issue certificates that are per-network and per-site. A golden image baked in a build environment without proxy inspection will fail when a developer connects through the corporate VPN. The proxy certificates must be detected and configured at runtime, on the developer's actual network - not at image build time.

**Images are all-or-nothing.** A data scientist and a platform engineer need different toolchains. Golden images either ship everything (bloated, slow to distribute) or require multiple image variants (multiplied maintenance). Scopes solve this: `--shell --python` for the data scientist, `--shell --k8s-dev --terraform` for the platform engineer, from the same base.

This tool takes the opposite approach: a lightweight bootstrapper that runs on the developer's actual machine, detects the actual network environment, installs exactly what's needed, and stays current via `nx upgrade`. It works on every platform - including WSL - because it provisions rather than snapshots.

## Why bash 3.2 compatibility

**The objection:** "It's 2026. Just require bash 5 and use modern features."

macOS ships bash 3.2 as the system default. Apple will not update it due to GPLv3 licensing. This creates a bootstrapping paradox: **the tool that sets up your environment cannot require you to already have a setup environment.**

If the setup script required bash 5, users would need to install it first - via Homebrew, Nix, or manual compilation. That prerequisite defeats the purpose of a one-command setup tool. The script must work with what the operating system provides out of the box.

The constraint is real and affects daily development:

- No `mapfile` or `readarray` - use `while IFS= read -r` loops
- No associative arrays (`declare -A`) - use space-delimited strings with helper functions
- No case modification (`${var,,}`) - use `tr`
- No namerefs (`declare -n`) - pass variable names as strings
- BSD `sed` and `grep` - no GNU extensions (`\s`, `\w`, `-P`, `-r`)

This is not enforced by convention. A custom pre-commit hook (`check_bash32.py`) scans every nix-path file for bash 4+ constructs and blocks the commit if any are found. The macOS CI workflow validates the constraint on every pull request by running the full setup on a macOS runner with the system bash.

Linux-only scripts (provisioning, system checks) use bash 5 features freely - the constraint applies only to files that run on macOS.

## Why a bootstrapper, not a configuration management agent

**The objection:** "Use Ansible, Chef, or Puppet - that's what configuration management tools are for."

Configuration management tools are designed for servers: homogeneous fleets, root access, persistent agents, central control planes. Developer workstations are the opposite:

| Server fleet            | Developer workstation            |
| ----------------------- | -------------------------------- |
| Homogeneous OS          | macOS + WSL + Linux + Coder      |
| Root access guaranteed  | Managed machines restrict root   |
| Agent runs continuously | No daemon, no background process |
| Central server required | Works offline after setup        |
| IT-managed              | Developer-managed                |

Ansible requires Python and SSH. Chef requires a server and a Ruby agent. Puppet requires a daemon and a control plane. All three assume root access and target a single OS distribution per playbook/recipe/manifest. None handle the cross-platform, user-scope, rootless requirements of developer workstations.

This tool is a **bootstrapper**: it runs once, provisions a self-contained environment in `~/.config/nix-env/`, and exits. No daemon, no server, no runtime dependency. After setup:

- `nx upgrade` updates packages - no central server needed
- `nx rollback` reverts if something breaks - no IT ticket needed
- `nx doctor` runs health checks - no monitoring agent needed
- The repository clone is disposable - all state is local

The bootstrapper model means zero operational overhead: no agent to monitor, no server to maintain, no network dependency for day-to-day use. The tool provisions the environment and gets out of the way.
