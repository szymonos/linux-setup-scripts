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
# set up Microsoft.PowerShell.PSResourceGet and update installed modules
if (Get-Module -Name Microsoft.PowerShell.PSResourceGet -ListAvailable) {
    if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
        Write-Host 'setting PSGallery trusted...'
        Set-PSResourceRepository -Name PSGallery -Trusted
        # update help, assuming this is the initial setup
        Write-Host 'updating help...'
        Update-Help -UICulture en-US
    }
    # update existing modules
    if (Test-Path .assets/provision/update_psresources.ps1 -PathType Leaf) {
        .assets/provision/update_psresources.ps1
    }
}
# install PSReadLine
for ($i = 0; ((Get-Module PSReadLine -ListAvailable).Count -eq 1) -and $i -lt 5; $i++) {
    Write-Host 'installing PSReadLine...'
    Install-PSResource -Name PSReadLine
}

# install kubectl autocompletion
if (Test-Path /usr/bin/kubectl -PathType Leaf) {
    $kubectlSet = try { Select-String 'Set-Alias -Name k' -Path $PROFILE.CurrentUserCurrentHost -SimpleMatch -Quiet } catch { $false }
    if (-not $kubectlSet) {
        Write-Host 'adding kubectl auto-completion...'
        # build completer text
        $completer = [string]::Join("`n",
            (/usr/bin/kubectl completion powershell) -join "`n",
            "`n# setup autocompletion for the 'k' alias",
            'Set-Alias -Name k -Value kubectl',
            "Register-ArgumentCompleter -CommandName 'k' -ScriptBlock `${__kubectlCompleterBlock}"
        )
        # add additional ArgumentCompleter at the end of the profile
        [System.IO.File]::WriteAllText($PROFILE, $completer)
    }
}

# setup conda initialization
if (Test-Path $HOME/miniconda3/bin/conda -PathType Leaf) {
    $condaSet = try { Select-String 'conda init' -Path $PROFILE.CurrentUserAllHosts -Quiet } catch { $false }
    # add conda init to the user profile
    if (-not $condaSet) {
        Write-Verbose 'adding miniconda initialization...'
        $content = [string]::Join("`n",
            '#region conda initialize',
            'try { (& "$HOME/miniconda3/bin/conda" "shell.powershell" "hook") | Out-String | Invoke-Expression | Out-Null } catch { Out-Null }',
            '#endregion'
        )
        [System.IO.File]::AppendAllText($PROFILE.CurrentUserAllHosts, $content)
    }
    # disable conda env prompt if oh-my-posh is installed
    if (Test-Path /usr/bin/oh-my-posh -PathType Leaf) {
        $changeps1 = & "$HOME/miniconda3/bin/conda" config --show changeps1 | Select-String 'False' -Quiet
        if (-not $changeps1) {
            & "$HOME/miniconda3/bin/conda" config --set changeps1 false
        }
    }
}

# add uv autocompletion
if (Test-Path "$HOME/.local/bin/uv" -PathType Leaf) {
    $uvSet = try { Select-String 'uv generate-shell-completion' -Path $PROFILE.CurrentUserAllHosts -SimpleMatch -Quiet } catch { $false }
    if (-not $uvSet) {
        Write-Verbose 'adding uv autocompletion...'
        $content = [string]::Join("`n",
            "`n#region uv autocompletion",
            'try { (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression | Out-Null } catch { Out-Null }',
            '#endregion'
        )
        [System.IO.File]::AppendAllText($PROFILE.CurrentUserAllHosts, $content)
    }
}
