#Requires -RunAsAdministrator
<#
.SYNOPSIS
Restart WSL.

.DESCRIPTION
Running the script fixes issues with unresponsive WSL or user permissions issues.
The script stops all running wsl processes and then restarts the following services:
- LxssManagerUser: Linux Subsystem User Manager
- WSLService: WSL Service
- vmcompute: Hyper-V Host Compute Service

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

# stop WSL processess
Get-Process wsl* | Stop-Process -Force

# restart services related to WSL
Get-Service LxssManagerUser*, WSLService, vmcompute | Restart-Service -Force
