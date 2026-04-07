# Azure CLI + azcopy.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "az" config.scopes.enabled) {
    home.packages = with pkgs; [
      azure-cli
      azure-storage-azcopy
    ];
  };
}
