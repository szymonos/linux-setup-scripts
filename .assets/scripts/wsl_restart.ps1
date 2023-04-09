#Requires -RunAsAdministrator
<#
.SYNOPSIS
Restart WSL.
.EXAMPLE
.assets/scripts/wsl_restart.ps1
gsudo .assets/scripts/wsl_restart.ps1
#>

Get-Process docker* | Stop-Process -Force
Start-Sleep 1
Get-Process wsl* | Stop-Process -Force
Start-Sleep 1
Get-Service LxssManagerUser* | Restart-Service -Force
