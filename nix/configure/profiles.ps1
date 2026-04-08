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

# -- install user-scope alias files ------------------------------------------
$userScriptsPath = [IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), '.config/powershell/Scripts')
if (-not [IO.Directory]::Exists($userScriptsPath)) {
    [IO.Directory]::CreateDirectory($userScriptsPath) | Out-Null
}
foreach ($aliasFile in @('_aliases_nix.ps1', '_aliases_devenv.ps1')) {
    $src = [IO.Path]::Combine($pwshCfg, $aliasFile)
    $dst = [IO.Path]::Combine($userScriptsPath, $aliasFile)
    if ([IO.File]::Exists($src)) {
        $needsCopy = -not [IO.File]::Exists($dst) -or
            [IO.File]::ReadAllText($src) -ne [IO.File]::ReadAllText($dst)
        if ($needsCopy) {
            [IO.File]::Copy($src, $dst, $true)
            Write-Host "`e[32minstalled $aliasFile for PowerShell`e[0m"
        }
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
