#!/usr/bin/env -S pwsh -nop
<#
.SYNOPSIS
Setting up PowerShell for the all users.
.EXAMPLE
sudo .assets/provision/setup_profile_allusers.ps1
#>
$WarningPreference = 'Ignore'

# path variables
$CFG_PATH = '/tmp/config/pwsh_cfg'
$SCRIPTS_PATH = '/usr/local/share/powershell/Scripts'
# copy config files for WSL setup
if (Test-Path .assets/config/pwsh_cfg -PathType Container) {
    if (-not (Test-Path $CFG_PATH)) {
        New-Item $CFG_PATH -ItemType Directory | Out-Null
    }
    Copy-Item .assets/config/pwsh_cfg/* $CFG_PATH -Force
}
# *modify exa alias
if (Test-Path $CFG_PATH/_aliases_linux.ps1) {
    $exa_git = try { exa --version | Select-String '+git' -SimpleMatch -Quiet } catch { $false }
    $exa_nerd = try { Select-String '\ue725' -Path /usr/local/share/oh-my-posh/theme.omp.json -SimpleMatch -Quiet } catch { $false }
    $exa_param = ($exa_git ? '--git ' : '') + ($exa_nerd ? '--icons ' : '')
    [IO.File]::ReadAllLines("$CFG_PATH/_aliases_linux.ps1").Replace('exa -g ', "exa -g $exa_param") `
    | Set-Content $CFG_PATH/_aliases_linux.ps1 -Encoding utf8
}

# *Copy global profiles
if (Test-Path $CFG_PATH -PathType Container) {
    # PowerShell profile
    install -o root -g root -m 0644 $CFG_PATH/profile.ps1 $PROFILE.AllUsersAllHosts
    # PowerShell functions
    if (-not (Test-Path $SCRIPTS_PATH)) {
        New-Item $SCRIPTS_PATH -ItemType Directory | Out-Null
    }
    install -o root -g root -m 0644 $CFG_PATH/_aliases_common.ps1 $SCRIPTS_PATH
    install -o root -g root -m 0644 $CFG_PATH/_aliases_linux.ps1 $SCRIPTS_PATH
    # git functions
    if (Test-Path /usr/bin/git -PathType Leaf) {
        install -o root -g root -m 0644 $CFG_PATH/_aliases_git.ps1 $SCRIPTS_PATH
    }
    # kubectl functions
    if (Test-Path /usr/bin/kubectl -PathType Leaf) {
        install -o root -g root -m 0644 $CFG_PATH/_aliases_kubectl.ps1 $SCRIPTS_PATH
    }
    # clean config folder
    Remove-Item $CFG_PATH -Recurse -Force
    # TODO to be removed, cleanup legacy aliases
    Get-ChildItem -Path $SCRIPTS_PATH -Filter 'ps_aliases_*.ps1' -File | Remove-Item -Force
}

# *PowerShell profile
for ($i = 0; -not ((Get-Module PowerShellGet -ListAvailable).Version.Major -ge 3) -and $i -lt 10; $i++) {
    Write-Host 'installing PowerShellGet...'
    Install-Module PowerShellGet -AllowPrerelease -Scope AllUsers -Force
}
if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
    Write-Host 'setting PSGallery trusted...'
    Set-PSResourceRepository -Name PSGallery -Trusted
}
for ($i = 0; -not (Get-Module posh-git -ListAvailable) -and $i -lt 10; $i++) {
    Write-Host 'installing posh-git...'
    Install-PSResource -Name posh-git -Scope AllUsers
}
# update existing modules
.assets/provision/update_psresources.ps1
