$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/certs.ps1
. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/logs.ps1
. $PSScriptRoot/Functions/scopes.ps1
. $PSScriptRoot/Functions/wsl.ps1
# load shared scope definitions from JSON
$scopesData = [System.IO.File]::ReadAllText("$PSScriptRoot/../../.assets/lib/scopes.json") | ConvertFrom-Json
[string[]]$Script:ValidScopes = $scopesData.valid_scopes
[string[]]$Script:InstallOrder = $scopesData.install_order
$Script:ScopeDependencyRules = $scopesData.dependency_rules

$exportModuleMemberParams = @{
    Function = @(
        # certs
        'ConvertFrom-PEM'
        'ConvertTo-PEM'
        'Get-Certificate'
        # common
        'Get-LogMessage'
        'ConvertFrom-Cfg'
        'ConvertTo-Cfg'
        'Get-ArrayIndexMenu'
        'Invoke-ExampleScriptSave'
        # logs
        'Show-LogContext'
        # scopes
        'Resolve-ScopeDeps'
        'Get-SortedScopes'
        # wsl
        'Get-WslDistro'
        'Set-WslConf'
    )
    Variable = @()
    Alias    = @()
}

Export-ModuleMember @exportModuleMemberParams
