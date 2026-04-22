# Design Decisions

Every tool makes architectural choices that shape what it can and cannot do. This page explains the three most consequential decisions in this project - not just what was chosen, but why the obvious alternatives were rejected.

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

Beyond the feature comparison, Nix provides a structural advantage: **store-based isolation**. Every package is installed into a content-addressed path (`/nix/store/<hash>-<name>-<version>/`), so multiple versions of the same tool coexist without conflict and upgrades never leave the system in a half-updated state. Homebrew mutates shared prefixes in-place - an interrupted `brew upgrade` can leave broken symlinks that require manual cleanup. Nix's immutable store makes rollback a pointer swap, not a repair job.

Homebrew installs packages. Nix provisions environments - declaratively, atomically, and reproducibly.

**The enterprise off-ramp:** Nix adoption carries organizational risk. [Determinate Systems](https://determinate.systems/nix/macos/mdm/) provides a commercially supported Nix installer with MDM integration (Jamf, Intune), enterprise support contracts, and managed fleet deployment. If the organization decides to formalize Nix adoption, the transition from the open-source installer to the enterprise offering is a configuration change, not a rewrite. The tool is already built on the Determinate Systems installer as its recommended installation method.

## Why not golden images

**The objection:** "Just bake a VM image or container with everything pre-installed, push it to developers."

Golden images are the default enterprise answer to environment standardization. They fail in developer workstation contexts for several reasons:

**WSL golden images require disproportionate effort.** Building a custom WSL disk image is technically possible, but it demands a custom build pipeline, manual distribution, and ongoing maintenance - significantly more effort than a bootstrapper that provisions WSL in minutes from a single PowerShell command. WSL is the most popular development environment on enterprise Windows; any solution that cannot provision it easily is incomplete in practice.

**Images go stale immediately.** A golden image is a snapshot. The day after distribution, packages are outdated. Every update requires a new build-test-distribute cycle through the MDM pipeline. Developers either wait for the next image refresh or install tools manually on top - re-creating the inconsistency the image was supposed to prevent.

**Images solve certificates at the wrong layer.** A golden image can ship with corporate CA certificates pre-installed, covering the OS trust store and some frameworks. But certificates expire - when they do, every deployed image needs a rebuild or a separate automation to rotate certs, which is exactly the tooling this solution already provides. More fundamentally, golden images resolve certificate trust at the system level and for some framework-level paths, but not all execution paths. An application not launched via bash will not see environment variables set in a bash profile. Different frameworks consult different certificate stores. This tool resolves MITM certificate issues at runtime, independently of how each framework is launched, covering execution paths that images cannot reach.

**Images cannot handle diverse network environments.** Vendors and contractors typically cannot receive golden images - they work on their own hardware. This solution is far more accessible: clone the repo, run the setup. Additionally, contractors connecting through external networks often encounter different MITM certificate chains than internal employees. A golden image baked against the internal proxy will fail on a contractor's network. Runtime certificate interception handles both scenarios transparently.

**Images are all-or-nothing.** A data scientist and a platform engineer need different toolchains. Golden images either ship everything (bloated, slow to distribute) or require multiple image variants (multiplied maintenance). Scopes solve this: `--shell --python` for the data scientist, `--shell --k8s-dev --terraform` for the platform engineer, from the same base.

This tool takes the opposite approach: a lightweight bootstrapper that runs on the developer's actual machine, detects the actual network environment, installs exactly what's needed, and stays current via `nx upgrade`. It works on every platform - including WSL - because it provisions rather than snapshots.

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

The bootstrapper model means zero operational overhead: no agent to monitor, no server to maintain, no network dependency for day-to-day use. The tool provisions the environment and gets out of the way. From there, developers can continue using the repo individually to manage their environment, or teams and organizations can distribute overlays to extend and customize capabilities - without contributing to the upstream repository.
