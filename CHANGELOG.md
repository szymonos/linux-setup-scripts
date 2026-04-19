# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added

- Nix-based cross-platform setup with scope system (`nix/setup.sh`)
- Declarative `nx` CLI for bash and PowerShell (`aliases_nix.sh`, `_aliases_nix.ps1`)
- `devenv` command for bash, zsh, and PowerShell
- Installation provenance record (`~/.config/dev-env/install.json`)
- Managed block pattern for shell profile injection (`manage_block`)
- Managed env block for cert env vars and local PATH (`env_block.sh`)
- Shared CA bundle builder and VS Code Server cert setup (`certs.sh`)
- Explicit upgrade semantics (`--upgrade` flag, `nx upgrade`)
- Scope dependency resolution and validation (`scopes.sh`, `scopes.json`)
- Oh-my-posh and starship prompt integration with mutual exclusivity
- Linux CI workflow (daemon + no-daemon matrix)
- macOS CI workflow (Determinate installer)
- Uninstaller with env-only mode (`nix/uninstall.sh`)
- BATS and Pester unit testing with pre-commit hooks
- BSD sed lint enforcement in pre-commit hook (`check_bash32`)
- `NIX_ENV_VERSION` and `NIX_ENV_SCOPES` environment variable exports
- `VERSION` file fallback for tarball installs (no `.git` directory)
- ARCHITECTURE.md with file classification, call tree, and design decisions
- Corporate proxy documentation (`docs/corporate_proxy.md`)
- `nx doctor` health checks (8 checks, `--json` output)
- `# bins:` comments in scope `.nix` files as single source of truth for expected binaries
- Pre-setup and post-setup hook directories (`~/.config/nix-env/hooks/`)
- Overlay directory for local customization (`~/.config/nix-env/local/` or `$NIX_ENV_OVERLAY_DIR`)
- `nx overlay list` and `nx overlay status` commands
- `nx scope add <name>` for creating custom overlay scopes
- SUPPORT.md with platform support matrix

### Fixed

- BSD sed grouped-command violations across all nix-path scripts
- Bash 3.2 compatibility (no mapfile, no associative arrays, no namerefs)
- Uninstaller cleanup for env-only and full removal modes
