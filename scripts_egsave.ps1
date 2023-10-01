#Requires -PSEdition Core
#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Generate example scripts from the current repository.
.EXAMPLE
./scripts_egsave.ps1
#>

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
}

process {
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
}

end {
    Pop-Location
}
