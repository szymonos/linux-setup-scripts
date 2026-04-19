# Python tooling - python itself is managed by uv/conda, not nix
# bins: uv prek
{ pkgs }: with pkgs; [
  uv
  prek
]
