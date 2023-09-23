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

    # clone/refresh szymonos/powershell-scripts repository
    if (.assets/tools/gh_repo_clone.ps1 -OrgRepo 'szymonos/powershell-scripts') {
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
