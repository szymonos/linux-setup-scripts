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

# *clean up obsolete modules superseded by a rename
# do-linux was renamed to do-unix; both export the same function/alias names, so a
# stale do-linux left in the user module path would shadow do-unix with duplicate
# commands. Remove it before the new module is installed. Only user scope is needed -
# do-linux was never installed AllUsers (do-common is the only system-wide module).
$staleModule = "$HOME/.local/share/powershell/Modules/do-linux"
if (Test-Path $staleModule -PathType Container) {
    Write-Host 'removing obsolete do-linux module...'
    Remove-Module -Name 'do-linux' -Force -ErrorAction SilentlyContinue
    Remove-Item $staleModule -Recurse -Force
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

#region wslview shim for MSAL browser auth
# Az/Graph PowerShell (Connect-AzAccount / Connect-MgGraph) start the browser
# auth-code flow by exec'ing the first opener found on PATH from a list hardcoded
# in MSAL.NET (NetCorePlatformProxy.cs GetOpenTool): default order
# xdg-open, gnome-open, kfmclient, microsoft-edge, wslview (broker-configured order
# puts microsoft-edge first). `wslview` is just a PATH binary name to MSAL - NOT a
# wslu dependency (wslu was archived 2025-03), so our shim is unaffected by that.
# On headless Linux (WSL, devcontainers, SSH VMs) none exist, so MSAL falls back to
# device code flow - now blocked by the Entra Conditional Access policy. Filling
# the last-resort wslview slot with a shim makes MSAL print the sign-in URL (like
# `az login`) so it can be CTRL+Clicked, keeping the localhost listener open to
# catch the redirect - no device code. Skip on Windows (WAM) and desktop Linux
# (a real opener already works), and never shadow a real wslview (e.g. wslu).
$shimSource = '.assets/config/bin/wslview'
$wslviewPath = "$HOME/.local/bin/wslview"
# a real opener earlier in MSAL's list means wslview is never reached - skip.
# Must match every entry ahead of wslview in either MSAL order (incl. microsoft-edge).
$hasRealOpener = @('xdg-open', 'gnome-open', 'kfmclient', 'microsoft-edge').Where(
    { Get-Command $_ -CommandType Application -ErrorAction SilentlyContinue }, 'First'
)
# a real wslview elsewhere on PATH (not our shim) must not be shadowed
$realWslview = Get-Command wslview -CommandType Application -ErrorAction SilentlyContinue |
    Where-Object Source -NE $wslviewPath
# "headless" = Linux with no MSAL browser opener of its own - the only case we
# install the shim. On a desktop Linux with a real opener (or a real wslview), the
# environment can do interactive auth on its own, so leave it alone. (Disabling the
# WAM broker is done separately by the orchestrators, after Az is installed.)
$headlessNoOpener = $IsLinux -and -not $hasRealOpener -and -not $realWslview
if ($headlessNoOpener -and (Test-Path $shimSource -PathType Leaf)) {
    # (re)install the shim only when missing or changed
    $installed = (Test-Path $wslviewPath -PathType Leaf) ? [System.IO.File]::ReadAllText($wslviewPath) : ''
    if ($installed -ne [System.IO.File]::ReadAllText($shimSource)) {
        Write-Host 'installing wslview shim for MSAL browser auth...'
        $binDir = [IO.Path]::GetDirectoryName($wslviewPath)
        if (-not (Test-Path $binDir -PathType Container)) {
            New-Item $binDir -ItemType Directory | Out-Null
        }
        & install -m 0755 $shimSource $wslviewPath
    }
}
#endregion

#region $PROFILE.CurrentUserCurrentHost
# load existing profile
$profileContent = [System.Collections.Generic.List[string]]::new()
if (Test-Path $PROFILE.CurrentUserCurrentHost -PathType Leaf) {
    $profileContent.AddRange([System.IO.File]::ReadAllLines($PROFILE.CurrentUserCurrentHost))
}
# track if profile is modified
$isProfileModified = $false

# install kubectl autocompletion
if (Test-Path /usr/bin/kubectl -PathType Leaf) {
    if (-not ($profileContent | Select-String '__kubectlCompleterBlock' -SimpleMatch -Quiet)) {
        Write-Host 'adding kubectl auto-completion...'
        # build completer text
        $profileContent.AddRange(
            [string[]]@(
                "`n#region kubectl completer"
                (/usr/bin/kubectl completion powershell) -join "`n"
                "`n# setup autocompletion for the 'k' alias"
                'Set-Alias -Name k -Value kubectl'
                "Register-ArgumentCompleter -CommandName 'k' -ScriptBlock `${__kubectlCompleterBlock}"
                "`n# setup autocompletion for the 'kubecolor' binary"
                'if (Test-Path /usr/bin/kubecolor -PathType Leaf) {'
                '    Set-Alias -Name kubectl -Value kubecolor'
                "    Register-ArgumentCompleter -CommandName 'kubecolor' -ScriptBlock `${__kubectlCompleterBlock}"
                '}'
                '#endregion'
            )
        )
        $isProfileModified = $true
    }
}

# save profile if modified
if ($isProfileModified) {
    [System.IO.File]::WriteAllText(
        $PROFILE.CurrentUserCurrentHost,
        "$(($profileContent -join "`n").Trim())`n"
    )
}
#endregion

#region $PROFILE.CurrentUserAllHosts
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
    if (-not ($profileContent | Select-String 'UV_SYSTEM_CERTS' -SimpleMatch -Quiet)) {
        Write-Verbose 'adding uv autocompletion...'
        $profileContent.AddRange(
            [string[]]@(
                "`n#region uv"
                '# use system certificates'
                '[System.Environment]::SetEnvironmentVariable("UV_SYSTEM_CERTS", $true)'
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

# set up make completer
$completerFunction = 'Register-MakeCompleter'
if (Get-Command $completerFunction -Module 'do-unix' -CommandType Function -ErrorAction SilentlyContinue) {
    if (-not ($profileContent | Select-String $completerFunction -SimpleMatch -Quiet)) {
        Write-Host 'adding make auto-completion...'
        $profileContent.AddRange(
            [string[]]@(
                "`n#region make completer"
                'Set-Alias -Name m -Value make'
                $completerFunction
                '#endregion'
            )
        )
        $isProfileModified = $true
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

# set up opencode
$openCodePath = '.opencode/bin'
if (Test-Path "$HOME/$openCodePath/opencode" -PathType Leaf) {
    if (-not ($profileContent | Select-String $openCodePath -SimpleMatch -Quiet)) {
        Write-Verbose 'adding opencode path...'
        $profileContent.AddRange(
            [string[]]@(
                "`n#region opencode"
                "if ((Test-Path `"`$HOME/$openCodePath/opencode`" -PathType Leaf) -and `"`$HOME/$openCodePath`" -notin `$env:PATH.Split([IO.Path]::PathSeparator)) {"
                "    [Environment]::SetEnvironmentVariable('PATH', [string]::Join([IO.Path]::PathSeparator, `"`$HOME/$openCodePath`", `$env:PATH))"
                '}'
                '#endregion'
            )
        )
        $isProfileModified = $true
    }
}

# set up devcontainer MSAL loopback fix
if (-not ($profileContent | Select-String 'DOTNET_SYSTEM_NET_DISABLEIPV6' -SimpleMatch -Quiet)) {
    Write-Verbose 'adding devcontainer MSAL loopback fix...'
    $profileContent.AddRange(
        [string[]]@(
            "`n#region devcontainer MSAL loopback fix"
            '# Az/Graph interactive login (MSAL) binds the auth-code redirect listener to'
            '# IPv6 loopback (::1), but VS Code forwards IPv4 (127.0.0.1), so the redirect'
            '# hangs. Force .NET onto IPv4 inside containers so Connect-AzAccount and'
            '# Connect-MgGraph complete. az login is unaffected (it binds 127.0.0.1).'
            'if ($env:REMOTE_CONTAINERS -or $env:CODESPACES) {'
            "    [System.Environment]::SetEnvironmentVariable('DOTNET_SYSTEM_NET_DISABLEIPV6', '1')"
            '}'
            '#endregion'
        )
    )
    $isProfileModified = $true
}

# save profile if modified
if ($isProfileModified) {
    [System.IO.File]::WriteAllText(
        $PROFILE.CurrentUserAllHosts,
        "$(($profileContent -join "`n").Trim())`n"
    )
}
#endregion
