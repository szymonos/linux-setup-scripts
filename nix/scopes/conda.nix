# Conda/Miniforge — installed via official installer, not nix.
# This scope exists for dependency resolution and triggers configure/conda.sh.
{ config, lib, ... }:

{
  # no nix packages — miniforge is installed via its own installer
}
