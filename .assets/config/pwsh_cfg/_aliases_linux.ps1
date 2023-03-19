# *Functions
function bsh { & /usr/bin/env -i bash --noprofile --norc }
function exa { & /usr/bin/env exa -g --color=auto --time-style=long-iso --group-directories-first @args }
function ll { exa -lah @args }
function grep { $input | & /usr/bin/env grep --color=auto @args }
function less { $input | & /usr/bin/env less -FRXc @args }
function ip { $input | & /usr/bin/env ip --color=auto @args }
function ls { & /usr/bin/env ls --color=auto --time-style=long-iso --group-directories-first @args }
function l { ls -1 @args }
function lsa { ls -lah @args }
function md { mkdir -p @args }
function mkdir { & /usr/bin/env mkdir -pv @args }
function mv { & /usr/bin/env mv -iv @args }
function nano { & /usr/bin/env nano -W @args }
function p { & /usr/bin/env pwsh -NoProfileLoadTime @args }
function src { . $PROFILE.CurrentUserAllHosts }
function tree { & /usr/bin/env tree -C @args }
function wget { & /usr/bin/env wget -c @args }

# *Aliases
Set-Alias -Name rd -Value rmdir
Set-Alias -Name vi -Value vim
