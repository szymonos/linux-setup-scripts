# Base packages — always installed regardless of scopes.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bash-completion
    cacert
    coreutils
    findutils
    gawk
    gnupg
    git
    gh
    less
    nmap
    openssl
    shfmt
    tig
    tree
    unzip
    vim
    wget
    whois
  ];
}
