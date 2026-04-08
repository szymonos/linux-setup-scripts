# Base packages - always installed
{ pkgs }: with pkgs; [
  bash-completion
  cacert
  coreutils
  fd
  findutils
  gawk
  gnupg
  git
  gh
  bind          # provides dig, nslookup, host
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
]
