# Python tooling — python itself is managed by uv/conda, not nix.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "python" config.scopes.enabled) {
    home.packages = with pkgs; [
      uv
      prek
    ];
  };
}
