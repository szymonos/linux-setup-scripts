#!/usr/bin/env pwsh
#Requires -PSEdition Core -Version 7.3
<#
.SYNOPSIS
Update repository modules from ps-modules.

.PARAMETER Refresh
Check if repository is up to date and reset to origin if necessary.

.EXAMPLE
.assets/scripts/modules_update.ps1
.assets/scripts/modules_update.ps1 -Refresh

.NOTES
# :save script example
.assets/scripts/scripts_egsave.ps1 .assets/scripts/modules_update.ps1
# :override the existing script example if exists
.assets/scripts/scripts_egsave.ps1 .assets/scripts/modules_update.ps1 -Force
# :open the example script in VSCode
code -r (.assets/scripts/scripts_egsave.ps1 .assets/scripts/modules_update.ps1 -WriteOutput)
#>
[CmdletBinding()]
param (
    [switch]$Refresh
)

begin {
    $ErrorActionPreference = 'Stop'

    if ($Refresh) {
        # check if repository is up to date
        Write-Host 'refreshing current repository...' -ForegroundColor Cyan
        git fetch
        $remote = "$(git remote)/$(git branch --show-current)"
        if ((git rev-parse HEAD) -ne (git rev-parse $remote)) {
            Write-Warning "Current branch is behind remote, performing hard reset.`n`t Run the script again!`n"
            git reset --hard $remote
            exit 0
        }
    }

    # set location to workspace folder
    Push-Location "$PSScriptRoot/../.."
    # import utils-install for the Invoke-GhRepoClone function
    Import-Module (Resolve-Path './modules/utils-install')
}

process {
    # *refresh ps-modules repository
    Write-Host 'refreshing ps-modules repository...' -ForegroundColor Cyan
    if ((Invoke-GhRepoClone -OrgRepo 'szymonos/ps-modules' -Path '..') -eq 0) {
        Write-Error 'Cloning ps-modules repository failed.'
    }

    # *perform update
    Write-Host 'perform modules update..' -ForegroundColor Cyan
    $modules = @(
        'aliases-git'
        'aliases-kubectl'
        'do-az'
        'do-common'
        'do-linux'
        'psm-windows'
    )
    foreach ($module in $modules) {
        try {
            Remove-Item -Path "./modules/$module" -Recurse -Force -ErrorAction SilentlyContinue
            Copy-Item -Path "../ps-modules/modules/$module" -Destination "./modules" -Recurse
        } catch {
            Write-Warning "Failed to update module ${module}: $_"
        }
    }
}

clean {
    Pop-Location
}
