#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Setting up PowerShell for the all users.
.EXAMPLE
.assets/provision/setup_profiles_allusers.ps1
#>
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'Ignore'

# path varaibles
$PROFILE_PATH = [IO.Path]::GetDirectoryName($PROFILE.AllUsersAllHosts)
$SCRIPTS_PATH = '/usr/local/share/powershell/Scripts'

# *Copy global profiles
if (Test-Path /tmp/pwsh_cfg -PathType Container) {
    # PowerShell profile
    Move-Item /tmp/pwsh_cfg/profile.ps1 -Destination $PROFILE_PATH
    # PowerShell functions
    New-Item $SCRIPTS_PATH -ItemType Directory
    Move-Item /tmp/pwsh_cfg/ps_aliases_common.ps1 -Destination $SCRIPTS_PATH
    # git functions
    if (Test-Path /usr/bin/git -PathType Leaf) {
        Move-Item /tmp/pwsh_cfg/ps_aliases_git.ps1 -Destination $SCRIPTS_PATH
    }
    # kubectl functions
    if (Test-Path /usr/bin/kubectl -PathType Leaf) {
        Move-Item /tmp/pwsh_cfg/ps_aliases_kubectl.ps1 -Destination $SCRIPTS_PATH
    }
    # clean config folder
    Remove-Item -Force -Recurse /tmp/pwsh_cfg
}

# *PowerShell profile
if (-not ((Get-Module PowerShellGet -ListAvailable -ErrorAction SilentlyContinue).Version.Major -ge 3)) {
    Write-Host 'installing PowerShellGet...' -ForegroundColor Cyan
    Install-Module PowerShellGet -AllowPrerelease -Scope AllUsers -Force
}
if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
    Write-Host 'setting PSGallery trusted...' -ForegroundColor Cyan
    Set-PSResourceRepository -Name PSGallery -Trusted
}
if (-not ((Get-Module PSReadLine -ListAvailable -ErrorAction SilentlyContinue).Version.Minor -ge 2)) {
    Write-Host 'installing PSReadLine...' -ForegroundColor Cyan
    Install-PSResource -Name PSReadLine -Scope AllUsers
}
if (-not (Get-Module posh-git -ListAvailable)) {
    Write-Host 'installing posh-git...' -ForegroundColor Cyan
    Install-PSResource -Name posh-git -Scope AllUsers
}
if (-not $PSNativeCommandArgumentPassing) {
    Write-Host 'enabling PSNativeCommandArgumentPassing...' -ForegroundColor Cyan
    Enable-ExperimentalFeature PSNativeCommandArgumentPassing
}
if (-not $PSStyle) {
    Write-Host 'enabling PSAnsiRenderingFileInfo...' -ForegroundColor Cyan
    Enable-ExperimentalFeature PSAnsiRenderingFileInfo
}
