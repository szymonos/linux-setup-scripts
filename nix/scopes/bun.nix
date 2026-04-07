# Bun — JavaScript/TypeScript runtime.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "bun" config.scopes.enabled) {
    home.packages = with pkgs; [
      bun
    ];
  };
}
