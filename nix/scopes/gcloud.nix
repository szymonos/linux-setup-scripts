# Google Cloud CLI.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "gcloud" config.scopes.enabled) {
    home.packages = with pkgs; [
      google-cloud-sdk
    ];
  };
}
