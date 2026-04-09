# Cross-platform dev environment aliases for tools installed via Nix.
# Checks ~/.nix-profile/bin/ - works on macOS, Linux, WSL, and Coder.
# Sourced from ~/.bashrc and ~/.zshrc by nix/configure/profiles.sh.

_nb="$HOME/.nix-profile/bin"

if [ -x "$_nb/eza" ]; then
  alias eza='eza -g --color=auto --time-style=long-iso --group-directories-first --color-scale=all --git-repos'
  alias l='eza -1'
  alias lsa='eza -a'
  alias ll='eza -lah'
  alias lt='eza -Th'
  alias lta='eza -aTh --git-ignore'
  alias ltd='eza -DTh'
  alias ltad='eza -aDTh --git-ignore'
  alias llt='eza -lTh'
  alias llta='eza -laTh --git-ignore'
else
  alias l='ls -1'
  alias lsa='ls -a'
  alias ll='ls -lah'
fi

[ -x "$_nb/bat" ] && alias batp='bat -pP' || true
[ -x "$_nb/rg" ] && alias rg='rg --ignore-case' || true
[ -x "$_nb/fastfetch" ] && alias ff='fastfetch' || true
[ -x "$_nb/pwsh" ] && alias pwsh='pwsh -NoProfileLoadTime' && alias p='pwsh -NoProfileLoadTime' || true
[ -x "$_nb/kubectx" ] && alias kc='kubectx' || true
[ -x "$_nb/kubens" ] && alias kn='kubens' || true
[ -x "$_nb/kubecolor" ] && alias kubectl='kubecolor' || true

unset _nb
