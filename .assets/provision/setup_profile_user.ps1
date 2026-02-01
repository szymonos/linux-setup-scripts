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
        [System.IO.File]::WriteAllText($PROFILE, "$($completer.Trim())`n")
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

#region $PROFILE.CurrentUserAllHosts,
# load existing profile
$profileContent = [System.Collections.Generic.List[string]]::new()
if (Test-Path $PROFILE.CurrentUserAllHosts -PathType Leaf) {
    $profileContent.AddRange([System.IO.File]::ReadAllLines($PROFILE.CurrentUserAllHosts))
}
# track if profile is modified
$isProfileModified = $false

# setup conda initialization
$condaCli = 'miniforge3/bin/conda'
if (Test-Path "$HOME/$condaCli" -PathType Leaf) {
    if (-not ($profileContent | Select-String $condaCli -SimpleMatch -Quiet)) {
        Write-Verbose 'adding miniforge initialization...'
        $profileContent.AddRange(
            [string[]]@(
                "`n#region conda"
                '# initialization'
                "try { (& `"`$HOME/$condaCli`" 'shell.powershell' 'hook') | Out-String | Invoke-Expression | Out-Null } catch { Out-Null }"
                '#endregion'
            )
        )
        $isProfileModified = $true
    }
    # hide conda env in shell prompt if oh-my-posh is installed
    if (Test-Path /usr/bin/oh-my-posh -PathType Leaf) {
        $changeps1 = & "$HOME/$condaCli" config --show | Select-String 'changeps1: False' -SimpleMatch -Quiet
        if (-not $changeps1) {
            & "$HOME/$condaCli" config --set changeps1 false
        }
    }
}

# set up uv
$uvCli = '.local/bin/uv'
if (Test-Path "$HOME/$uvCli" -PathType Leaf) {
    if (-not ($profileContent | Select-String 'UV_NATIVE_TLS' -SimpleMatch -Quiet)) {
        Write-Verbose 'adding uv autocompletion...'
        $profileContent.AddRange(
            [string[]]@(
                "`n#region uv"
                '# use system certificates'
                '[System.Environment]::SetEnvironmentVariable("UV_NATIVE_TLS", $true)'
            )
        )
        $isProfileModified = $true

        $completionCmd = 'generate-shell-completion powershell'
        if (-not ($profileContent | Select-String $completionCmd -SimpleMatch -Quiet)) {
            $profileContent.AddRange(
                [string[]]@(
                    '# autocompletion'
                    "try { (& `"`$HOME/$uvCli`" $completionCmd) | Out-String | Invoke-Expression | Out-Null } catch { Out-Null }"
                    '#endregion'
                )
            )
            $isProfileModified = $true
        } else {
            $profileContent.Add('#endregion')
        }
    }
}

# set up pixi
$pixiCli = '.pixi/bin/pixi'
if (Test-Path "$HOME/$pixiCli" -PathType Leaf) {
    if (-not ($profileContent | Select-String $pixiCli -SimpleMatch -Quiet)) {
        Write-Verbose 'adding pixi autocompletion...'
        $profileContent.AddRange(
            [string[]]@(
                "`n#region pixi"
                '# autocompletion'
                "try { (& `"`$HOME/$pixiCli`" completion --shell powershell) | Out-String | Invoke-Expression } catch { Out-Null }"
                '#endregion'
            )
        )
        $isProfileModified = $true
    }
    # hide pixi env in shell prompt if oh-my-posh is installed
    if (Test-Path /usr/bin/oh-my-posh -PathType Leaf) {
        $changeps1 = & "$HOME/$pixiCli" config list | Select-String 'change-ps1 = false' -SimpleMatch -Quiet
        if (-not $changeps1) {
            & "$HOME/$pixiCli" config set --global shell.change-ps1 false
        }
    }
}

# save profile if modified
if ($isProfileModified) {
    [System.IO.File]::WriteAllText(
        $PROFILE.CurrentUserAllHosts,
        "$(($profileContent -join "`n").Trim())`n"
    )
}
#endregion
