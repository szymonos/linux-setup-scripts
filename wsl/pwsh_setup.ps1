#Requires -PSEdition Desktop
<#
.SYNOPSIS
Install/update PowerShell Core.
.EXAMPLE
wsl/pwsh_setup.ps1
# !Run below command on execution error.
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#>

begin {
    $ErrorActionPreference = 'Stop'

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
    # import InstallUtils for the Invoke-GhRepoClone function
    Import-Module (Resolve-Path './modules/InstallUtils')

    # clone/refresh szymonos/powershell-scripts repository
    if (Invoke-GhRepoClone -OrgRepo 'szymonos/powershell-scripts' -Path '..') {
        Set-Location ../powershell-scripts
    } else {
        Write-Error 'Cloning ps-modules repository failed.'
    }
}

process {
    # run powershell install/setup script
    scripts/windows/setup_powershell.ps1
}

end {
    Pop-Location
}
