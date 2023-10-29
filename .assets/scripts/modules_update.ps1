#Requires -PSEdition Core
<#
.SYNOPSIS
Update repository modules from ps-modules.

.PARAMETER Refresh
Check if repository is up to date and reset to origin if necessary.

.EXAMPLE
.assets/scripts/modules_update.ps1
.assets/scripts/modules_update.ps1 -Refresh
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
    # import InstallUtils for the Invoke-GhRepoClone function
    Import-Module (Resolve-Path './modules/InstallUtils')

    # specify update functions structure
    $import = @{
        'do-common'   = @{
            SetupUtils = @{
                certs  = @(
                    'ConvertTo-PEM'
                    'Get-Certificate'
                )
                common = @(
                    'Get-LogMessage'
                    'ConvertFrom-Cfg'
                    'ConvertTo-Cfg'
                    'Get-ArrayIndexMenu'
                    'Invoke-ExampleScriptSave'
                )
            }
        }
        'psm-windows' = @{
            InstallUtils = @{
                common = @(
                    'Invoke-CommandRetry'
                    'Join-Str'
                    'Test-IsAdmin'
                    'Update-SessionEnvironmentPath'
                )
            }
        }
    }
}

process {
    # *refresh ps-modules repository
    Write-Host 'refreshing ps-modules repository...' -ForegroundColor Cyan
    if ((Invoke-GhRepoClone -OrgRepo 'szymonos/ps-modules' -Path '..') -eq 0) {
        Write-Error 'Cloning ps-modules repository failed.'
    }

    # *perform update
    Write-Host 'perform modules update..' -ForegroundColor Cyan
    foreach ($srcModule in $import.GetEnumerator()) {
        Import-Module (Resolve-Path "../ps-modules/modules/$($srcModule.Key)")
        Write-Host "`n$($srcModule.Key)" -ForegroundColor Green
        foreach ($dstModule in $srcModule.Value.GetEnumerator()) {
            Write-Host $dstModule.Key
            foreach ($destFile in $dstModule.Value.GetEnumerator()) {
                Write-Host "  - $($destFile.Key).ps1"
                $filePath = "./modules/$($dstModule.Key)/Functions/$($destFile.Key).ps1"
                Set-Content -Value $null -Path $filePath
                $builder = [System.Text.StringBuilder]::new()
                foreach ($function in $destFile.Value) {
                    Write-Host "    • $function"
                    $def = "    $((Get-Command $function -CommandType Function).Definition.Trim())"
                    $builder.AppendLine("function $function {") | Out-Null
                    $builder.AppendLine($def) | Out-Null
                    $builder.AppendLine("}`n") | Out-Null
                }
                Set-Content -Value $builder.ToString().Trim().Replace("`r`n", "`n") -Path $filePath -Encoding utf8
            }
        }
    }
}

end {
    Pop-Location
}
