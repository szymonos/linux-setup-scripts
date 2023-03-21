# *Functions
<#
.SYNOPSIS
Write provided command with its arguments and then execute it.
You can suppress writing the command by providing -Quiet as one of the arguments.
You can suppress executing the command by providing -WhatIf as one of the arguments.

.PARAMETER Command
Command to be executed.
.PARAMETER Arguments
Command arguments.
#>
function Invoke-WriteExecuteCommand {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Command,

        [Parameter(Position = 1)]
        [string[]]$Arguments
    )

    # build the command to write and execute
    $cmd = "$Command $($Arguments.Where({ $_ -notin $('-WhatIf', '-Quiet') }).ForEach({ $_ -match '\s' ? "'$_'" : $_ }))"
    if ('-Quiet' -notin $Arguments) {
        # write the command
        Write-Host $cmd -ForegroundColor Magenta
    }
    if ('-WhatIf' -notin $Arguments) {
        # execute the command
        Invoke-Expression $cmd
    }
}

function cd.. { Set-Location ../ }
function .. { Set-Location ../ }
function ... { Set-Location ../../ }
function .... { Set-Location ../../../ }
function la { Get-ChildItem @args -Force }
function src { . $PROFILE.CurrentUserAllHosts }

# *Aliases
Set-Alias -Name c -Value Clear-Host
Set-Alias -Name type -Value Get-Command
