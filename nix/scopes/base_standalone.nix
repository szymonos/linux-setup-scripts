# Extra base packages for standalone setups (macOS, Coder).
# On WSL/Linux these are installed system-wide.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.scopes.isStandalone {
    home.packages = with pkgs; [
      curl
      jq
    ];
  };
}
