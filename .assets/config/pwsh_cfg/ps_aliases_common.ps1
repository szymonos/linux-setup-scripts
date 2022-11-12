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
function pwsh { & /usr/bin/env pwsh -NoProfileLoadTime @args }
function src { . $PROFILE.CurrentUserAllHosts }
function tree { & /usr/bin/env tree -C @args }
function wget { & /usr/bin/env wget -c @args }
function Invoke-SudoPS {
    for ($i = 0; $i -lt $args.Count; $i++) {
        # expand arguments alias/function definition
        if ($cmd = (Get-ChildItem Alias:/$($args[$i]) -ErrorAction SilentlyContinue || Get-ChildItem Function:/$($args[$i]) -ErrorAction SilentlyContinue).Definition.Where({ $_ -notmatch '\n' })) {
            $args[$i] = "$cmd".Trim().Replace('$input | ', '').Replace('& /usr/bin/env ', '').Replace(' @args', '')
        } elseif ($args[$i] -match ' ') {
            # quote arguments with spaces
            $args[$i] = "'$($args[$i])'"
        }
    }
    # run sudo command with resolved commands
    & /usr/bin/env sudo $params pwsh -NoProfile -NonInteractive -Command "$args"
}
function Invoke-Sudo {
    for ($i = 0; $i -lt $args.Count; $i++) {
        # expand arguments alias/function definition
        if ($cmd = (Get-ChildItem Alias:/$($args[$i]) -ErrorAction SilentlyContinue || Get-ChildItem Function:/$($args[$i]) -ErrorAction SilentlyContinue).Definition.Where({ $_ -notmatch '\n' })) {
            $args[$i] = "$cmd".Trim().Replace('$input | ', '').Replace('& /usr/bin/env ', '').Replace(' @args', '')
        } elseif ($args[$i] -match ' ') {
            # quote arguments with spaces
            $args[$i] = "'$($args[$i])'"
        }
    }
    & /usr/bin/env bash -c "/usr/bin/env sudo $args"
}

function please { Write-Host @args }

# *Aliases
Set-Alias -Name _ -Value Invoke-Sudo
Set-Alias -Name alias -Value Get-CmdAlias
Set-Alias -Name c -Value Clear-Host
Set-Alias -Name rd -Value rmdir
Set-Alias -Name sps -Value Invoke-SudoPS
Set-Alias -Name type -Value Get-Command
Set-Alias -Name vi -Value vim
