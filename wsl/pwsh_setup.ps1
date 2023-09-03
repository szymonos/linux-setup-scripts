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

    $targetRepo = 'powershell-scripts'
    # determine if target repository exists and clone if necessary
    $getOrigin = { git config --get remote.origin.url }
    try {
        Set-Location "../$targetRepo"
        if ((Invoke-Command $getOrigin) -match "github\.com[:/]szymonos/$targetRepo\b") {
            # refresh target repository
            git fetch --prune --quiet
            git switch main --force --quiet
            git reset --hard --quiet origin/main
        } else {
            Write-Warning "Another `"$targetRepo`" repository exists."
            exit 1
        }
    } catch {
        $remote = (Invoke-Command $getOrigin) -replace '([:/]szymonos/)[\w-]+', "`$1$targetRepo"
        # clone target repository
        git clone $remote "../$targetRepo"
        Set-Location "../$targetRepo"
    }
}

process {
    # run powershell install/setup script
    scripts/windows/setup_powershell.ps1
}

end {
    Pop-Location
}
