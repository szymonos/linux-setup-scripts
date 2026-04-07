# Node.js.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "nodejs" config.scopes.enabled) {
    home.packages = with pkgs; [
      nodejs
    ];
  };
}
