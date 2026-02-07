#region aliases
export SWD=$(pwd)
alias swd="echo $SWD"
alias cds="cd $SWD"
alias sudo='sudo '
alias _='sudo'
alias please='sudo'
alias -- -='cd -'
alias ..='cd ../'
alias ...='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias .6='cd ../../../../../../'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
alias afind='ack -il'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias c='clear'
alias cd..='cd ../'
alias cic='set completion-ignore-case On'
alias cp='cp -iv'
alias d='bm -d'
alias fix_stty='stty sane'
alias fix_term='printf "\ec"'
alias grep='grep --ignore-case --color=auto'
alias less='less -FRXc'
alias md='mkdir -p'
alias mkdir='mkdir -pv'
alias mv='mv -iv'
alias osr='cat /etc/os-release'
alias nano='nano -W'
alias path='printf "${PATH//:/\\n}\n"'
alias rd='rmdir'
alias show_options='shopt'
alias src='source ~/.bashrc'
alias systemctl='systemctl --no-pager'
alias tree='tree -C'
alias vi='vim'
alias wget='wget -c'

# conditional aliases
if grep -qw '^ID.*\balpine' /etc/os-release 2>/dev/null; then
  alias bsh='/usr/bin/env -i ash --noprofile --norc'
  alias ls='ls -h --color=auto --group-directories-first'
else
  alias bsh='/usr/bin/env -i bash --noprofile --norc'
  alias ip='ip --color=auto'
  alias ls='ls -h --color=auto --group-directories-first --time-style=long-iso'
fi

if [ -x /usr/bin/eza ]; then
  if grep -qw '^ID.*\balpine' /etc/os-release 2>/dev/null; then
    alias eza='eza -g --color=auto --group-directories-first --color-scale=all --git-repos'
  else
    alias eza='eza -g --color=auto --group-directories-first --color-scale=all --git-repos --time-style=long-iso'
  fi
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

if [ -x /usr/bin/bat ]; then
  alias batp='bat -pP'
fi

if [ -x /usr/bin/pwsh ]; then
  alias pwsh='pwsh -NoProfileLoadTime'
  alias p='pwsh -NoProfileLoadTime'
fi

if [ -x /usr/bin/kubectx ]; then
  alias kc='kubectx'
fi

if [ -x /usr/bin/kubens ]; then
  alias kn='kubens'
fi

if [ -x /usr/bin/kubecolor ]; then
  alias kubectl='kubecolor'
fi

[ -x /usr/bin/rg ] && alias rg='rg --ignore-case' || true
[ -x /usr/bin/fastfetch ] && alias ff='fastfetch' || true
[ -x /usr/local/bin/tfswitch ] && alias tfswitch="tfswitch --bin='$HOME/.local/bin/terraform'" || true
#endregion
