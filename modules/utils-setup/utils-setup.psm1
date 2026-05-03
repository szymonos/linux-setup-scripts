$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/wsl.ps1

$exportModuleMemberParams = @{
    Function = @(
        # wsl
        'Get-WslDistro'
        'Set-WslConf'
    )
    Variable = @()
    Alias    = @()
}

Export-ModuleMember @exportModuleMemberParams
