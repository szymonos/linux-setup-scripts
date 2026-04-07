# Zsh plugins.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "zsh" config.scopes.enabled) {
    home.packages = with pkgs; [
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-completions
    ];
  };
}
