# Docker requires root and is installed traditionally (not via nix).
# This scope only triggers configure/docker.sh for post-install checks.
# bins: docker
{ pkgs }: [ ]
