#Requires -PSEdition Desktop
<#
.SYNOPSIS
Install/update PowerShell Core.
.EXAMPLE
wsl/pwsh_setup.ps1
#>

# *set location to workspace folder
Push-Location "$PSScriptRoot/.."

# *determine if powershell-scripts repository exist and clone if necessary
$remote = (git config --get remote.origin.url).Replace('linux-setup-scripts', 'powershell-scripts')
try {
    Set-Location '../powershell-scripts' -ErrorAction Stop
    if ((git config --get remote.origin.url) -match '\bszymonos/powershell-scripts\.git$') {
        git fetch --prune --quiet
        $targetBranch = if ((git branch --show-current) -eq 'dev') {
            'dev'
        } else {
            'main'
        }
        git switch $targetBranch --force --quiet 2>$null
        git reset --hard --quiet "origin/$targetBranch"
        git clean --force -d
    } else {
        Write-Warning 'Another "powershell-scripts" repository exist.'
        break
    }
} catch {
    # clone ps-modules repository
    git clone $remote ../powershell-scripts
    Set-Location '../powershell-scripts'
}

# *run powershell install/setup script
../powershell-scripts/scripts/windows/setup_powershell.ps1

# *restore startup location
Pop-Location