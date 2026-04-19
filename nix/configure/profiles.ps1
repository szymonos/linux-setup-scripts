#!/usr/bin/env pwsh
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

# ============================================================================
# Helpers
# ============================================================================

# Upsert a #region block into a List[string] of profile lines.
# Replaces existing region content if present and outdated, inserts if absent.
# Returns $true if a change was made.
function Update-ProfileRegion {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$RegionName,
        [string[]]$Content
    )
    $startTag = "#region $RegionName"
    $endTag = '#endregion'
    $startIdx = ($Lines | Select-String $startTag -SimpleMatch).LineNumber
    if ($startIdx) {
        $endIdx = ($Lines | Select-String $endTag -SimpleMatch |
            Where-Object LineNumber -GE $startIdx | Select-Object -First 1).LineNumber
        if ($endIdx) {
            $existing = $Lines[($startIdx - 1)..($endIdx - 1)] -join "`n"
            if ($existing -eq ($Content -join "`n")) {
                return $false
            }
            $removeFrom = $startIdx - 1
            while ($removeFrom -gt 0 -and [string]::IsNullOrWhiteSpace($Lines[$removeFrom - 1])) {
                $removeFrom--
            }
            $Lines.RemoveRange($removeFrom, $endIdx - $removeFrom)
            $Lines.Add('')
            $Lines.AddRange([string[]]$Content)
            return $true
        }
    }
    $Lines.Add('')
    $Lines.AddRange([string[]]$Content)
    return $true
}

# Remove a #region block by exact name. Returns $true if found and removed.
function Remove-ProfileRegion {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$RegionName
    )
    $startTag = "#region $RegionName"
    $endTag = '#endregion'
    $startIdx = $null
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].TrimEnd() -eq $startTag) { $startIdx = $i; break }
    }
    if ($null -eq $startIdx) { return $false }
    $endIdx = $null
    for ($i = $startIdx + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].TrimEnd() -eq $endTag) { $endIdx = $i; break }
    }
    if ($null -eq $endIdx) { return $false }
    $removeFrom = $startIdx
    while ($removeFrom -gt 0 -and [string]::IsNullOrWhiteSpace($Lines[$removeFrom - 1])) {
        $removeFrom--
    }
    $Lines.RemoveRange($removeFrom, $endIdx - $removeFrom + 1)
    return $true
}

# ============================================================================
# Install user-scope alias files
# ============================================================================
$userScriptsPath = [IO.Path]::Combine(
    [Environment]::GetFolderPath('UserProfile'), '.config/powershell/Scripts')
if (-not [IO.Directory]::Exists($userScriptsPath)) {
    [IO.Directory]::CreateDirectory($userScriptsPath) | Out-Null
}
$aliasFile = '_aliases_nix.ps1'
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

# ============================================================================
# Install base profile to durable config
# ============================================================================
$envDir = [IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), '.config/nix-env')
$baseProfileSrc = [IO.Path]::Combine($pwshCfg, 'profile_nix.ps1')
$baseProfileDst = [IO.Path]::Combine($envDir, 'profile_base.ps1')
if ([IO.File]::Exists($baseProfileSrc)) {
    $needsCopy = -not [IO.File]::Exists($baseProfileDst) -or
        [IO.File]::ReadAllText($baseProfileSrc) -ne [IO.File]::ReadAllText($baseProfileDst)
    if ($needsCopy) {
        [IO.File]::Copy($baseProfileSrc, $baseProfileDst, $true)
        Write-Host "`e[32minstalled base profile for PowerShell`e[0m"
    }
}

# ============================================================================
# Build profile content - CurrentUserAllHosts ($PROFILE.CurrentUserAllHosts)
# ============================================================================
$nixBin = [IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), '.nix-profile/bin')
$profilePath = $PROFILE.CurrentUserAllHosts
$profileContent = [System.Collections.Generic.List[string]]::new()
if ([IO.File]::Exists($profilePath)) {
    $profileContent.AddRange([IO.File]::ReadAllLines($profilePath))
}

# -- Migration: remove old region names (before nix: prefix convention) ------
foreach ($oldRegion in @('base', 'nix', 'oh-my-posh', 'starship', 'uv')) {
    if (Remove-ProfileRegion -Lines $profileContent -RegionName $oldRegion) {
        Write-Host "`e[33mmigrated old region '$oldRegion' from PowerShell profile`e[0m"
    }
}

# -- nix:base - profile dot-source -------------------------------------------
$baseRegion = [string[]]@(
    '#region nix:base'
    "if (Test-Path `"$baseProfileDst`" -PathType Leaf) { . `"$baseProfileDst`" }"
    '#endregion'
)
if (Update-ProfileRegion -Lines $profileContent -RegionName 'nix:base' -Content $baseRegion) {
    Write-Host "`e[32mupdated nix:base in PowerShell profile`e[0m"
}

# -- nix:path - nix PATH -----------------------------------------------------
$nixRegion = [string[]]@(
    '#region nix:path'
    'foreach ($nixPath in @(''/nix/var/nix/profiles/default/bin'', [IO.Path]::Combine([Environment]::GetFolderPath(''UserProfile''), ''.nix-profile/bin''))) {'
    '    if ([IO.Directory]::Exists($nixPath) -and $nixPath -notin $env:PATH.Split([IO.Path]::PathSeparator)) {'
    '        [Environment]::SetEnvironmentVariable(''PATH'', [string]::Join([IO.Path]::PathSeparator, $nixPath, $env:PATH))'
    '    }'
    '}'
    '#endregion'
)
if (Update-ProfileRegion -Lines $profileContent -RegionName 'nix:path' -Content $nixRegion) {
    Write-Host "`e[32mupdated nix:path in PowerShell profile`e[0m"
}

