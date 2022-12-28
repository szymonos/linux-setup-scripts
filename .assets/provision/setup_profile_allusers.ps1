#!/usr/bin/env -S pwsh -nop
<#
.SYNOPSIS
Setting up PowerShell for the all users.
.EXAMPLE
sudo .assets/provision/setup_profile_allusers.ps1
#>
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'Ignore'

# path variables
$CFG_PATH = '/tmp/config/pwsh_cfg'
$SCRIPTS_PATH = '/usr/local/share/powershell/Scripts'
# copy config files for WSL setup
if (Test-Path .assets/config/pwsh_cfg -PathType Container) {
    New-Item $CFG_PATH -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    Copy-Item .assets/config/pwsh_cfg/* $CFG_PATH -Force
}

# *Copy global profiles
if (Test-Path $CFG_PATH -PathType Container) {
    # PowerShell profile
    Move-Item $CFG_PATH/profile.ps1 -Destination $PROFILE.AllUsersAllHosts -Force
    # PowerShell functions
    New-Item $SCRIPTS_PATH -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    Move-Item $CFG_PATH/ps_aliases_common.ps1 -Destination $SCRIPTS_PATH -Force
    Move-Item $CFG_PATH/ps_aliases_linux.ps1 -Destination $SCRIPTS_PATH -Force
    # git functions
    if (Test-Path /usr/bin/git -PathType Leaf) {
        Move-Item $CFG_PATH/ps_aliases_git.ps1 -Destination $SCRIPTS_PATH -Force
    }
    # kubectl functions
    if (Test-Path /usr/bin/kubectl -PathType Leaf) {
        Move-Item $CFG_PATH/ps_aliases_kubectl.ps1 -Destination $SCRIPTS_PATH -Force
    }
    # clean config folder
    Remove-Item $CFG_PATH -Recurse -Force
}

# *PowerShell profile
while (-not ((Get-Module PowerShellGet -ListAvailable).Version.Major -ge 3)) {
    Write-Host 'installing PowerShellGet...'
    Install-Module PowerShellGet -AllowPrerelease -Scope AllUsers -Force
}
if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
    Write-Host 'setting PSGallery trusted...'
    Set-PSResourceRepository -Name PSGallery -Trusted
}
while (-not (Get-Module posh-git -ListAvailable)) {
    Write-Host 'installing posh-git...'
    Install-PSResource -Name posh-git -Scope AllUsers
}
