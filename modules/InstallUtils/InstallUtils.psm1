$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/git.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Invoke-CommandRetry'
        'Test-IsAdmin'
        'Update-SessionEnvironmentPath'
        # git
        'Invoke-GhRepoClone'
    )
    Variable = @()
    Alias    = @()
}

Export-ModuleMember @exportModuleMemberParams
