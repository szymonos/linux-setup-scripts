<#
.SYNOPSIS
Manage appending windows paths in PowerShell profile. Script has to be executed inside WSL distro.

.PARAMETER DisableWinPath
Flag wheter to remove windows paths from the PATH environment variable.

.EXAMPLE
$DisableWinPath = $false
wsl/wsl_win_path.ps1
wsl/wsl_win_path.ps1 -DisableWinPath $false

.NOTES
# :save script example
./scripts_egsave.ps1 wsl/wsl_win_path.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 wsl/wsl_win_path.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 wsl/wsl_win_path.ps1 -WriteOutput)
#>
[CmdletBinding()]
param (
    [bool]$DisableWinPath = $true
)
$ErrorActionPreference = 'Stop'
# check if the script is running on Windows
if ($env:OS -notmatch 'windows') {
    Write-Warning 'Run the script on Windows!'
    exit 0
}

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
