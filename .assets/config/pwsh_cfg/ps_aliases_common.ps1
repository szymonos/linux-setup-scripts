# *Functions
function .. { Set-Location ../ }
function ... { Set-Location ../../ }
function cd.. { Set-Location ../ }
function grep { $input | & /usr/bin/env grep --color=auto @args }
function less { $input | & /usr/bin/env less -FSRXc @args }
function ip { $input | & /usr/bin/env ip --color=auto @args }
function la { Get-ChildItem @args -Force }
function ls { & /usr/bin/env ls --color=auto --time-style=long-iso --group-directories-first @args }
function l { ls -1 @args }
function lsa { ls -lah @args }
function ll { & /usr/bin/env exa -lagh --color=auto --time-style=long-iso --group-directories-first @args }
function md { mkdir -p @args }
function mkdir { & /usr/bin/env mkdir -pv @args }
function mv { & /usr/bin/env mv -iv @args }
function nano { & /usr/bin/env nano -W @args }
function p { & /usr/bin/env pwsh -NoProfileLoadTime @args }
function src { . $PROFILE.CurrentUserAllHosts }
function tree { & /usr/bin/env tree -C @args }
function wget { & /usr/bin/env wget -c @args }

# *Aliases
Set-Alias -Name c -Value Clear-Host
Set-Alias -Name rd -Value rmdir
Set-Alias -Name type -Value Get-Command
Set-Alias -Name vi -Value vim
