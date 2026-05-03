#region alias
Set-Alias -Name gglobj -Value Get-GitLogObject -Scope Global
Set-Alias -Name grlobj -Value Get-GitReflogObject -Scope Global
#endregion


#region helper git log functions
<#
.SYNOPSIS
Get-GitLogObject function aliases.
#>
function gglogs {
    [CmdletBinding()]
    param (
        [switch]$All,

        [switch]$Grep,

        [switch]$Limit,

        [switch]$Tags,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    Get-GitLogObject @PSBoundParameters | Select-Object Commit, DateUTC, Subject, Author
}


function gglo {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    gglogs @PSBoundParameters -Limit
}


function ggloa {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    gglogs @PSBoundParameters -Limit -All
}
#endregion


#region helper git log colored functions
<#
.SYNOPSIS
Get-GitLogObject function colored aliases.
#>
function gglogc {
    [CmdletBinding()]
    param (
        [switch]$All,

        [switch]$Grep,

        [switch]$Limit,

        [switch]$Tags,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    # build properties for Format-Table
    $refCmd = {
        $refs = switch -Regex ($_.Ref.Split(',').Trim().Where({ $_ -ne 'origin/HEAD' })) {
            '^tag:' { "`e[1;93m$($_ -replace '^tag: ')`e[0m" }
            '^origin/' { "`e[1;91m$_`e[0m" }
            '^HEAD' { "`e[1;96mHEAD -> `e[92m$($_ -replace 'HEAD -> ')`e[0m" }
            Default { "`e[1;92m$_`e[0m" }
        }
        $([string]::Join(', ', $refs))
    }
    $prop = @(
        @{ Name = 'Commit'; Expression = { "`e[33m$($_.Commit)`e[0m" } }
        @{ Name = 'DateUTC'; Expression = { "`e[32m$($_.DateUTC)`e[0m" } }
        @{ Name = 'Subject'; Expression = { $_.Subject.Substring(0, [Math]::Min(59, $_.Subject.Length)) } }
        @{ Name = 'Author'; Expression = { "`e[94;1m$($_.Author)`e[0m" } }
        @{ Name = 'Email'; Expression = { "`e[34;3m$($_.Email -match 'users.noreply.github.com' ? 'noreply@github.com' : $_.Email)`e[0m" } }
        @{ Name = 'Ref'; Expression = $refCmd }
    )

    Get-GitLogObject @PSBoundParameters | Format-Table -Property $prop -Wrap
}


function ggloc {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    gglogc @PSBoundParameters -Limit
}


function ggloca {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    gglogc @PSBoundParameters -Limit -All
}


function gglot {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    gglogc @PSBoundParameters -Limit -Tags
}
#endregion



#region helper git reflog functions
<#
.SYNOPSIS
Get-GitReflogObject function aliases.
#>
function grlogs {
    [CmdletBinding()]
    param (
        [switch]$Limit,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    Get-GitReflogObject @PSBoundParameters | Select-Object Commit, Selector, DateUTC, Subject, Author, Ref
}


function grlo {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    grlogs @PSBoundParameters -Limit
}
#endregion


#region helper git reflog colored functions
<#
.SYNOPSIS
Get-GitReflogObject function colored aliases.
#>
function grlogc {
    [CmdletBinding()]
    param (
        [switch]$Limit,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    # build properties for Format-Table
    $refCmd = {
        $refs = switch -Regex ($_.Ref.Split(',').Trim().Where({ $_ -ne 'origin/HEAD' })) {
            '^tag:' { "`e[1;93m$($_ -replace '^tag: ')`e[0m" }
            '^origin/' { "`e[1;91m$_`e[0m" }
            '^HEAD' { "`e[1;96mHEAD -> `e[92m$($_ -replace 'HEAD -> ')`e[0m" }
            Default { "`e[1;92m$_`e[0m" }
        }
        $([string]::Join(', ', $refs))
    }
    $prop = @(
        @{ Name = 'Commit'; Expression = { "`e[33m$($_.Commit)`e[0m" } }
        @{ Name = 'Selector'; Expression = { "`e[36m$($_.Selector)`e[0m" } }
        @{ Name = 'DateUTC'; Expression = { "`e[32m$($_.DateUTC)`e[0m" } }
        @{ Name = 'Subject'; Expression = { $_.Subject.Substring(0, [Math]::Min(59, $_.Subject.Length)) } }
        @{ Name = 'Author'; Expression = { "`e[94;1m$($_.Author)`e[0m" } }
        @{ Name = 'Email'; Expression = { "`e[34;3m$($_.Email -match 'users.noreply.github.com' ? 'noreply@github.com' : $_.Email)`e[0m" } }
        @{ Name = 'Ref'; Expression = $refCmd }
    )

    Get-GitReflogObject @PSBoundParameters | Format-Table -Property $prop -Wrap
}


function grloc {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    grlogc @PSBoundParameters -Limit
}
#endregion


#region helper git grep functions
function ggrep {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Grep,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    $arguments = if ($PSBoundParameters.Xargs) {
        ,"--grep=$Grep" + $Xargs
    } else {
        "--grep=$Grep"
    }

    gglogs $arguments -Grep
}


function ggrepa {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Grep,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    $arguments = if ($PSBoundParameters.Xargs) {
        ,"--grep=$Grep" + $Xargs
    } else {
        "--grep=$Grep"
    }

    gglogs $arguments -Grep -All
}


function ggrepc {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Grep,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    $arguments = if ($PSBoundParameters.Xargs) {
        ,"--grep=$Grep" + $Xargs
    } else {
        "--grep=$Grep"
    }

    gglogc $arguments -Grep
}


function ggrepca {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Grep,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    $arguments = if ($PSBoundParameters.Xargs) {
        ,"--grep=$Grep" + $Xargs
    } else {
        "--grep=$Grep"
    }

    gglogc $arguments -Grep -All
}


function glom {
    Get-GitLogMessage
}


function glom1 {
    Get-GitLogMessage -First
}
#endregion
