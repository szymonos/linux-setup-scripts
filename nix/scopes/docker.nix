# Docker — installed traditionally (requires root), not via nix.
# This scope exists for dependency resolution and triggers configure/docker.sh.
{ config, lib, ... }:

{
  # no nix packages — docker requires root and is installed system-wide
}
