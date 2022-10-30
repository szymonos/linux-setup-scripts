#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Setting up PowerShell for the current user.
.EXAMPLE
.assets/provision/setup_profiles_user.ps1
#>
$WarningPreference = 'Ignore'

# *PowerShell profile
if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
    Write-Host 'setting PSGallery trusted...' -ForegroundColor Cyan
    Set-PSResourceRepository -Name PSGallery -Trusted
}
if (-not $PSNativeCommandArgumentPassing) {
    Write-Host 'enabling PSNativeCommandArgumentPassing...' -ForegroundColor Cyan
    Enable-ExperimentalFeature PSNativeCommandArgumentPassing
}
if (-not $PSStyle) {
    Write-Host 'enabling PSAnsiRenderingFileInfo...' -ForegroundColor Cyan
    Enable-ExperimentalFeature PSAnsiRenderingFileInfo
}

$profileSet = try { Select-String '__kubectl_debug' -Path $PROFILE -Quiet } catch { $false }
if ((Test-Path /usr/bin/kubectl) -and -not $profileSet) {
    Write-Host 'setting kubectl auto-completion...' -ForegroundColor Cyan
    (/usr/bin/kubectl completion powershell).Replace("'kubectl'", "'k'") >$PROFILE
}
