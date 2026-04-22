# Design Decisions

Every tool makes architectural choices that shape what it can and cannot do. This page explains the reasoning behind the key decisions in this project - not just what was chosen, but why the obvious alternatives were rejected.

## Architecture decisions

### Why Nix, not Homebrew

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

### Why not golden images

**The objection:** "Just bake a VM image or container with everything pre-installed, push it to developers."

Golden images are the default enterprise answer to environment standardization. They fail in developer workstation contexts for several reasons:

**WSL golden images require disproportionate effort.** Building a custom WSL disk image is technically possible, but it demands a custom build pipeline, manual distribution, and ongoing maintenance - significantly more effort than a bootstrapper that provisions WSL in minutes from a single PowerShell command. WSL is the most popular development environment on enterprise Windows; any solution that cannot provision it easily is incomplete in practice.

**Images go stale immediately.** A golden image is a snapshot. The day after distribution, packages are outdated. Every update requires a new build-test-distribute cycle through the MDM pipeline. Developers either wait for the next image refresh or install tools manually on top - re-creating the inconsistency the image was supposed to prevent.

**Images solve certificates at the wrong layer.** A golden image can ship with corporate CA certificates pre-installed, covering the OS trust store and some frameworks. But certificates expire - when they do, every deployed image needs a rebuild or a separate automation to rotate certs, which is exactly the tooling this solution already provides. More fundamentally, golden images resolve certificate trust at the system level and for some framework-level paths, but not all execution paths. An application not launched via bash will not see environment variables set in a bash profile. Different frameworks consult different certificate stores. This tool resolves MITM certificate issues at runtime, independently of how each framework is launched, covering execution paths that images cannot reach.

**Images cannot handle diverse network environments.** Vendors and contractors typically cannot receive golden images - they work on their own hardware. This solution is far more accessible: clone the repo, run the setup. Additionally, contractors connecting through external networks often encounter different MITM certificate chains than internal employees. A golden image baked against the internal proxy will fail on a contractor's network. Runtime certificate interception handles both scenarios transparently.

**Images are all-or-nothing.** A data scientist and a platform engineer need different toolchains. Golden images either ship everything (bloated, slow to distribute) or require multiple image variants (multiplied maintenance). Scopes solve this: `--shell --python` for the data scientist, `--shell --k8s-dev --terraform` for the platform engineer, from the same base.

This tool takes the opposite approach: a lightweight bootstrapper that runs on the developer's actual machine, detects the actual network environment, installs exactly what's needed, and stays current via `nx upgrade`. It works on every platform - including WSL - because it provisions rather than snapshots.

### Why a bootstrapper, not a configuration management agent

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

## Implementation decisions

### Why bash 3.2 compatibility

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

### Why oh-my-posh and starship, not oh-my-zsh

**The objection:** "Oh-my-zsh works great for me - it has hundreds of themes and plugins."

Oh-my-zsh is a zsh framework. That is exactly the problem:

| Capability          | oh-my-zsh          | oh-my-posh / starship                    |
| ------------------- | ------------------ | ---------------------------------------- |
| Shell support       | zsh only           | bash, zsh, PowerShell, fish, cmd, nu     |
| Platform parity     | Requires zsh setup | Works on any shell the platform ships    |
| Startup performance | Plugin-dependent   | Single binary, sub-50ms prompt render    |
| Configuration       | ~/.zshrc framework | Standalone config file, no shell lock-in |

A cross-platform tool that standardizes the developer experience cannot anchor its prompt to a single shell. Developers on this tool use bash on Coder, zsh on macOS, and PowerShell on Windows - often all three in the same week. Oh-my-posh and starship render an identical prompt across all of them from a single theme file.

Both engines are offered as opt-in scopes rather than forcing one choice:

- **oh-my-posh** (Go, mature ecosystem, rich themes) - default recommendation for macOS and WSL where startup latency is less critical
- **starship** (Rust, faster cold-start) - preferred on Coder where container startup time matters and resource budgets are tighter

