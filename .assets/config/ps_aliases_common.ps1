# *Functions
function Get-CmdAlias ([string]$CmdletName) {
    Get-Alias | `
        Where-Object -FilterScript { $_.Definition -match $CmdletName } | `
        Sort-Object -Property Definition, Name | `
        Select-Object -Property Definition, Name
}
function .. { Set-Location ../ }
function ... { Set-Location ../../ }
function cd.. { Set-Location ../ }
function grep { $input | & /usr/bin/env grep --color=auto $args }
function less { $input | & /usr/bin/env less -FSRXc $args }
function la {
    $arguments = $args.ForEach({ $_ -match ' ' ? "'$_'" : $_ })
    Invoke-Expression "Get-ChildItem $arguments -Force"
}
function ls { & /usr/bin/env ls --color=auto --group-directories-first $args }
function l { & /usr/bin/env ls -1 --color=auto --group-directories-first $args }
function ll { & /usr/bin/env exa -lagh --color=auto --time-style=long-iso --group-directories-first $args }
function lsa { & /usr/bin/env ls -lah --color=auto --time-style=long-iso --group-directories-first $args }
function md { mkdir -p $args }
function mkdir { & /usr/bin/env mkdir -pv $args }
function mv { & /usr/bin/env mv -iv $args }
function nano { & /usr/bin/env nano -W $args }
function pwsh { & /usr/bin/env pwsh -nol $args }
function p { & /usr/bin/env pwsh -nol $args }
function src { . $PROFILE.CurrentUserAllHosts }
function tree { & /usr/bin/env tree -C $args }
function wget { & /usr/bin/env wget -c $args }
function Invoke-SudoPS {
    # determine if the first argument is an alias or function
    if ($cmd = (Get-Command $args[0] -CommandType Alias, Function -ErrorAction SilentlyContinue).Definition.Where({ $_ -notmatch '\n' })) {
        $args[0] = $cmd.Trim().Replace('$input | ', '').Replace('& /usr/bin/env ', '').Replace(' $args', '')
    }
    # parse sudo parameters and command with arguments
    $params = ("$args" | Select-String '^-.+?(?=\s+[^-])').Matches.Value
    $cmd = ("$args" -replace $params).Trim()
    # run sudo command with resolved commands
    & /usr/bin/env sudo $params pwsh -NoProfile -NonInteractive -Command "$cmd"
}
function Invoke-Sudo {
    # determine if the first argument is an alias or function
    if ($cmd = (Get-Command $args[0] -CommandType Alias, Function -ErrorAction SilentlyContinue).Definition.Where({ $_ -notmatch '\n' })) {
        $args[0] = $cmd.Trim().Replace('$input | ', '').Replace('& /usr/bin/env ', '').Replace(' $args', '')
    }
    # parse sudo parameters and command with arguments
    $params = ("$args" | Select-String '^-.+?(?=\s+[^-])').Matches.Value
    $cmd = ("$args" -replace $params).Trim()
    # run sudo command with resolved commands
    & /usr/bin/env sudo $params bash -c "$cmd"
}

# *Aliases
Set-Alias -Name _ -Value Invoke-Sudo
Set-Alias -Name alias -Value Get-CmdAlias
Set-Alias -Name c -Value Clear-Host
Set-Alias -Name rd -Value rmdir
Set-Alias -Name sps -Value Invoke-SudoPS
Set-Alias -Name type -Value Get-Command
Set-Alias -Name vi -Value vim
