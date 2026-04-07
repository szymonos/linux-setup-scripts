# Shell tools — fzf, eza, bat, ripgrep, yq.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "shell" config.scopes.enabled) {
    home.packages = with pkgs; [
      fzf
      eza
      bat
      ripgrep
      yq-go
    ];
  };
}
