# Rice — eye candy / fun tools.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "rice" config.scopes.enabled) {
    home.packages = with pkgs; [
      btop
      cmatrix
      cowsay
      fastfetch
    ];
  };
}
