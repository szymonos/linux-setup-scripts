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
        $getOrigin = { git config --get remote.origin.url; if (-not $?) { 'https://github.com/' } }
        # determine clone protocol: prefer SSH if key is configured, fallback to HTTPS
        $gitProtocol = if (ssh -T git@github.com 2>&1 | Select-String -Quiet 'successfully authenticated') {
            'git@github.com:'
        } else {
            $(Invoke-Command $getOrigin) -replace '(^.+github\.com[:/]).*', '$1'
        }
        # calculate destination path
        $destPath = Join-Path $Path -ChildPath $repo
    }

    process {
        try {
            Push-Location $destPath
            $status = if ($(Invoke-Command $getOrigin) -match "github\.com[:/]$org/$repo\b") {
                $defaultBranch = (git branch --all | Select-String "(?<=HEAD -> $(git remote)/).+").Matches.Value
                if ($defaultBranch) {
                    # refresh target repository
                    git switch $defaultBranch --force --quiet 2>$null
                    Update-GitRepository | Out-Null
                    Write-Verbose "Repository `"$OrgRepo`" refreshed successfully."
                    Write-Output 2
                } else {
                    Write-Warning 'Default branch not found.'
                    Write-Output 0
                }
            } else {
                Write-Warning "Another `"$repo`" repository exists not matching remote."
                Write-Output 0
            }
            Pop-Location
        } catch {
            # clone target repository - try SSH first, fall back to HTTPS
            $cloneUrl = "${gitProtocol}${org}/${repo}.git"
            $cloneErr = $null
            git clone $cloneUrl "$destPath" --quiet 2>&1 | ForEach-Object { $cloneErr += "$_`n" }
            if (-not $?) {
                if ($gitProtocol -eq 'git@github.com:') {
                    Write-Warning "SSH clone failed, retrying with HTTPS: $($cloneErr?.Trim())"
                    $cloneUrl = "https://github.com/${org}/${repo}.git"
                    $cloneErr = $null
                    git clone $cloneUrl "$destPath" --quiet 2>&1 | ForEach-Object { $cloneErr += "$_`n" }
                }
            }
            $status = if ($?) {
                Write-Verbose "Repository `"$OrgRepo`" cloned successfully."
                Write-Output 1
            } else {
                Write-Warning "Cloning `"$OrgRepo`" failed ($cloneUrl): $($cloneErr?.Trim())"
                Write-Output 0
            }
        }
    }

    end {
        return $status
    }
}

<#
.SYNOPSIS
Function for updating current git branch from remote.
#>
function Update-GitRepository {
    [CmdletBinding()]
    param ()
    # resolve upstream tracking ref in a single call (e.g. "origin/main");
    # fall back to first remote + current branch when no upstream is configured
    $upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>$null
    if ($upstream) {
        $remote, $branch = $upstream -split '/', 2
    } else {
        $remote = git remote 2>$null | Select-Object -First 1
        if (-not $remote) {
            Write-Warning 'Not a git repository.'
            return 0
        }
        $branch = git branch --show-current
        $upstream = "$remote/$branch"
    }

    # cheap pre-check: `ls-remote` is a single small network round-trip with no local writes.
    # if the remote tip already matches our tracking ref, the previous fetch is still current
    # and we can skip the heavy `git fetch --tags --prune --prune-tags --force` (the dominant
    # IO cost on slow disks - it always rewrites FETCH_HEAD, packed-refs, etc. even on no-op)
    $remoteSha = ((git ls-remote --heads $remote $branch 2>$null) -split '\s+', 2)[0]
    $localUpstreamSha = git rev-parse $upstream 2>$null
    if ($remoteSha -and $localUpstreamSha -and $remoteSha -eq $localUpstreamSha) {
        if ((git rev-parse HEAD) -eq $localUpstreamSha) {
            Write-Verbose "$branch branch is up to date (skipped fetch)"
            return 1
        }
        Write-Verbose "$branch behind $upstream (skipped fetch, performing hard reset)"
        git reset --hard $upstream
        return 2
    }

    # full fetch path: remote moved, ls-remote was unreachable, or no local tracking ref yet
    Write-Verbose "fetching $remote..."
    $fetched = $false
    for ($i = 1; $i -le 10; $i++) {
        Write-Verbose "attempt No. $i..."
        git fetch --tags --prune --prune-tags --force $remote 2>$null
        if ($?) {
            $fetched = $true
            break
        }
    }
    if (-not $fetched) {
        Write-Warning 'Fetching from remote failed.'
        return 0
    }
    # single rev-parse for both refs
    $shas = git rev-parse HEAD $upstream
    if ($shas[0] -ne $shas[1]) {
        Write-Verbose "$branch branch is behind the $remote, performing hard reset"
        git reset --hard $upstream
        return 2
    }
    Write-Verbose "$branch branch is up to date"
    return 1
}
