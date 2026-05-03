$ErrorActionPreference = 'Stop'

. $PSScriptRoot/Functions/git.ps1

$exportModuleMemberParams = @{
    Function = @(
        # git
        'Invoke-GhRepoClone'
        'Update-GitRepository'
    )
    Variable = @()
    Alias    = @()
}

Export-ModuleMember @exportModuleMemberParams
