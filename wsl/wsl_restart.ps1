#Requires -RunAsAdministrator
<#
.SYNOPSIS
Restart WSL.

.PARAMETER StopDockerDesktop
Flag whether to stop DockerDesktop process.

.EXAMPLE
wsl/wsl_restart.ps1
gsudo wsl/wsl_restart.ps1
gsudo wsl/wsl_restart.ps1 -StopDockerDesktop
#>
[CmdletBinding()]
param (
    [Parameter()]
    [switch]$StopDockerDesktop
)

# check if the script is running on Windows
if ($env:OS -notmatch 'windows') {
    Write-Warning 'Run the script on Windows!'
    exit 0
}

if ($StopDockerDesktop) {
    Get-Process docker* | Stop-Process -Force
}

# stop wsl processess
Get-Process wsl* | Stop-Process -Force

# restart LxssManagerUser service
Get-Service LxssManagerUser*, WSLService | Restart-Service -Force
