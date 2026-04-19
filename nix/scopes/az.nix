# Azure CLI installed via uv (see nix/configure/az.sh); azcopy via Nix
# bins: azcopy
{ pkgs }: with pkgs; [
  azure-storage-azcopy
]
