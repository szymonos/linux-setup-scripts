# PowerShell.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "pwsh" config.scopes.enabled) {
    home.packages = with pkgs; [
      powershell
    ];
  };
}
