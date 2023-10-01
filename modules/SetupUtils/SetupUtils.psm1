$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/certs.ps1
. $PSScriptRoot/Functions/common.ps1

$exportModuleMemberParams = @{
    Function = @(
        # certs
        'ConvertTo-PEM'
        'Get-Certificate'
        # common
        'ConvertFrom-Cfg'
        'ConvertTo-Cfg'
        'Invoke-ExampleScriptSave'
    )
    Variable = @()
    Alias    = @()
}

Export-ModuleMember @exportModuleMemberParams
