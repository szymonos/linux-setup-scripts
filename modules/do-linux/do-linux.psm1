$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/completers.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Get-SysInfo'
        'Invoke-Sudo'
        'Invoke-SudoPS'
        'Invoke-ExecutableBitFix'
        # completers
        'Register-MakeCompleter'
    )
    Variable = @()
    Alias    = @(
        # common
        'gsi'
        '_'
        'sps'
        'fixmod'
        'fxmod'
    )
}

Export-ModuleMember @exportModuleMemberParams
