# Pre-scope base packages needed before scope resolution.
# On WSL/Linux jq is bootstrapped by nix/setup.sh; curl is a system prerequisite.
{ pkgs }: with pkgs; [
  jq
]
