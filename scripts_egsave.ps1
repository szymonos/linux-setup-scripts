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
        # clone/refresh szymonos/ps-modules repository
        if (.assets/tools/gh_repo_clone.ps1 -OrgRepo 'szymonos/ps-modules') {
            Import-Module -Name (Resolve-Path '../ps-modules/modules/do-common')
        } else {
            Write-Error 'Cloning ps-modules repository failed.'
        }
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
