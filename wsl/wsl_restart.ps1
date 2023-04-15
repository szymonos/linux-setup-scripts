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

if ($StopDockerDesktop) {
    Get-Process docker* | Stop-Process -Force
}

# stop wsl processess
Get-Process wsl* | Stop-Process -Force

# restart LxssManagerUser service
Get-Service LxssManagerUser* | Restart-Service -Force
