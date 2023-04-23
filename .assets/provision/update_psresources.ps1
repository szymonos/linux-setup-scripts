#!/usr/bin/env -S pwsh -nop
#Requires -Module @{ ModuleName = 'PowerShellGet'; ModuleVersion = '3.0.0' }
<#
.SYNOPSIS
Script for updating PowerShell modules and cleaning-up old versions.
.EXAMPLE
.assets/provision/update_psresources.ps1
#>

param (
    [Alias('u')]
    [switch]$Update,

    [Alias('c')]
    [switch]$CleanUp
)

begin {
    # determine scope
    $param = if ($(id -u) -eq 0) {
        @{ Scope = 'AllUsers' }
    } else {
        @{ Scope = 'CurrentUser' }
    }
}

process {
    #region update modules
    Write-Host "updating modules in the `e[3m$($param.Scope)`e[23m scope" -ForegroundColor DarkGreen
    Update-PSResource @param -AcceptLicense -ErrorAction SilentlyContinue
    # update pre-release modules
    Write-Verbose 'checking pre-release versions...'
    $prerelease = Get-PSResource @param | Where-Object PrereleaseLabel
    foreach ($mod in $prerelease) {
        Write-Host "- $($mod.Name)"
        (Find-PSResource -Name $mod.Name -Prerelease) | ForEach-Object {
            if ($_.Version.ToString() -notmatch $mod.Version.ToString()) {
                Write-Host "found newer version: `e[1m$($_.Version)`e[22m" -ForegroundColor DarkYellow
                Update-PSResource @param -Name $mod.Name -Prerelease -AcceptLicense -Force
            }
        }
    }
    #endregion

    #region cleanup modules
    Write-Verbose 'getting duplicate modules...'
    $dupedModules = Get-PSResource @param | Group-Object -Property Name | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name
    foreach ($mod in $dupedModules) {
        # determine lates version of the module
        $allVersions = Get-PSResource @param -Name $mod
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
}
