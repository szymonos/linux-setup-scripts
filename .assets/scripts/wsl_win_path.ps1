<#
.SYNOPSIS
Manage appending windows paths in PowerShell profile.
.EXAMPLE
$DisableWinPath = $false
.assets/scripts/wsl_win_path.ps1
.assets/scripts/wsl_win_path.ps1 -DisableWinPath $false
#>
[CmdletBinding()]
param (
    [bool]$DisableWinPath = $true
)
$ErrorActionPreference = 'Stop'

# command for removing Windows paths
$REMOVE_CMD = @'
# remove '/mnt/c' paths from PATH environment variable
[Environment]::SetEnvironmentVariable('PATH', [string]::Join(':', $env:PATH.Split(':') -notmatch '^/mnt/c'))
'@

# determine if profile exist and if command for removing path exist
$state = try {
    $psProfile = [IO.File]::ReadAllText($PROFILE.CurrentUserAllHosts).Trim().Split("`n")
    if ($psProfile -match '/mnt/c') {
        'set_path_exist'
    } else {
        'no_set_path'
    }
} catch {
    'noprofile'
}

# calculate user profile content
if ($DisableWinPath) {
    switch ($state) {
        set_path_exist {
            exit
        }
        no_set_path {
            $psProfile = [string]::Join("`n", $psProfile + '' + $REMOVE_CMD)
            continue
        }
        noprofile {
            $psProfile = $REMOVE_CMD
            continue
        }
    }
} else {
    if ($state -eq 'set_path_exist') {
        $psProfile = [string]::Join("`n", ($psProfile -notmatch '/mnt/c')).Trim()
    } else {
        exit
    }
}

# write updated profile
[IO.File]::WriteAllText($PROFILE.CurrentUserAllHosts, ($psProfile -replace "`n{3,}", "`n`n"))

# show current profile
if (Get-Command bat -CommandType Application) {
    bat --paging=never $PROFILE.CurrentUserAllHosts
} else {
    cat $PROFILE.CurrentUserAllHosts
}
