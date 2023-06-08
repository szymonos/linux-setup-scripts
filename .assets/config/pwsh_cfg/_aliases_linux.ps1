# *Functions
if ($env:DISTRO_FAMILY -eq 'alpine') {
    function bsh { & /usr/bin/env -i ash --noprofile --norc }
    function ls { & /usr/bin/env ls -h --color=auto --group-directories-first @args }
} else {
    function bsh { & /usr/bin/env -i bash --noprofile --norc }
    function ip { $input | & /usr/bin/env ip --color=auto @args }
    function ls { & /usr/bin/env ls -h --color=auto --group-directories-first --time-style=long-iso @args }
}
function exa { & /usr/bin/env exa -g --color=auto --time-style=long-iso --group-directories-first @args }
function ll { exa -lah @args }
function grep { $input | & /usr/bin/env grep --color=auto @args }
function less { $input | & /usr/bin/env less -FRXc @args }
function l { ls -1 @args }
function lsa { ls -la @args }
function mkdir { & /usr/bin/env mkdir -pv @args }
function mv { & /usr/bin/env mv -iv @args }
function nano { & /usr/bin/env nano -W @args }
function p { & /usr/bin/env pwsh -NoProfileLoadTime @args }
function tree { & /usr/bin/env tree -C @args }
function wget { & /usr/bin/env wget -c @args }

# *Aliases
Set-Alias -Name ff -Value fastfetch
Set-Alias -Name rd -Value rmdir
Set-Alias -Name vi -Value vim
