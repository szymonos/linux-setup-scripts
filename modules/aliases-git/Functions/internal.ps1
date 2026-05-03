<#
.SYNOPSIS
Get git log object.

.PARAMETER Xargs
Additional arguments to pass to the git log command.
#>
function Get-GitLogObject {
    [CmdletBinding()]
    param (
        [switch]$All,

        [switch]$Grep,

        [switch]$Limit,

        [switch]$Tags,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    begin {
        #region build arguments list
        # build git log command arguments
        $cmdArgs = [System.Collections.Generic.List[string]]::new(
            [string[]]@(
                '--reverse'
                "--pretty=format:%h`f%ai`f%s`f%an`f%ae`f%D"
            )
        )
        # limit result to 30
        if ($PSBoundParameters.Limit -and $PSBoundParameters.Xargs -notmatch '^(-?\d+)$') {
            $cmdArgs.Add('-30')
        }
        # return commits from all branches
        if ($PSBoundParameters.All) {
            $cmdArgs.Add('--all')
        }
        # add additional grep filter parameters
        if ($PSBoundParameters.Grep) {
            $cmdArgs.AddRange(
                [string[]]@(
                    '--perl-regexp'
                    '--regexp-ignore-case'
                )
            )
        }
        # return tags only
        if ($PSBoundParameters.Tags) {
            $cmdArgs.AddRange(
                [string[]]@(
                    '--tags=*'
                    '--no-walk'
                )
            )
        }
        # parse Xargs for count specification
        $parsedXargs = if ($PSBoundParameters.Xargs -match '^0$') {
            $Xargs -notmatch '^0$'
        } elseif ($PSBoundParameters.Xargs -match '^\d+$') {
            $Xargs -replace '^\d+$', "-`$&"
        } else {
            $Xargs
        }

        if ($parsedXargs) {
            $cmdArgs.AddRange([string[]]$parsedXargs)
        }
        #endregion

        #region specify headers and output parameters
        # specify CSV headers
        $headers = @(
            'Commit'
            'Date'
            'Subject'
            'Author'
            'Email'
            'Ref'
        )
        # property selection
        $prop = @(
            'Commit'
            @{ Name = 'DateUTC'; Expression = { [TimeZoneInfo]::ConvertTimeToUtc($_.Date).ToString('s').Replace('T', ' ') } }
            'Subject'
            'Author'
            'Email'
            'Ref'
        )
        #endregion
    }

    process {
        # show the expression
        Write-Verbose "git log $cmdArgs".Replace("`f", ' ').Replace('%h', '"$h').Replace('%D', '$D"')
        # run git log and convert output to objects
        $result = git log @cmdArgs | ConvertFrom-Csv -Delimiter "`f" -Header $headers | Select-Object -Property $prop
    }

    end {
        return $result
    }
}


<#
.SYNOPSIS
Get git reflog object.

.PARAMETER Xargs
Additional arguments to pass to the git reflog command.
#>
function Get-GitReflogObject {
    [CmdletBinding()]
    param (
        [switch]$Limit,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    begin {
        #region build arguments list
        # build git reflog command arguments
        $cmdArgs = [System.Collections.Generic.List[string]]::new(
            [string[]]@(
                "--format=%h`f%gd`f%ai`f%gs`f%an`f%ae`f%D"
            )
        )
        # limit result to 30
        if ($PSBoundParameters.Limit -and $PSBoundParameters.Xargs -notmatch '^(-?\d+)$') {
            $cmdArgs.Add('-30')
        }
        # parse Xargs for count specification
        $parsedXargs = if ($PSBoundParameters.Xargs -match '^0$') {
            $Xargs -notmatch '^0$'
        } elseif ($PSBoundParameters.Xargs -match '^\d+$') {
            $Xargs -replace '^\d+$', "-`$&"
        } else {
            $Xargs
        }

        if ($parsedXargs) {
            $cmdArgs.AddRange([string[]]$parsedXargs)
        }
        #endregion

        #region specify headers and output parameters
        # specify CSV headers
        $headers = @(
            'Commit'
            'Selector'
            'Date'
            'Subject'
            'Author'
            'Email'
            'Ref'
        )
        # property selection
        $prop = @(
            'Commit'
            'Selector'
            @{ Name = 'DateUTC'; Expression = { [TimeZoneInfo]::ConvertTimeToUtc($_.Date).ToString('s').Replace('T', ' ') } }
            'Subject'
            'Author'
            'Email'
            'Ref'
        )
        #endregion
    }

    process {
        # show the expression
        Write-Verbose "git reflog $cmdArgs".Replace("`f", ' ').Replace('%h', '"$h').Replace('%D', '$D"')
        # run git reflog and convert output to objects, reverse to show oldest first
        [array]$result = git reflog @cmdArgs | ConvertFrom-Csv -Delimiter "`f" -Header $headers | Select-Object -Property $prop
        [array]::Reverse($result)
    }

    end {
        return $result
    }
}


<#
.SYNOPSIS
Get last git commit message.

.PARAMETER First
Switch whether to return only the first line of the commit message.
#>
function Get-GitLogMessage ([switch]$First) {
    # get the last commit message
    $msg = (git log -1 --pretty=%B).ForEach({ "$_".Trim() }).Where({ $_ })

    # return first line or full message
    if ($PSBoundParameters.First) {
        $msg | Select-Object -First 1
    } else {
        $msg -join ' '
    }
}

<#
.SYNOPSIS
Write provided command with its arguments and then execute it.
You can suppress writing the command by providing -Quiet as one of the arguments.
You can suppress executing the command by providing -WhatIf as one of the arguments.

.PARAMETER Command
Command to be executed.
.PARAMETER Xargs
Command arguments to be passed to the provided command.
.PARAMETER WhatIf
Do not execute the command.
.PARAMETER Quiet
Do not print the command string.
#>
function Invoke-WriteExecCommand {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    begin {
        # build command
        $sb = [System.Text.StringBuilder]::new($Command)
        if ($PSBoundParameters.Xargs) {
            $Xargs | ForEach-Object {
                $arg = $_ -match '\s|@' ? "'$_'" : $_
                $sb.Append(" $arg") | Out-Null
            }
        }
        # get command string
        $cmnd = $sb.ToString()
    }

    process {
        if (-not $PSBoundParameters.Quiet) {
            # write command
            Write-Host $cmnd -ForegroundColor Magenta
        }
        if (-not $PSBoundParameters.WhatIf) {
            # execute command
            return Invoke-Expression $cmnd
        }
    }
}


<#
.SYNOPSIS
Get current branch name.
#>
function Get-GitCurrentBranch {
    git branch --show-current
}


<#
.SYNOPSIS
Resolve main, dev, stage branch names.

.PARAMETER BranchName
Name of the branch to switch to.
#>
function Get-GitResolvedBranch {
    [CmdletBinding()]
    param (
        [string[]]$BranchName
    )

    if (git rev-parse --is-inside-work-tree) {
        # build remote names filter
        filter remoteFilter {
            "$_".Trim() -replace [string]::Join('|', (git remote).ForEach({ "$_/?" })) | Where-Object { $_ }
        }
        [string]$BranchName = $BranchName | remoteFilter
        $match = @{
            d = @('^dev(|el|elop|elopment)$')
            m = @('^ma(in|ster)$')
            p = @('^prod(uction)?$')
            s = @('^st(g|age|aging)$')
            t = @('^trunk$')
        }
        $branchMatch = switch ($BranchName) {
            '' { $match.m + $match.p + $match.s + $match.d + $match.t; break }
            d { $match.d; break }
            m { $match.m; break }
            p { $match.p; break }
            s { $match.s; break }
            t { $match.t; break }
            default { @("^$BranchName$") }
        }
        Write-Verbose "BranchMatch: $($branchMatch -join ', ')"
        # instantiate collections
        $matched = [System.Collections.Generic.HashSet[string]]::new()
    } else {
        break
    }

    # get list of branches
    $branches = git branch --all --format='%(refname:short)' | remoteFilter | Sort-Object -Unique
    # match branches
    foreach ($match in $branchMatch) {
        $branches.Where({ $_ -match $match }).ForEach({ $matched.Add($_) | Out-Null })
    }
    Write-Verbose "Matched branches: $($matched -join ', ')"

    if ($matched.Count -eq 0) {
        if ($BranchName) {
            Write-Warning "Invalid reference: '$BranchName'. Valid reference values are: `e[0;1m$([string]::Join(', ', $branches))`e[0m"
            break
        } else {
            $matched = Get-GitCurrentBranch
        }
    }

    return $matched | Select-Object -First 1
}


<#
.SYNOPSIS
Delete local branches.
.DESCRIPTION
If DeleteNoMerged parameter is not specified, all local merged branches will be deleted.

.PARAMETER DeleteNoMerged
Switch whether to delete non merged branches.
#>
function Remove-GitLocalBranches {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [switch]$DeleteNoMerged,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    begin {
        # remove DeleteNoMerged from PSBoundParameters
        $PSBoundParameters.Remove('DeleteNoMerged') | Out-Null
        # switch to dev/main branch
        git switch $(Get-GitResolvedBranch) --quiet
        # update remote
        git remote update --prune
        # instantiate sorted set for branches to delete
        $branches = [System.Collections.Generic.SortedSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $regex = '^(ma(in|ster)|(non)?prod(uction)?|dev(|el|elop|elopment)|qa|stag(e|ing)|trunk|docs)$'
        filter branchFilter { $_.Where({ $_ -notmatch $regex }) }
    }

    process {
        # add merged branches
        git branch --format='%(refname:short)' --merged | branchFilter | ForEach-Object { $branches.Add($_) | Out-Null }
        # add branches with gone upstream (e.g. squash-merged PRs)
        git branch --format='%(refname:short) %(upstream:track)' | ForEach-Object {
            if ($_ -match '^(\S+)\s+\[gone\]$') { $Matches[1] }
        } | branchFilter | ForEach-Object { $branches.Add($_) | Out-Null }
        # delete merged and gone branches
        foreach ($branch in $branches) {
            Invoke-WriteExecCommand -Command "git branch -D $branch" @PSBoundParameters
        }
        if ($DeleteNoMerged) {
            $no_merged = git branch --format='%(refname:short)' --no-merged | branchFilter
            foreach ($branch in $no_merged) {
                if ((Read-Host -Prompt "Do you want to remove branch: `e[1;97m$branch`e[0m? [y/N]") -eq 'y') {
                    Invoke-WriteExecCommand -Command "git branch -D $branch" @PSBoundParameters
                }
            }
        }
    }
}


<#
.SYNOPSIS
Delete merged branches.

.PARAMETER DeleteRemote
Switch whether to delete remote merged branches.
#>
function Remove-GitMergedBranches {
    param (
        [switch]$DeleteRemote
    )

    # remove local merged and gone branches
    Remove-GitLocalBranches -Quiet

    # remove remote merged branches
    if ($DeleteRemote) {
        $regex = '^(ma(in|ster)|(non)?prod(uction)?|dev(|el|elop|elopment)|qa|stag(e|ing)|trunk|docs)$'
        [string[]]$remotes = git remote
        $remoteFilter = $remotes.ForEach({ "^$_/" }) | Join-String -Separator '|'
        $knownFilter = "($remoteFilter)($($regex.Replace('^', '')))"
        filter remoteFilter { $_.Where({ $_ -match $remoteFilter -and $_ -notmatch $knownFilter }) }
        [string[]]$mergedRemote = git branch --remotes --format='%(refname:short)' --merged | remoteFilter
        foreach ($remote in $remotes) {
            $mergedRemote | Select-String "^$remote/(.*)" | ForEach-Object {
                git push --delete $remote $_.Matches.Groups[1].Value
            }
        }
    }
}


<#
.SYNOPSIS
Run specified git commands in a current repo or all repos located in subdirectories of the current folder.
Function runs only for repositories with remote set.

.PARAMETER Command
Script block of commands to execute.
#>
function Invoke-GitRepoCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = 'The command to be invoked.')]
        [scriptblock]$Command
    )

    Push-Location
    # instantiate list for storing git directories with remote set
    $dirs = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()

    # check if in git repo
    $isGitRepo = git rev-parse --is-inside-work-tree 2>$null && $true || $false
    # build list of directories with remote set
    if ($isGitRepo) {
        (git remote) ? $dirs.Add($(Get-Item .)) : $null
    } else {
        Get-ChildItem -Directory | ForEach-Object {
            (git -C $_.FullName remote 2>$null) ? $dirs.Add($_) : $null
        }
    }

    # iterate over all git repos with remote set
    foreach ($dir in $dirs) {
        Set-Location $dir
        # set line separator for printing the following results
        $follow = $dir -eq $dirs[0] ? '' : "`n"
        if ($dirs.Count -gt 1) {
            Write-Host "$follow$($dir.Name)" -ForegroundColor Cyan
        }
        # execute commands
        Invoke-Command -ScriptBlock $Command
    }

    Pop-Location
}
