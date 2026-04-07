# Oh My Posh prompt engine.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "oh_my_posh" config.scopes.enabled) {
    home.packages = with pkgs; [
      oh-my-posh
    ];
  };
}
