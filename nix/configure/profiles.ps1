#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Setting up PowerShell profile for Nix package manager.

.EXAMPLE
nix/configure/profiles.ps1
#>
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'Ignore'

# resolve paths
$scriptRoot = $PSScriptRoot
$repoRoot = (Resolve-Path "$scriptRoot/../..").Path
$pwshCfg = [IO.Path]::Combine($repoRoot, '.assets/config/pwsh_cfg')

# -- nix aliases (nx wrapper) ------------------------------------------------
$nixAliasesSrc = [IO.Path]::Combine($pwshCfg, '_aliases_nix.ps1')
$userScriptsPath = [IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), '.config/powershell/Scripts')
$nixAliasesDst = [IO.Path]::Combine($userScriptsPath, '_aliases_nix.ps1')

if ([IO.File]::Exists($nixAliasesSrc)) {
    $needsCopy = -not [IO.File]::Exists($nixAliasesDst) -or
        [IO.File]::ReadAllText($nixAliasesSrc) -ne [IO.File]::ReadAllText($nixAliasesDst)
    if ($needsCopy) {
        if (-not [IO.Directory]::Exists($userScriptsPath)) {
            [IO.Directory]::CreateDirectory($userScriptsPath) | Out-Null
        }
        [IO.File]::Copy($nixAliasesSrc, $nixAliasesDst, $true)
        Write-Host "`e[32minstalled nix aliases for PowerShell`e[0m"
    }
}

# -- nix PATH in PowerShell profile ------------------------------------------
$profilePath = $PROFILE.CurrentUserAllHosts
$profileContent = [System.Collections.Generic.List[string]]::new()
if ([IO.File]::Exists($profilePath)) {
    $profileContent.AddRange([IO.File]::ReadAllLines($profilePath))
}

# add nix paths to PATH (daemon bin + user profile bin)
$nixRegion = [string[]]@(
    '#region nix'
    'foreach ($nixPath in @(''/nix/var/nix/profiles/default/bin'', [IO.Path]::Combine([Environment]::GetFolderPath(''UserProfile''), ''.nix-profile/bin''))) {'
    '    if ([IO.Directory]::Exists($nixPath) -and $nixPath -notin $env:PATH.Split([IO.Path]::PathSeparator)) {'
    '        [Environment]::SetEnvironmentVariable(''PATH'', [string]::Join([IO.Path]::PathSeparator, $nixPath, $env:PATH))'
    '    }'
    '}'
    '#endregion'
)

# remove existing nix region if present, then add the current version
$startIdx = ($profileContent | Select-String '#region nix' -SimpleMatch).LineNumber
if ($startIdx) {
    $endIdx = ($profileContent | Select-String '#endregion' -SimpleMatch | Where-Object LineNumber -GE $startIdx | Select-Object -First 1).LineNumber
    if ($endIdx) {
        # check if existing region matches
        $existingRegion = $profileContent[($startIdx - 1)..($endIdx - 1)] -join "`n"
        if ($existingRegion -eq ($nixRegion -join "`n")) {
            return
        }
        # remove blank line before region if present
        $removeFrom = $startIdx - 1
        while ($removeFrom -gt 0 -and [string]::IsNullOrWhiteSpace($profileContent[$removeFrom - 1])) { $removeFrom-- }
        $profileContent.RemoveRange($removeFrom, $endIdx - $removeFrom)
    }
}
Write-Host "`e[32madding nix to PATH...`e[0m"
$profileContent.Add('')
$profileContent.AddRange($nixRegion)

# save profile
[IO.File]::WriteAllText(
    $profilePath,
    "$(($profileContent -join "`n").Trim())`n"
)
