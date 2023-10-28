$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/certs.ps1
. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/wsl.ps1

$exportModuleMemberParams = @{
    Function = @(
        # certs
        'ConvertTo-PEM'
        'Get-Certificate'
        # common
        'ConvertFrom-Cfg'
        'ConvertTo-Cfg'
        'Get-ArrayIndexMenu'
        'Invoke-ExampleScriptSave'
        # wsl
        'Get-WslDistro'
        'Set-WslConf'
    )
    Variable = @()
    Alias    = @()
}

Export-ModuleMember @exportModuleMemberParams
