#region helper git branch delete functions
function gbd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git branch --delete $Branch"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gbd! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git branch -D $Branch"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gbdo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command strings
    if ($remote = @(git remote)[0]) {
        $commands = [System.Collections.Generic.List[string]]::new()
        $commands.Add("git branch --delete $Branch")
        $commands.Add("git push --delete $remote $Branch")
        $PSBoundParameters.Remove('Branch') | Out-Null
    } else {
        Write-Host 'fatal: Remote repository not set.'
        return
    }

    # run commands
    foreach ($cmnd in $commands) {
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    }
}
function gbdo! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command strings
    if ($remote = @(git remote)[0]) {
        $commands = [System.Collections.Generic.List[string]]::new()
        $commands.Add("git branch -D $Branch")
        $commands.Add("git push --delete $remote $Branch")
        $PSBoundParameters.Remove('Branch') | Out-Null
    } else {
        Write-Host 'fatal: Remote repository not set.'
        return
    }

    # run commands
    foreach ($cmnd in $commands) {
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    }
}
function gbdl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )
    Remove-GitLocalBranches @PSBoundParameters
}
function gbdl! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )
    Remove-GitLocalBranches -DeleteNoMerged @PSBoundParameters
}
function gbdm {
    Remove-GitMergedBranches
}
function gbdm! {
    Remove-GitMergedBranches -DeleteRemote
}
function gpushd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    if ($remote = @(git remote)[0]) {
        # calculate command string
        $cmnd = "git push --delete $remote $Branch"
        $PSBoundParameters.Remove('Branch') | Out-Null
        # run command
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
#endregion


#region helper merge/rebase functions
function gmg {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $rmt, $br = $Branch.Split('/', 2)
    $resolvedBranch = if ($rmt -in (git remote)) {
        "${rmt}/$(Get-GitResolvedBranch $br)"
    } else {
        Get-GitResolvedBranch $Branch
    }
    $cmnd = "git merge $resolvedBranch"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gmgo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command strings
    if ($remote = @(git remote)[0]) {
        # get current branch
        $currentBranch = git branch --show-current
        # resolve provided branch
        $resolvedBranch = Get-GitResolvedBranch $Branch
        $PSBoundParameters.Remove('Branch') | Out-Null
        # build list of commands to execute
        Invoke-WriteExecCommand -Command "git fetch $remote --prune" @PSBoundParameters
        if ($currentBranch -ne $resolvedBranch) {
            Invoke-WriteExecCommand -Command "git merge ${remote}/${currentBranch} --quiet" @PSBoundParameters
        }
        Invoke-WriteExecCommand -Command "git merge ${remote}/${resolvedBranch}" @PSBoundParameters | Tee-Object -Variable merge
        if ($merge | Select-String 'Fast-forward' -Quiet) {
            Invoke-WriteExecCommand -Command "git push ${remote}" @PSBoundParameters
        }
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function grb {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $rmt, $br = $Branch.Split('/', 2)
    $resolvedBranch = if ($rmt -in (git remote)) {
        "${rmt}/$(Get-GitResolvedBranch $br)"
    } else {
        Get-GitResolvedBranch $Branch
    }
    $cmnd = "git rebase $resolvedBranch"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function grbo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command strings
    if ($remote = @(git remote)[0]) {
        # get current branch
        $currentBranch = git branch --show-current
        # resolve provided branch
        $resolvedBranch = Get-GitResolvedBranch $Branch
        $PSBoundParameters.Remove('Branch') | Out-Null
        # build list of commands to execute
        $commands = [System.Collections.Generic.List[string]]::new()
        $commands.Add("git fetch $remote --prune")
        if ($currentBranch -ne $resolvedBranch) {
            $commands.Add("git rebase ${remote}/${currentBranch} --quiet")
        }
        $commands.Add("git rebase ${remote}/${resolvedBranch}")
    } else {
        Write-Host 'fatal: Remote repository not set.'
        return
    }

    # run commands
    foreach ($cmnd in $commands) {
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    }
    # check if rebase was successful and push changes
    $behind, $ahead = (git rev-list --count --left-right '@{u}...HEAD') -split "`t"
    if ($? -and $behind -eq 0 -and $ahead -gt 0) {
        Invoke-WriteExecCommand -Command "git push ${remote}" @PSBoundParameters
    }
}
function gmb {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git merge-base $(Get-GitResolvedBranch $Branch) HEAD"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function grmb {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git reset `$(git merge-base $(Get-GitResolvedBranch $Branch) HEAD)"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
#endregion


#region helper grun functions
<#
.DESCRIPTION
Alias functions using the Invoke-GitRepoCommand internal function that runs specified git commands in the current repo,
or all repos located in subdirectories of the current folder.
Function runs only in repositories with remote set.
#>

<#
.SYNOPSIS
Invoke-GitRepoCommand alias function.

.PARAMETER cmd
Script block of commands to execute.
#>
function grunrepocmd ([scriptblock]$cmd) {
    Invoke-GitRepoCommand -Command $cmd
}


<#
.SYNOPSIS
Refresh all git repositories in subdirectories of the current folder.
#>
function grunrefresh {
    # prepare commands to execute
    $cmd = {
        # calculate arguments
        $defaultBranch = Get-GitResolvedBranch
        $remote = @(git remote)[0]

        # run git commands
        git fetch --all --tags --prune --prune-tags --force
        $switch = Invoke-WriteExecCommand -Command "git switch $defaultBranch"
        # run commands if switched branch successfully
        if ($?) {
            if ($switch -ne "Your branch is up to date with '$remote/$defaultBranch'.") {
                Invoke-WriteExecCommand -Command "git merge ${remote}/${defaultBranch}"
            }
            Remove-GitMergedBranches
        }
    }
    # run git repository command
    Invoke-GitRepoCommand -Command $cmd
}


<#
.SYNOPSIS
Set git local settings in all git repositories.

.PARAMETER Option
Git local setting option.
.PARAMETER Value
Git local setting value.
#>
function gruncfl {
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Option,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )

    $cmd = {
        git config --local $Option $Value
        Write-Host "${Option}: $(git config --local $Option)"
    }
    Invoke-GitRepoCommand -Command $cmd
}
#endregion


#region git stash functions
function gstaap {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [ArgumentCompleter({ ArgGitGetStashList @args })]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # command string
    $cmnd = 'git stash apply --force'
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gstad {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [ArgumentCompleter({ ArgGitGetStashList @args })]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # command string
    $cmnd = 'git stash drop'
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gstas {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [ArgumentCompleter({ ArgGitGetStashList @args })]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # command string
    $cmnd = 'git stash show'
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gstast {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [ArgumentCompleter({ ArgGitGetStashList @args })]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # command string
    $cmnd = 'git stash show --text'
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
#endregion


#region helper switch functions
function gsw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git switch $(Get-GitResolvedBranch $Branch)"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
function gsw! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    # calculate command string
    $cmnd = "git switch $(Get-GitResolvedBranch $Branch) --force"
    $PSBoundParameters.Remove('Branch') | Out-Null
    # run command
    Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
}
#endregion
