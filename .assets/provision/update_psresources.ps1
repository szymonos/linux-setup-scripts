#!/usr/bin/pwsh -nop
#Requires -Module @{ ModuleName = 'PowerShellGet'; ModuleVersion = '3.0.0' }
<#
.SYNOPSIS
Script for updating PowerShell modules and cleaning-up old versions.

.EXAMPLE
.assets/provision/update_psresources.ps1
#>
$ErrorActionPreference = 'SilentlyContinue'

# determine scope
$param = if ($(id -u) -eq 0) {
    @{ Scope = 'AllUsers' }
} else {
    @{ Scope = 'CurrentUser' }
}

#region update modules
Write-Host "updating modules in the `e[3m$($param.Scope)`e[23m scope" -ForegroundColor DarkGreen
Update-PSResource @param -AcceptLicense
#endregion

#region cleanup modules
Write-Verbose 'getting duplicate modules...'
$dupedModules = Get-InstalledPSResource @param | Group-Object -Property Name | Where-Object Count -GT 1 | Select-Object -ExpandProperty Name
foreach ($mod in $dupedModules) {
    # determine lates version of the module
    $allVersions = Get-InstalledPSResource @param -Name $mod
    $latestVersion = ($allVersions | Sort-Object PublishedDate)[-1].Version
    # uninstall old versions
    Write-Host "`n`e[4m$($mod)`e[24m - $($allVersions.Count) versions of the module found, latest: `e[1mv$latestVersion`e[22m" -ForegroundColor DarkYellow
    Write-Host 'uninstalling...'
    foreach ($v in $allVersions.Where({ $_.Version -ne $latestVersion })) {
        Write-Host "- `e[95mv$($v.Version)`e[0m"
        Uninstall-PSResource @param -Name $v.Name -Version ($v.Prerelease ? "$($v.Version)-$($v.Prerelease)" : "$($v.Version)") -SkipDependencyCheck
    }
}
#endregion
