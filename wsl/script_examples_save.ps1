#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Generate example scripts from the wsl folder.
.EXAMPLE
wsl/script_examples_save.ps1
#>

$ErrorActionPreference = 'Stop'

# check if the Invoke-ExampleScriptSave function is available import it from the do-common module otherwise
try {
    Get-Command Invoke-ExampleScriptSave -CommandType Function | Out-Null
} catch {
    # determine if ps-modules repository exist and clone if necessary
    $getOrigin = { git config --get remote.origin.url }
    $remote = (Invoke-Command $getOrigin).Replace('linux-setup-scripts', 'ps-modules')
    try {
        Push-Location '../ps-modules' -ErrorAction Stop
        if ($(Invoke-Command $getOrigin) -eq $remote) {
            # refresh ps-modules repository
            git fetch --quiet && git reset --hard --quiet "origin/$(git branch --show-current)"
        }
        Pop-Location
    } catch {
        # clone ps-modules repository
        git clone $remote ../ps-modules
    }
    Import-Module -Name (Resolve-Path '../ps-modules/modules/do-common/do-common.psm1')
}

Invoke-ExampleScriptSave 'wsl/*.ps1'
