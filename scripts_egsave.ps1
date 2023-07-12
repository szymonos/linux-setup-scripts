#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Generate example scripts from the current repository.
.EXAMPLE
./scripts_egsave.ps1
#>

$ErrorActionPreference = 'Stop'

# check if the Invoke-ExampleScriptSave function is available import it from the do-common module otherwise
try {
    Get-Command Invoke-ExampleScriptSave -CommandType Function | Out-Null
} catch {
    # determine if ps-modules repository exist and clone if necessary
    $remote = (git config --get remote.origin.url).Replace('linux-setup-scripts', 'ps-modules')
    try {
        Push-Location '../ps-modules' -ErrorAction Stop
        if ($remote -match '\bszymonos/ps-modules\.git$') {
            # refresh ps-modules repository
            git fetch --prune --quiet
            $targetBranch = if ((git branch --show-current) -eq 'dev') {
                'dev'
            } else {
                'main'
            }
            git switch $targetBranch --force --quiet 2>$null
            git reset --hard --quiet "origin/$targetBranch"
            git clean --force -d
        }
        Pop-Location
    } catch {
        # clone ps-modules repository
        git clone $remote ../ps-modules
    }
    Import-Module -Name (Resolve-Path '../ps-modules/modules/do-common/do-common.psd1')
}

# save example scripts
$folders = @(
    'wsl'
    '.assets/provision'
    '.assets/scripts'
    '.assets/tools'
)
foreach ($folder in $folders) {
    Invoke-ExampleScriptSave $folder -FolderFromBase
}
