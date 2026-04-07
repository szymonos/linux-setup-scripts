# Terraform utilities.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "terraform" config.scopes.enabled) {
    home.packages = with pkgs; [
      terraform
      tflint
    ];
  };
}
