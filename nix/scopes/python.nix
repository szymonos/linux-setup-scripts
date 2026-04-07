# Python tooling - python itself is managed by uv/conda, not nix
{ pkgs }: with pkgs; [
  uv
  prek
]
