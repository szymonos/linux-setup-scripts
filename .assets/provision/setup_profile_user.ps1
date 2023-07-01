#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Setting up PowerShell for the current user.

.EXAMPLE
.assets/provision/setup_profile_user.ps1
#>
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'Ignore'

# *PowerShell profile
# create user profile powershell config directory
$profileDir = [IO.Path]::GetDirectoryName($PROFILE)
if (-not (Test-Path $profileDir -PathType Container)) {
    New-Item $profileDir -ItemType Directory | Out-Null
}
# set up PowerShellGet and update installed modules
if (Get-InstalledModule -Name PowerShellGet) {
    if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
        Write-Host 'setting PSGallery trusted...'
        Set-PSResourceRepository -Name PSGallery -Trusted
        # update help, assuming this is the initial setup
        Write-Host 'updating help...'
        Update-Help
    }
    # update existing modules
    if (Test-Path .assets/provision/update_psresources.ps1 -PathType Leaf) {
        .assets/provision/update_psresources.ps1
    }
}
# disable oh-my-posh update notice
if (Get-Command oh-my-posh -CommandType Application) {
    oh-my-posh disable notice
}

$kubectlSet = try { Select-String '__kubectl_debug' -Path $PROFILE -Quiet } catch { $false }
if ((Test-Path /usr/bin/kubectl) -and -not $kubectlSet) {
    Write-Host 'adding kubectl auto-completion...'
    (/usr/bin/kubectl completion powershell).Replace("'kubectl'", "'k'") >$PROFILE
}

$condaSet = try { Select-String 'conda init' -Path $PROFILE.CurrentUserAllHosts -Quiet } catch { $false }
if ((Test-Path $HOME/miniconda3/bin/conda) -and -not $condaSet) {
    Write-Verbose 'adding miniconda initialization...'
    [string]::Join("`n",
        '#region conda initialize',
        'try { (& "$HOME/miniconda3/bin/conda" "shell.powershell" "hook") | Out-String | Invoke-Expression } catch { Out-Null }',
        '#endregion'
    ) | Add-Content $PROFILE.CurrentUserAllHosts
}
