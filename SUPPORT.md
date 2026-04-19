# Support matrix

## Platforms

| Platform                      | Setup path     | Status      |
| ----------------------------- | -------------- | ----------- |
| macOS (Apple Silicon + Intel) | `nix/setup.sh` | Supported   |
| Ubuntu / Debian               | `nix/setup.sh` | Supported   |
| Fedora / RHEL                 | `nix/setup.sh` | Supported   |
| OpenSUSE                      | `nix/setup.sh` | Supported   |
| WSL (any distro)              | `nix/setup.sh` | Supported   |
| Arch Linux                    | `nix/setup.sh` | Best-effort |
| Alpine Linux                  | `nix/setup.sh` | Best-effort |

## Shell versions

| Shell      | Minimum version | Notes                                               |
| ---------- | --------------- | --------------------------------------------------- |
| bash       | 3.2             | macOS system default; no mapfile/associative arrays |
| zsh        | 5.0             | macOS system default                                |
| PowerShell | 7.4             | Installed via `--pwsh` scope                        |

## Nix

| Requirement     | Value                                                                      |
| --------------- | -------------------------------------------------------------------------- |
| Minimum version | 2.18                                                                       |
| Recommended     | Latest from [Determinate Systems](https://install.determinate.systems/nix) |
| Flakes          | Required (enabled by default with Determinate installer)                   |
| Daemon mode     | Supported (recommended)                                                    |
| No-daemon mode  | Supported (rootless containers)                                            |

## Reporting issues

Run `nx doctor --json` and include the output when reporting problems.
