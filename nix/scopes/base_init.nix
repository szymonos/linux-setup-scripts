# Pre-scope base packages (curl, jq) needed before scope resolution.
# On WSL/Linux these are installed system-wide by install_nix.sh.
{ pkgs }: with pkgs; [
  curl
  jq
]
