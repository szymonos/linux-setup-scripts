#!/usr/bin/env -S pwsh -nop
<#
.SYNOPSIS
Setting up PowerShell for the current user.
.EXAMPLE
.assets/provision/setup_profile_user.ps1
#>
$WarningPreference = 'Ignore'

# *PowerShell profile
if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
    Write-Host 'setting PSGallery trusted...'
    Set-PSResourceRepository -Name PSGallery -Trusted
}

$kubectlSet = try { Select-String '__kubectl_debug' -Path $PROFILE -Quiet } catch { $false }
if ((Test-Path /usr/bin/kubectl) -and -not $kubectlSet) {
    Write-Host 'adding kubectl auto-completion...'
    New-Item ([IO.Path]::GetDirectoryName($PROFILE)) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    (/usr/bin/kubectl completion powershell).Replace("'kubectl'", "'k'") >$PROFILE
}

$condaSet = try { Select-String 'conda init' -Path $PROFILE.CurrentUserAllHosts -Quiet } catch { $false }
if ((Test-Path $HOME/miniconda3/bin/conda) -and -not $condaSet) {
    Write-Host 'adding miniconda initialization...'
    & "$HOME/miniconda3/bin/conda" init powershell | Out-Null
}
