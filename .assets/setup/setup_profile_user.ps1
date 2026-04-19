#!/usr/bin/env pwsh
<#
.SYNOPSIS
Setting up PowerShell for the current user.

.PARAMETER UpdateModules
Run update_psresources.ps1 to update all installed modules.

.EXAMPLE
.assets/setup/setup_profile_user.ps1
# :update modules
.assets/setup/setup_profile_user.ps1 -UpdateModules
#>
param (
    [switch]$UpdateModules
)
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
        if (Test-Connection 'aka.ms' -TcpPort 443 -TimeoutSeconds 1) {
            Write-Host 'updating help...'
            Update-Help -UICulture en-US
        }
    }
    # update existing modules
    if ($PSBoundParameters.UpdateModules -and (Test-Path .assets/setup/update_psresources.ps1 -PathType Leaf)) {
        .assets/setup/update_psresources.ps1
    }
}
# install PSReadLine
for ($i = 0; ((Get-Module PSReadLine -ListAvailable).Count -eq 1) -and $i -lt 5; $i++) {
    Write-Host 'installing PSReadLine...'
    Install-PSResource -Name PSReadLine
}

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
    if (Get-Command oh-my-posh -CommandType Application -ErrorAction SilentlyContinue) {
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
if (Get-Command $completerFunction -Module 'do-linux' -CommandType Function -ErrorAction SilentlyContinue) {
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

# set up local-path (~/.local/bin)
$localBin = [IO.Path]::Combine($HOME, '.local', 'bin')
if (-not ($profileContent | Select-String 'local-path' -SimpleMatch -Quiet)) {
    Write-Verbose 'adding local-path to PATH...'
    $profileContent.AddRange([string[]]@(
            "`n#region local-path"
            '$localBin = [IO.Path]::Combine([Environment]::GetFolderPath(''UserProfile''), ''.local/bin'')'
            'if ([IO.Directory]::Exists($localBin) -and $localBin -notin $env:PATH.Split([IO.Path]::PathSeparator)) {'
            '    [Environment]::SetEnvironmentVariable(''PATH'', [string]::Join([IO.Path]::PathSeparator, $localBin, $env:PATH))'
            '}'
            '#endregion'
        )
    )
    $isProfileModified = $true
}

# set up devenv function (install provenance viewer)
if (-not ($profileContent | Select-String 'function devenv' -SimpleMatch -Quiet)) {
    Write-Verbose 'adding devenv function...'
    $profileContent.AddRange([string[]]@(
            "`n#region devenv"
            'function devenv {'
            '    $f = [IO.Path]::Combine([Environment]::GetFolderPath(''UserProfile''), ''.config/dev-env/install.json'')'
            '    if (-not [IO.File]::Exists($f)) { Write-Host "`e[33mNo install record found.`e[0m"; return }'
            '    $r = Get-Content $f -Raw | ConvertFrom-Json'
            '    $ref = if ($r.source_ref) { $r.source_ref.Substring(0, [Math]::Min(12, $r.source_ref.Length)) } else { ''n/a'' }'
            '    $statusStr = if ($r.status -eq ''success'') { "`e[32m$($r.status)`e[0m" } else { "`e[31m$($r.status)`e[0m (phase: $($r.phase))" }'
            '    $prop = [ordered]@{'
            '        Version   = "`e[96m$($r.version)`e[0m"'
            '        Entry     = $r.entry_point'
            '        Source    = "$($r.source) ($ref)"'
            '        Platform  = "$($r.platform)/$($r.arch)"'
            '        Mode      = $r.mode'
            '        Status    = $statusStr'
            '    }'
            '    if ($r.status -ne ''success'' -and $r.error) { $prop[''Error''] = "`e[31m$($r.error)`e[0m" }'
            '    $prop[''Installed''] = $r.installed_at'
            '    if ($r.nix_version) { $prop[''Nix''] = $r.nix_version }'
            '    $prop[''Scopes''] = if ($r.scopes) { $r.scopes -join '', '' } else { '''' }'
            '    return [PSCustomObject]$prop'
            '}'
            '#endregion'
        )
    )
    $isProfileModified = $true
}

# set up custom CA certs environment variables for MITM proxy certificates
$certCustom = [IO.Path]::Combine($HOME, '.config', 'certs', 'ca-custom.crt')
$certBundle = [IO.Path]::Combine($HOME, '.config', 'certs', 'ca-bundle.crt')
if (Test-Path $certCustom -PathType Leaf) {
    if (-not ($profileContent | Select-String 'NODE_EXTRA_CA_CERTS' -SimpleMatch -Quiet)) {
        Write-Verbose 'adding NODE_EXTRA_CA_CERTS env var...'
        $profileContent.AddRange([string[]]@(
                "`n#region certs"
                "if (Test-Path `"$certCustom`" -PathType Leaf) {"
                "    [Environment]::SetEnvironmentVariable('NODE_EXTRA_CA_CERTS', `"$certCustom`")"
                '}'
                '#endregion'
            )
        )
        $isProfileModified = $true
    }
}
if (Test-Path $certBundle -PathType Leaf) {
    if (-not ($profileContent | Select-String 'REQUESTS_CA_BUNDLE' -SimpleMatch -Quiet)) {
        Write-Verbose 'adding REQUESTS_CA_BUNDLE and SSL_CERT_FILE env vars...'
        $profileContent.AddRange([string[]]@(
                "`n#region ca-bundle"
                "if (Test-Path `"$certBundle`" -PathType Leaf) {"
                "    [Environment]::SetEnvironmentVariable('REQUESTS_CA_BUNDLE', `"$certBundle`")"
                "    [Environment]::SetEnvironmentVariable('SSL_CERT_FILE', `"$certBundle`")"
                '}'
                '#endregion'
            )
        )
        $isProfileModified = $true
    }
    if (-not ($profileContent | Select-String 'CLOUDSDK_CORE_CUSTOM_CA_CERTS_FILE' -SimpleMatch -Quiet)) {
        if ((Test-Path /usr/bin/gcloud -PathType Leaf) -or (Test-Path "$HOME/.nix-profile/bin/gcloud" -PathType Leaf)) {
            Write-Verbose 'adding CLOUDSDK_CORE_CUSTOM_CA_CERTS_FILE env var...'
            $profileContent.AddRange([string[]]@(
                    "`n#region gcloud-certs"
                    "if (Test-Path `"$certBundle`" -PathType Leaf) {"
                    "    [Environment]::SetEnvironmentVariable('CLOUDSDK_CORE_CUSTOM_CA_CERTS_FILE', `"$certBundle`")"
                    '}'
                    '#endregion'
                )
            )
            $isProfileModified = $true
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