The scopes are mutually exclusive at runtime (`--omp-theme` removes starship and vice versa) but both remain available. This lets teams standardize on a prompt engine while respecting environment-specific trade-offs.

### Why managed blocks, not append-style profile injection

**The objection:** "Just append a line to `.bashrc` - it's simpler."

The `grep -q 'pattern' || echo 'line' >> ~/.bashrc` pattern is the most common approach to shell profile configuration. It is also the most fragile:

- Running setup twice appends duplicate entries unless the grep is perfectly maintained
- Removing configuration requires manual editing or fragile `sed` deletion
- Uninstallation leaves orphaned lines that can cause errors after the tool is removed
- There is no way to update configuration in place - only append more

This tool uses a **managed block** pattern instead. Configuration is written between sentinel markers (`# >>> nix-env managed >>>` / `# <<< nix-env managed <<<`) and fully regenerated on each run:

- **Idempotent** - running setup any number of times produces identical results, validated by CI on every PR
- **Updatable** - the block is replaced atomically, not appended to
- **Removable** - `nix/uninstall.sh` deletes the block cleanly, leaving the rest of the profile intact
- **Diagnosable** - `nx doctor` detects duplicate or missing blocks

The same pattern is implemented for PowerShell via `#region`/`#endregion` markers and `Update-ProfileRegion`. Two block types separate nix-specific config (removed on uninstall) from generic config (certs, local PATH - preserved after uninstall).

### Why phase-based orchestration with side-effect stubs

**The objection:** "It's a setup script - just write it top to bottom."

A 600-line bash script written top-to-bottom is untestable by definition. Functions cannot be sourced in isolation, side effects execute on import, and tests resort to brittle `sed` extraction to test individual functions.

This tool uses a **phase library** architecture: `nix/setup.sh` is a slim ~110-line orchestrator that sources independent phase files from `nix/lib/phases/`. Each phase exports functions with documented inputs and outputs (`# Reads:` / `# Writes:` header comments). Side-effecting operations (nix commands, curl probes, external script invocations) are routed through thin wrappers in `nix/lib/io.sh`:

```bash
_io_nix()        { nix "$@"; }
_io_curl_probe() { curl -sS "$1" >/dev/null 2>&1; }
_io_run()        { "$@"; }
```

Tests override these wrappers by function redefinition before sourcing the phase under test - three lines per test, zero framework overhead:

```bash
setup() {
  _io_nix() { echo "nix $*" >>"$BATS_TEST_TMPDIR/nix.log"; }
  source "$REPO_ROOT/nix/lib/io.sh"
  source "$REPO_ROOT/nix/lib/phases/nix_profile.sh"
}
```

This pattern makes bash scripts testable at a level normally associated with compiled languages - without mocking frameworks, without PATH manipulation, without subprocess overhead. It is the reason this project has 412 test cases across 22 test files for what is, at its core, a shell script.

### Why JSON as the shared schema format

**The objection:** "Bash scripts should use bash-native data formats."

Scope metadata (valid names, install order, dependency rules) lives in a single `scopes.json` consumed by three runtimes:

| Consumer   | Parser             |
| ---------- | ------------------ |
| bash       | `jq`               |
| PowerShell | `ConvertFrom-Json` |
| Python     | `json` stdlib      |

JSON is the only format all three parse natively without a custom parser. Alternatives (bash-sourceable data, TSV, INI) would force either a fragile parallel parser in PowerShell/Python or a source-of-truth split between bash-data and JSON-data. A single source of truth means scope definitions are always consistent across `nix/setup.sh`, `wsl/wsl_setup.ps1`, and the `validate_scopes.py` pre-commit hook.

The only cost is that bash 3.2 on a bare macOS has no JSON parser, so `jq` must be bootstrapped before scope resolution can run. This is handled by a minimal `base_init.nix` scope (~13 lines) that installs `jq` on first run and is skipped on all subsequent runs - a bounded, one-time cost for a permanent architectural benefit.
