#!/usr/bin/env -S pwsh -nop
<#
.SYNOPSIS
Setting up PowerShell for the all users.
.EXAMPLE
sudo .assets/provision/setup_profiles_allusers.ps1
#>
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'Ignore'

# path varaibles
$SCRIPTS_PATH = '/usr/local/share/powershell/Scripts'

# determine folder with config files
$assets = $env:WSL_DISTRO_NAME ? '.assets' : '/tmp'

# *Copy global profiles
if (Test-Path $assets/config/pwsh_cfg -PathType Container) {
    # PowerShell profile
    Copy-Item $assets/config/pwsh_cfg/profile.ps1 -Destination $PROFILE.AllUsersAllHosts
    # PowerShell functions
    New-Item $SCRIPTS_PATH -ItemType Directory | Out-Null
    Copy-Item $assets/config/pwsh_cfg/ps_aliases_common.ps1 -Destination $SCRIPTS_PATH
    # git functions
    if (Test-Path /usr/bin/git -PathType Leaf) {
        Copy-Item $assets/config/pwsh_cfg/ps_aliases_git.ps1 -Destination $SCRIPTS_PATH
    }
    # kubectl functions
    if (Test-Path /usr/bin/kubectl -PathType Leaf) {
        Copy-Item $assets/config/pwsh_cfg/ps_aliases_kubectl.ps1 -Destination $SCRIPTS_PATH
    }
    if (Test-Path /tmp/config/pwsh_cfg -PathType Container) {
        # clean config folder
        Remove-Item -Force -Recurse /tmp/config/pwsh_cfg
    }
}

# *PowerShell profile
if (-not ((Get-Module PowerShellGet -ListAvailable -ErrorAction SilentlyContinue).Version.Major -ge 3)) {
    Write-Host 'installing PowerShellGet...'
    Install-Module PowerShellGet -AllowPrerelease -Scope AllUsers -Force
}
if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
    Write-Host 'setting PSGallery trusted...'
    Set-PSResourceRepository -Name PSGallery -Trusted
}
if (-not (Get-Module posh-git -ListAvailable)) {
    Write-Host 'installing posh-git...'
    Install-PSResource -Name posh-git -Scope AllUsers
}