# -- nix:starship - starship prompt ------------------------------------------
$nixBinStarship = [IO.Path]::Combine($nixBin, 'starship')
if ([IO.File]::Exists($nixBinStarship)) {
    $starshipRegion = [string[]]@(
        '#region nix:starship'
        '# starship prompt'
        "if (Test-Path `"$nixBinStarship`" -PathType Leaf) { (& `"$nixBinStarship`" init powershell) | Out-String | Invoke-Expression }"
        '#endregion'
    )
    if (Update-ProfileRegion -Lines $profileContent -RegionName 'nix:starship' -Content $starshipRegion) {
        Write-Host "`e[32mupdated nix:starship in PowerShell profile`e[0m"
    }
}

# -- nix:oh-my-posh - oh-my-posh prompt -------------------------------------
$nixBinOmp = [IO.Path]::Combine($nixBin, 'oh-my-posh')
$ompTheme = [IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), '.config/nix-env/omp/theme.omp.json')
if ([IO.File]::Exists($nixBinOmp) -and [IO.File]::Exists($ompTheme)) {
    $ompRegion = [string[]]@(
        '#region nix:oh-my-posh'
        '# oh-my-posh prompt'
        "if (Test-Path `"$nixBinOmp`" -PathType Leaf) {"
        "    (& `"$nixBinOmp`" init pwsh --config `"$ompTheme`") | Out-String | Invoke-Expression"
        '    [Environment]::SetEnvironmentVariable(''VIRTUAL_ENV_DISABLE_PROMPT'', $true)'
        '}'
        '#endregion'
    )
    if (Update-ProfileRegion -Lines $profileContent -RegionName 'nix:oh-my-posh' -Content $ompRegion) {
        Write-Host "`e[32mupdated nix:oh-my-posh in PowerShell profile`e[0m"
    }
}

# -- nix:uv - uv / uvx completion -------------------------------------------
$nixBinUv = [IO.Path]::Combine($nixBin, 'uv')
if ([IO.File]::Exists($nixBinUv)) {
    $uvRegion = [string[]]@(
        '#region nix:uv'
        "if (Test-Path `"$nixBinUv`" -PathType Leaf) {"
        '    $env:UV_SYSTEM_CERTS = ''true'''
        "    (& `"$nixBinUv`" generate-shell-completion powershell) | Out-String | Invoke-Expression"
        '    (& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression'
        '}'
        '#endregion'
    )
    if (Update-ProfileRegion -Lines $profileContent -RegionName 'nix:uv' -Content $uvRegion) {
        Write-Host "`e[32mupdated nix:uv in PowerShell profile`e[0m"
    }
}

# -- local-path - ~/.local/bin (generic, survives nix uninstall) ------------
$localBin = [IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), '.local/bin')
$localPathRegion = [string[]]@(
    '#region local-path'
    '$localBin = [IO.Path]::Combine([Environment]::GetFolderPath(''UserProfile''), ''.local/bin'')'
    'if ([IO.Directory]::Exists($localBin) -and $localBin -notin $env:PATH.Split([IO.Path]::PathSeparator)) {'
    '    [Environment]::SetEnvironmentVariable(''PATH'', [string]::Join([IO.Path]::PathSeparator, $localBin, $env:PATH))'
    '}'
    '#endregion'
)
if (Update-ProfileRegion -Lines $profileContent -RegionName 'local-path' -Content $localPathRegion) {
    Write-Host "`e[32mupdated local-path in PowerShell profile`e[0m"
}

# save CurrentUserAllHosts profile
[IO.File]::WriteAllText(
    $profilePath,
    "$(($profileContent -join "`n").Trim())`n"
)

# ============================================================================
# kubectl completion - CurrentUserCurrentHost ($PROFILE.CurrentUserCurrentHost)
# ============================================================================
$kubectlBin = [IO.Path]::Combine($nixBin, 'kubectl')
if ([IO.File]::Exists($kubectlBin)) {
    $kubectlProfilePath = $PROFILE.CurrentUserCurrentHost
    $kubectlContent = [System.Collections.Generic.List[string]]::new()
    if ([IO.File]::Exists($kubectlProfilePath)) {
        $kubectlContent.AddRange([IO.File]::ReadAllLines($kubectlProfilePath))
    }
    # migration: remove old region name
    if (Remove-ProfileRegion -Lines $kubectlContent -RegionName 'kubectl completer') {
        Write-Host "`e[33mmigrated old region 'kubectl completer' from PowerShell profile`e[0m"
    }
    $kubectlRegion = [string[]]@(
        '#region nix:kubectl'
        (& $kubectlBin completion powershell) -join "`n"
        ''
        '# setup autocompletion for the k alias'
        'Set-Alias -Name k -Value kubectl'
        "Register-ArgumentCompleter -CommandName 'k' -ScriptBlock `${__kubectlCompleterBlock}"
        ''
        '# setup autocompletion for kubecolor'
        'if (Test-Path "$HOME/.nix-profile/bin/kubecolor" -PathType Leaf) {'
        '    Set-Alias -Name kubectl -Value kubecolor'
        "    Register-ArgumentCompleter -CommandName 'kubecolor' -ScriptBlock `${__kubectlCompleterBlock}"
        '}'
        '#endregion'
    )
    if (Update-ProfileRegion -Lines $kubectlContent -RegionName 'nix:kubectl' -Content $kubectlRegion) {
        Write-Host "`e[32mupdated nix:kubectl in PowerShell profile`e[0m"
        [IO.File]::WriteAllText(
            $kubectlProfilePath,
            "$(($kubectlContent -join "`n").Trim())`n"
        )
    }
}
