#!/usr/bin/pwsh -nop
#Requires -PSEdition Core -Version 7.3
<#
.SYNOPSIS
Generate example scripts from the current repository.
.PARAMETER Path
The path to the script file to save as an example.
.PARAMETER Force
Force ovewriting target file if exists.
.PARAMETER WriteOutput
Write output to the success [1] stream instead of the information [6] one.

.EXAMPLE
# :save all missing script examples from the scripts directory and its subdirectories
./scripts_egsave.ps1
# :force saveing all script examples from the scripts directory and its subdirectories
./scripts_egsave.ps1 -Force
#>
[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [ValidateScript({ Test-Path $_ }, ErrorMessage = "'{0}' is not a valid path.")]
    [string]$Path,

    [switch]$Force,

    [switch]$WriteOutput
)

begin {
    $ErrorActionPreference = 'Stop'

    # set location to workspace folder
    Push-Location $PSScriptRoot

    # check if the Invoke-ExampleScriptSave function is available, otherwise clone ps-modules repo
    try {
        Get-Command Invoke-ExampleScriptSave -CommandType Function | Out-Null
    } catch {
        Import-Module (Resolve-Path './modules/SetupUtils')
    }

    # rewrite PSBoundParameters to the param variable
    $param = $PSBoundParameters
    $param.FolderFromBase = $true
}

process {
    if ($param.Path) {
        Invoke-ExampleScriptSave @param
    } else {
        # specify directories to save examples from
        $folders = @(
            'wsl'
            '.assets/provision'
            '.assets/scripts'
            '.assets/tools'
        )
        foreach ($folder in $folders) {
            $param.Path = $folder
            Invoke-ExampleScriptSave @param
        }
    }
}

clean {
    Pop-Location
}
