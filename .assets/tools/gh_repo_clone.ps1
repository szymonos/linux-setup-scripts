#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Clone specified GitHub repository name.

.PARAMETER OrgRepo
GitHub repository in the Organization/RepoName format.

.EXAMPLE
$OrgRepo = 'szymonos/ps-modules'
$result = .assets/tools/gh_repo_clone.ps1 -r $OrgRepo
#>
[CmdletBinding()]
[OutputType([bool])]
param (
    [Alias('r')]
    [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
    [ValidateScript({ $_ -match '^[\w-\.]+/[\w-\.]+$' })]
    [string]$OrgRepo
)

begin {
    $ErrorActionPreference = 'Stop'

    # determine organisation and repository name
    $org, $repo = $OrgRepo.Split('/')
    # command for getting the remote url
    $getOrigin = { git config --get remote.origin.url }
}

process {
    try {
        Push-Location "../$repo"
        $cloned = if ($(Invoke-Command $getOrigin) -match "github\.com[:/]$org/$repo\b") {
            # refresh target repository
            git fetch --prune --quiet
            git switch main --force --quiet 2>$null
            git reset --hard --quiet origin/main
            # ps-modules repo refreshed successfully
            $true
        } else {
            Write-Warning "Another `"$targetRepo`" repository exists."
            # repo remote not match
            $false
        }
        Pop-Location
    } catch {
        # determine GitHub protocol used (https/ssl)
        $gitProtocol = $(Invoke-Command $getOrigin) -replace '(^.+github\.com[:/]).*', '$1'
        # clone target repository
        git clone "${gitProtocol}$org/$repo" "../$repo" --quiet
        # determine state of cloning the repository
        $cloned = if ($?) {
            $true
        } else {
            Write-Warning "Cloning of the `"$OrgRepo`" repository failed."
            $false
        }
    }
}

end {
    # return status if repository has been cloned successfully
    return $cloned
}
