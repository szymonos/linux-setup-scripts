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
    $kubectlSet = try { Select-String 'kubecolor' -Path $PROFILE.CurrentUserCurrentHost -SimpleMatch -Quiet } catch { $false }
    if (-not $kubectlSet) {
        Write-Host 'adding kubectl auto-completion...'
        # build completer text
        $completer = [string]::Join("`n",
            (/usr/bin/kubectl completion powershell) -join "`n",
            "`n# setup autocompletion for the 'k' alias",
            'Set-Alias -Name k -Value kubectl',
            "Register-ArgumentCompleter -CommandName 'k' -ScriptBlock `${__kubectlCompleterBlock}",
            "`n# setup autocompletion for the 'kubecolor' binary",
            'if (Test-Path /usr/bin/kubecolor -PathType Leaf) {',
            '    Set-Alias -Name kubectl -Value kubecolor',
            "    Register-ArgumentCompleter -CommandName 'kubecolor' -ScriptBlock `${__kubectlCompleterBlock}",
            '}'
        )
        # add additional ArgumentCompleter at the end of the profile
        [System.IO.File]::WriteAllText($PROFILE, $completer)
    }
}

# add gh copilot aliases
if (Test-Path /usr/bin/gh) {
    if (gh extension list | Select-String 'github/gh-copilot' -SimpleMatch -Quiet) {
        $USER_SCRIPTS_PATH = "$HOME/.config/powershell/Scripts"
        if (-not (Test-Path $USER_SCRIPTS_PATH)) {
            New-Item -Path $USER_SCRIPTS_PATH -ItemType Directory -Force | Out-Null
        }
        $GH_COPILOT_PROFILE = Join-Path -Path $USER_SCRIPTS_PATH -ChildPath '_aliases_copilot.ps1'
        gh copilot alias -- pwsh | Out-File ( New-Item -Path $GH_COPILOT_PROFILE -Force )
    }
}

# setup conda initialization
if (Test-Path $HOME/miniforge3/bin/conda -PathType Leaf) {
    $condaSet = try { Select-String 'conda init' -Path $PROFILE.CurrentUserAllHosts -Quiet } catch { $false }
    # add conda init to the user profile
    if (-not $condaSet) {
        Write-Verbose 'adding miniforge initialization...'
        $content = [string]::Join("`n",
            '#region conda initialize',
            'try { (& "$HOME/miniforge3/bin/conda" "shell.powershell" "hook") | Out-String | Invoke-Expression | Out-Null } catch { Out-Null }',
            '#endregion'
        )
        [System.IO.File]::AppendAllText($PROFILE.CurrentUserAllHosts, $content)
    }
    # disable conda env prompt if oh-my-posh is installed
    if (Test-Path /usr/bin/oh-my-posh -PathType Leaf) {
        $changeps1 = & "$HOME/miniforge3/bin/conda" config --show changeps1 | Select-String 'False' -Quiet
        if (-not $changeps1) {
            & "$HOME/miniforge3/bin/conda" config --set changeps1 false
        }
    }
}

# set up uv
if (Test-Path "$HOME/.local/bin/uv" -PathType Leaf) {
    # enable shell completion
    $uvSet = try { Select-String 'uv generate-shell-completion' -Path $PROFILE.CurrentUserAllHosts -SimpleMatch -Quiet } catch { $false }
    if (-not $uvSet) {
        Write-Verbose 'adding uv autocompletion...'
        $content = [string]::Join("`n",
            "`n#region uv",
            "# use system certificates",
            '[System.Environment]::SetEnvironmentVariable("UV_NATIVE_TLS", $true)',
            "`n# autocompletion",
            'try { (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression | Out-Null } catch { Out-Null }',
            '#endregion'
        )
        [System.IO.File]::AppendAllText($PROFILE.CurrentUserAllHosts, $content)
    }
}
