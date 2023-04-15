#Requires -RunAsAdministrator
<#
.SYNOPSIS
Restart WSL.
.EXAMPLE
wsl/wsl_restart.ps1
gsudo wsl/wsl_restart.ps1
#>

Get-Process docker* | Stop-Process -Force
Start-Sleep 1
Get-Process wsl* | Stop-Process -Force
Start-Sleep 1
Get-Service LxssManagerUser* | Restart-Service -Force
