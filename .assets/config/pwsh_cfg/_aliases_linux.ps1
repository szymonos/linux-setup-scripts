# *Functions
if ($env:DISTRO_FAMILY -eq 'alpine') {
    function bsh { & /usr/bin/env -i ash --noprofile --norc }
    function ls { & /usr/bin/env ls -h --color=auto --group-directories-first @args }
} else {
    function bsh { & /usr/bin/env -i bash --noprofile --norc }
    function ip { $input | & /usr/bin/env ip --color=auto @args }
    function ls { & /usr/bin/env ls -h --color=auto --group-directories-first --time-style=long-iso @args }
}
function grep { $input | & /usr/bin/env grep --ignore-case --color=auto @args }
function less { $input | & /usr/bin/env less -FRXc @args }
function mkdir { & /usr/bin/env mkdir -pv @args }
function mv { & /usr/bin/env mv -iv @args }
function nano { & /usr/bin/env nano -W @args }
function p { & /usr/bin/env pwsh -NoProfileLoadTime @args }
function tree { & /usr/bin/env tree -C @args }
function wget { & /usr/bin/env wget -c @args }
# conditional alias functions
if (Test-Path '/usr/bin/eza' -PathType Leaf) {
    function eza { & /usr/bin/env eza -g --color=auto --time-style=long-iso --group-directories-first --color-scale=all --git-repos @args }
    function l { eza -1 @args }
    function lsa { eza -a @args }
    function ll { eza -lah @args }
    function lt { eza -Th @args }
    function lta { eza -aTh --git-ignore @args }
    function ltd { eza -DTh @args }
    function ltad { eza -aDTh --git-ignore @args }
    function llt { eza -lTh @args }
    function llta { eza -laTh --git-ignore @args }
} else {
    function l { ls -1 @args }
    function lsa { ls -a @args }
    function ll { ls -lah @args }
}
if (Test-Path '/usr/bin/rg' -PathType Leaf) {
    function rg { $input | & /usr/bin/env rg --ignore-case @args }
}
if (Test-Path '/usr/local/bin/tfswitch' -PathType Leaf) {
    function tfswitch { & /usr/bin/env tfswitch --bin="$HOME/.local/bin/terraform" @args }
}

# *Aliases
Set-Alias -Name rd -Value rmdir
Set-Alias -Name vi -Value vim
# conditional aliases
if (Test-Path '/usr/bin/fastfetch' -PathType Leaf) {
    Set-Alias -Name ff -Value fastfetch
}
