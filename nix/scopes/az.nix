# Azure CLI installed via uv (see nix/configure/az.sh); azcopy via Nix
{ pkgs }: with pkgs; [
  azure-storage-azcopy
]
