<#
.SYNOPSIS
Function for refreshing/cloning specified GitHub repository.

.PARAMETER OrgRepo
GitHub repository provided as Org/Repo.
.PARAMETER Path
Destination path to clone/refresh repo to.
#>
function Invoke-GhRepoClone {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Alias('r')]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateScript({ $_ -match '^[\w-\.]+/[\w-\.]+$' })]
        [string]$OrgRepo,

        [ValidateScript({ Test-Path $_ -PathType 'Container' })]
        [string]$Path = '..'
    )

    begin {
        $ErrorActionPreference = 'Stop'

        # determine organisation and repository name
        $org, $repo = $OrgRepo.Split('/')
        # command for getting the remote url
        $getOrigin = { git config --get remote.origin.url }
        # calculate destination path
        $destPath = Join-Path $Path -ChildPath $repo
    }

    process {
        try {
            Push-Location $destPath
            $status = if ($(Invoke-Command $getOrigin) -match "github\.com[:/]$org/$repo\b") {
                # refresh target repository
                git fetch --prune --quiet
                git switch main --force --quiet 2>$null
                git reset --hard --quiet origin/main
                Write-Verbose "Repository `"$OrgRepo`" refreshed successfully."
                Write-Output 2
            } else {
                Write-Warning "Another `"$repo`" repository exists not matching remote."
                Write-Output 0
            }
            Pop-Location
        } catch {
            # determine GitHub protocol used (https/ssl)
            $gitProtocol = $(Invoke-Command $getOrigin) -replace '(^.+github\.com[:/]).*', '$1'
            # clone target repository
            git clone "${gitProtocol}$org/$repo" "$destPath" --quiet
            # determine state of cloning the repository
            $status = if ($?) {
                Write-Verbose "Repository `"$OrgRepo`" cloned successfully."
                Write-Output 1
            } else {
                Write-Warning "Cloning of the `"$OrgRepo`" repository failed."
                Write-Output 0
            }
        }
    }

    end {
        return $status
    }
}
