#region common aliases
function cd.. { Set-Location ../ }
function .. { Set-Location ../ }
function ... { Set-Location ../../ }
function .... { Set-Location ../../../ }
function la { Get-ChildItem @args -Force }

Set-Alias -Name c -Value Clear-Host
Set-Alias -Name type -Value Get-Command
#endregion

#region platform aliases
if ($IsLinux) {
    if ($env:DISTRO_FAMILY -eq 'alpine') {
        function bsh { & /usr/bin/env -i ash --noprofile --norc }
        function ls { & /usr/bin/env ls -h --color=auto --group-directories-first @args }
    } else {
        function bsh { & /usr/bin/env -i bash --noprofile --norc }
        function ip { $input | & /usr/bin/env ip --color=auto @args }
        function ls { & /usr/bin/env ls -h --color=auto --group-directories-first --time-style=long-iso @args }
    }
} elseif ($IsMacOS) {
    function bsh { & /usr/bin/env -i bash --noprofile --norc }
}
function grep { $input | & /usr/bin/env grep --ignore-case --color=auto @args }
function less { $input | & /usr/bin/env less -FRXc @args }
function mkdir { & /usr/bin/env mkdir -pv @args }
function mv { & /usr/bin/env mv -iv @args }
function nano { & /usr/bin/env nano -W @args }
function tree { & /usr/bin/env tree -C @args }
function wget { & /usr/bin/env wget -c @args }

Set-Alias -Name rd -Value rmdir
Set-Alias -Name vi -Value vim
#endregion

#region dev tool aliases
$_nb = "$HOME/.nix-profile/bin"

if (Test-Path "$_nb/eza" -PathType Leaf) {
    function eza { & /usr/bin/env eza -g --color=auto --time-style=long-iso --group-directories-first --color-scale=all --git-repos @args }
    function l { eza -1 @args }
    function lsa { eza -a @args }
    function ll { eza -lah @args }
    function lt { eza -Th @args }
    function lta { eza -aTh --git-ignore @args }
    function ltd { eza -DTh @args }
    function ltad { eza -aDTh --git-ignore @args }
    function llt { eza -lTh @args }
    function llta { eza -laTh --git-ignore @args }
} else {
    function l { ls -1 @args }
    function lsa { ls -a @args }
    function ll { ls -lah @args }
}
if (Test-Path "$_nb/rg" -PathType Leaf) {
    function rg { $input | & /usr/bin/env rg --ignore-case @args }
}
if (Test-Path "$_nb/bat" -PathType Leaf) {
    function batp { $input | & /usr/bin/env bat -pP @args }
}
if (Test-Path "$_nb/fastfetch" -PathType Leaf) {
    Set-Alias -Name ff -Value fastfetch
}
if (Test-Path "$_nb/pwsh" -PathType Leaf) {
    function p { & /usr/bin/env pwsh -NoProfileLoadTime @args }
}
if (Test-Path "$_nb/kubectx" -PathType Leaf) {
    Set-Alias -Name kc -Value kubectx
}
if (Test-Path "$_nb/kubens" -PathType Leaf) {
    Set-Alias -Name kn -Value kubens
}
if (Test-Path "$_nb/kubecolor" -PathType Leaf) {
    Set-Alias -Name kubectl -Value kubecolor
}

Remove-Variable _nb
#endregion

#region nix package management wrapper (apt/brew-like UX)
$_nxEnvDir = [IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), '.config/nix-env')
$_nxPkgFile = [IO.Path]::Combine($_nxEnvDir, 'packages.nix')

function _nxReadPkgs {
    if ([IO.File]::Exists($Script:_nxPkgFile)) {
        (Get-Content $Script:_nxPkgFile) | ForEach-Object {
            if ($_ -match '^\s*"([^"]+)"') { $Matches[1] }
        }
    }
}

function _nxWritePkgs {
    param([string[]]$Packages)
    $sorted = $Packages | Where-Object { $_ } | Sort-Object -Unique
    $lines = @('[')
    foreach ($p in $sorted) { $lines += "  `"$p`"" }
    $lines += ']'
    $tmp = [IO.Path]::GetTempFileName()
    [IO.File]::WriteAllLines($tmp, $lines)
    [IO.File]::Move($tmp, $Script:_nxPkgFile, $true)
}

function _nxApply {
    Write-Host "`e[96mapplying changes...`e[0m"
    nix profile upgrade nix-env
    if ($?) {
        Write-Host "`e[32mdone.`e[0m"
    } else {
        Write-Host "`e[31mnix profile upgrade failed`e[0m" -ForegroundColor Red
    }
}

function _nxScopePkgs {
    param([string]$File)
    if ([IO.File]::Exists($File)) {
        (Get-Content $File) | ForEach-Object {
            if ($_ -match '^\s*([a-zA-Z][a-zA-Z0-9_-]*)') {
                $name = $Matches[1]
                if ($name -notin 'pkgs', 'with') { $name }
            }
        }
    }
}

function _nxValidatePkg {
    param([string]$Name)
    $null = nix eval "nixpkgs#$Name.name" 2>$null
    return $LASTEXITCODE -eq 0
}

function _nxScopeFileAdd {
    param([string]$File, [string[]]$Packages)
    $existing = @(_nxScopePkgs $File)
    $added = $false
    foreach ($p in $Packages) {
        if ($p -in $existing) {
            Write-Host "`e[33m$p is already in scope`e[0m"
        } else {
            $existing += $p
            Write-Host "`e[32madded $p`e[0m"
            $added = $true
        }
    }
    if (-not $added) { return $false }
    $sorted = $existing | Sort-Object -Unique
    $lines = @('{ pkgs }: with pkgs; [')
    foreach ($p in $sorted) { $lines += "  $p" }
    $lines += ']'
    [IO.File]::WriteAllLines($File, $lines)
    return $true
}

function _nxScopes {
    $configNix = [IO.Path]::Combine($Script:_nxEnvDir, 'config.nix')
    if ([IO.File]::Exists($configNix)) {
        $inScopes = $false
        foreach ($line in (Get-Content $configNix)) {
            if ($line -match 'scopes\s*=\s*\[') { $inScopes = $true; continue }
            if ($inScopes -and $line -match '\]') { break }
            if ($inScopes -and $line -match '^\s*"([^"]+)"') { $Matches[1] }
        }
    }
}

function _nxIsInit {
    $configNix = [IO.Path]::Combine($Script:_nxEnvDir, 'config.nix')
    if ([IO.File]::Exists($configNix)) {
        foreach ($line in (Get-Content $configNix)) {
            if ($line -match '\bisInit\s*=\s*(true|false)') { return $Matches[1] }
        }
    }
    'false'
}

function _nxAllScopePkgMap {
    $scopesDir = [IO.Path]::Combine($Script:_nxEnvDir, 'scopes')
    $map = @{}
    if (-not (Test-Path $scopesDir -PathType Container)) { return $map }
    $baseFile = [IO.Path]::Combine($scopesDir, 'base.nix')
    foreach ($p in @(_nxScopePkgs $baseFile)) { $map[$p] = 'base' }
    if ((_nxIsInit) -eq 'true') {
        $initFile = [IO.Path]::Combine($scopesDir, 'base_init.nix')
        foreach ($p in @(_nxScopePkgs $initFile)) { $map[$p] = 'base_init' }
    }
    foreach ($s in @(_nxScopes)) {
        $scopeFile = [IO.Path]::Combine($scopesDir, "$s.nix")
        foreach ($p in @(_nxScopePkgs $scopeFile)) { $map[$p] = $s }
    }
    return $map
}

function nx {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Command,

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Xargs
    )

    $Xargs = @($Xargs | ForEach-Object { $_ -split '[,\s]+' } | Where-Object { $_ })
    $envDir = $Script:_nxEnvDir
    $scopesDir = [IO.Path]::Combine($envDir, 'scopes')

    switch ($Command) {
        'search' {
            if (-not $Xargs) { Write-Host 'Usage: nx search <query>' -ForegroundColor Yellow; return }
            nix search nixpkgs @Xargs
        }
        { $_ -in 'install', 'add' } {
            if (-not $Xargs) { Write-Host 'Usage: nx install <pkg> [pkg...]' -ForegroundColor Yellow; return }
            # validate packages exist in nixpkgs
            $validated = [System.Collections.Generic.List[string]]::new()
            foreach ($p in $Xargs) {
                Write-Host "`e[90mvalidating $p...`e[0m" -NoNewline
                if (_nxValidatePkg $p) {
                    Write-Host "`r" -NoNewline
                    $validated.Add($p)
                } else {
                    Write-Host "`r`e[31m$p not found in nixpkgs`e[0m"
                }
            }
            if ($validated.Count -eq 0) { return }
            # build scope package lookup
            $scopePkgMap = _nxAllScopePkgMap
            $current = @(_nxReadPkgs)
            $added = $false
            $newList = [System.Collections.Generic.List[string]]::new()
            if ($current.Count -gt 0) { $newList.AddRange([string[]]$current) }
            foreach ($p in $validated) {
                if ($scopePkgMap.ContainsKey($p)) {
                    Write-Host "`e[33m$p is already installed in scope '$($scopePkgMap[$p])'`e[0m"
                } elseif ($p -in $current) {
                    Write-Host "`e[33m$p is already installed (extra)`e[0m"
                } else {
                    $newList.Add($p)
                    Write-Host "`e[32madded $p`e[0m"
                    $added = $true
                }
            }
            _nxWritePkgs -Packages $newList.ToArray()
            if ($added) { _nxApply }
        }
        { $_ -in 'remove', 'uninstall' } {
            if (-not $Xargs) { Write-Host 'Usage: nx remove <pkg> [pkg...]' -ForegroundColor Yellow; return }
            # check for scope-managed packages first
            $scopePkgMap = _nxAllScopePkgMap
            $filteredArgs = [System.Collections.Generic.List[string]]::new()
            foreach ($p in $Xargs) {
                if ($scopePkgMap.ContainsKey($p)) {
                    Write-Host "`e[33m$p is managed by scope '$($scopePkgMap[$p])' - use: nx scope remove $($scopePkgMap[$p])`e[0m"
                } else {
                    $filteredArgs.Add($p)
                }
            }
            if ($filteredArgs.Count -eq 0) { return }
            $current = @(_nxReadPkgs)
            if ($current.Count -eq 0) {
                Write-Host "`e[33mNo user packages installed.`e[0m"
                return
            }
            $removed = $false
            $remaining = [System.Collections.Generic.List[string]]::new()
            foreach ($p in $current) {
                if ($p -in $filteredArgs) {
                    Write-Host "`e[32mremoved $p`e[0m"
                    $removed = $true
                } else {
                    $remaining.Add($p)
                }
            }
            foreach ($p in $filteredArgs) {
                if ($p -notin $current) {
                    Write-Host "`e[33m$p is not installed - skipping`e[0m"
                }
            }
            _nxWritePkgs -Packages $remaining.ToArray()
            if ($removed) { _nxApply }
        }
        { $_ -in 'upgrade', 'update' } {
            Write-Host "`e[96mupgrading packages...`e[0m"
            $pinFile = Join-Path $envDir 'pinned_rev'
            $pinnedRev = if (Test-Path $pinFile) { (Get-Content $pinFile -Raw).Trim() } else { '' }
            if ($pinnedRev) {
                Write-Host "`e[96mpinning nixpkgs to $pinnedRev`e[0m"
                nix flake lock --override-input nixpkgs "github:nixos/nixpkgs/$pinnedRev" --flake $envDir 2>$null
            } else {
                nix flake update --flake $envDir 2>$null
            }
            nix profile upgrade nix-env
            if ($?) {
                Write-Host "`e[32mdone.`e[0m"
            } else {
                Write-Host "`e[31mnix profile upgrade failed`e[0m" -ForegroundColor Red
            }
        }
        { $_ -in 'list', 'ls' } {
            $allPkgs = [System.Collections.Generic.List[object]]::new()
            # base packages
            $baseFile = [IO.Path]::Combine($scopesDir, 'base.nix')
            foreach ($p in @(_nxScopePkgs $baseFile)) {
                $allPkgs.Add([PSCustomObject]@{ Name = $p; Scope = 'base' })
            }
            # base_init packages
            if ((_nxIsInit) -eq 'true') {
                $initFile = [IO.Path]::Combine($scopesDir, 'base_init.nix')
                foreach ($p in @(_nxScopePkgs $initFile)) {
                    $allPkgs.Add([PSCustomObject]@{ Name = $p; Scope = 'base_init' })
                }
            }
            # configured scopes
            foreach ($s in @(_nxScopes)) {
                $scopeFile = [IO.Path]::Combine($scopesDir, "$s.nix")
                foreach ($p in @(_nxScopePkgs $scopeFile)) {
                    $allPkgs.Add([PSCustomObject]@{ Name = $p; Scope = $s })
                }
            }
            # user packages (extra)
            foreach ($p in @(_nxReadPkgs)) {
                $allPkgs.Add([PSCustomObject]@{ Name = $p; Scope = 'extra' })
            }
            if ($allPkgs.Count -gt 0) {
                $allPkgs | Sort-Object Name -Unique | ForEach-Object {
                    Write-Host ("  `e[1m*`e[0m {0,-24} `e[90m({1})`e[0m" -f $_.Name, $_.Scope)
                }
            } else {
                Write-Host "`e[33mNo packages installed.`e[0m Use `e[1mnx install <pkg>`e[0m or run `e[1mnix/setup.sh`e[0m."
            }
        }
        'scope' {
            $configNix = [IO.Path]::Combine($envDir, 'config.nix')
            $subCmd = if ($Xargs.Count -gt 0) { $Xargs[0] } else { 'help' }
            [string[]]$subArgs = if ($Xargs.Count -gt 1) { $Xargs[1..($Xargs.Count - 1)] } else { @() }

            switch ($subCmd) {
                { $_ -in 'list', 'ls' } {
                    $scopes = @(_nxScopes)
                    if ($scopes.Count -gt 0) {
                        Write-Host "`e[96mInstalled scopes:`e[0m"
                        $scopes | ForEach-Object { Write-Host "  `e[1m*`e[0m $_" }
                    } else {
                        Write-Host "`e[33mNo scopes configured.`e[0m Run `e[1mnix/setup.sh`e[0m to initialize."
                    }
                }
                'show' {
                    if (-not $subArgs) { Write-Host 'Usage: nx scope show <scope>' -ForegroundColor Yellow; return }
                    $scopeFile = [IO.Path]::Combine($scopesDir, "$($subArgs[0]).nix")
                    if (-not [IO.File]::Exists($scopeFile)) {
                        Write-Host "`e[31mScope '$($subArgs[0])' not found.`e[0m" -ForegroundColor Red
                        return
                    }
                    Write-Host "`e[96m$($subArgs[0]):`e[0m"
                    foreach ($p in @(_nxScopePkgs $scopeFile)) {
                        Write-Host "  `e[1m*`e[0m $p"
                    }
                }
                'tree' {
                    # base is always present
                    $baseFile = [IO.Path]::Combine($scopesDir, 'base.nix')
                    if ([IO.File]::Exists($baseFile)) {
                        Write-Host "`e[96mbase:`e[0m"
                        foreach ($p in @(_nxScopePkgs $baseFile)) {
                            Write-Host "  `e[1m*`e[0m $p"
                        }
                    }
                    foreach ($s in @(_nxScopes)) {
                        Write-Host "`e[96m${s}:`e[0m"
                        $scopeFile = [IO.Path]::Combine($scopesDir, "$s.nix")
                        foreach ($p in @(_nxScopePkgs $scopeFile)) {
                            Write-Host "  `e[1m*`e[0m $p"
                        }
                    }
                    $userPkgs = @(_nxReadPkgs)
                    if ($userPkgs.Count -gt 0) {
                        Write-Host "`e[96mextra:`e[0m"
                        $userPkgs | ForEach-Object { Write-Host "  `e[1m*`e[0m $_" }
                    }
                }
                { $_ -in 'remove', 'rm' } {
                    if (-not $subArgs) { Write-Host 'Usage: nx scope remove <scope> [scope...]' -ForegroundColor Yellow; return }
                    if (-not [IO.File]::Exists($configNix)) {
                        Write-Host "`e[31mNo nix-env config found. Run nix/setup.sh to initialize.`e[0m" -ForegroundColor Red
                        return
                    }
                    $currentScopes = @(_nxScopes)
                    $isInit = _nxIsInit
                    if ($currentScopes.Count -eq 0) {
                        Write-Host "`e[33mNo scopes configured - nothing to remove.`e[0m"
                        return
                    }
                    $ovDir = if ($env:NIX_ENV_OVERLAY_DIR -and (Test-Path $env:NIX_ENV_OVERLAY_DIR -PathType Container)) {
                        $env:NIX_ENV_OVERLAY_DIR
                    } else {
                        [IO.Path]::Combine($envDir, 'local')
                    }
                    $removeSet = [System.Collections.Generic.HashSet[string]]::new()
                    foreach ($r in $subArgs) { $removeSet.Add($r) | Out-Null; $removeSet.Add("local_$r") | Out-Null }
                    $scopeList = [System.Collections.Generic.List[string]]::new()
                    $removed = $false
                    foreach ($s in $currentScopes) {
                        if ($removeSet.Contains($s)) {
                            $displayName = $s -replace '^local_', ''
                            Write-Host "`e[32mremoved scope: $displayName`e[0m"
                            $removed = $true
                        } else {
                            $scopeList.Add($s)
                        }
                    }
                    foreach ($r in $subArgs) {
                        $overlayFile = [IO.Path]::Combine($ovDir, 'scopes', "$r.nix")
                        $installedFile = [IO.Path]::Combine($scopesDir, "local_$r.nix")
                        if (Test-Path $overlayFile) { Remove-Item $overlayFile }
                        if (Test-Path $installedFile) { Remove-Item $installedFile }
                        if ($r -notin $currentScopes -and "local_$r" -notin $currentScopes) {
                            Write-Host "`e[33mscope '$r' is not configured - skipping`e[0m"
                        }
                    }
                    if (-not $removed) { return }
                    # rewrite config.nix
                    $nixScopes = ($scopeList | ForEach-Object { "    `"$_`"" }) -join "`n"
                    if ($nixScopes) { $nixScopes = "`n$nixScopes`n" } else { $nixScopes = "`n" }
                    $content = "# Generated by nx scope remove - re-run nix/setup.sh to reconfigure.`n{`n  isInit = $($isInit ?? 'false');`n`n  scopes = [$nixScopes  ];`n}`n"
                    $tmp = [IO.Path]::GetTempFileName()
                    [IO.File]::WriteAllText($tmp, $content)
                    [IO.File]::Move($tmp, $configNix, $true)
                    _nxApply
                    Write-Host "Restart your shell to apply changes."
                }
                'add' {
                    if (-not $subArgs) { Write-Host 'Usage: nx scope add <name> [pkg...]' -ForegroundColor Yellow; return }
                    $name = $subArgs[0] -replace '-', '_'
                    $pkgs = if ($subArgs.Count -gt 1) { $subArgs[1..($subArgs.Count - 1)] } else { @() }
                    $ovDir = if ($env:NIX_ENV_OVERLAY_DIR -and (Test-Path $env:NIX_ENV_OVERLAY_DIR -PathType Container)) {
                        $env:NIX_ENV_OVERLAY_DIR
                    } else {
                        [IO.Path]::Combine($envDir, 'local')
                    }
                    $scopeFile = [IO.Path]::Combine($ovDir, 'scopes', "$name.nix")
                    $created = $false
                    if (-not [IO.File]::Exists($scopeFile)) {
                        $null = New-Item -ItemType Directory -Path ([IO.Path]::Combine($ovDir, 'scopes')) -Force
                        $null = New-Item -ItemType Directory -Path $scopesDir -Force
                        [IO.File]::WriteAllText($scopeFile, "{ pkgs }: with pkgs; []`n")
                        Copy-Item $scopeFile ([IO.Path]::Combine($scopesDir, "local_$name.nix"))
                        if ([IO.File]::Exists($configNix)) {
                            $currentScopes = @(_nxScopes)
                            if ("local_$name" -notin $currentScopes) {
                                $isInit = _nxIsInit
                                $allScopes = $currentScopes + "local_$name"
                                $nixScopes = ($allScopes | ForEach-Object { "    `"$_`"" }) -join "`n"
                                if ($nixScopes) { $nixScopes = "`n$nixScopes`n" } else { $nixScopes = "`n" }
                                $content = "# Generated by nx scope add - re-run nix/setup.sh to reconfigure.`n{`n  isInit = $($isInit ?? 'false');`n`n  scopes = [$nixScopes  ];`n}`n"
                                $tmp = [IO.Path]::GetTempFileName()
                                [IO.File]::WriteAllText($tmp, $content)
                                [IO.File]::Move($tmp, $configNix, $true)
                            }
                        }
                        $created = $true
                        Write-Host "`e[32mCreated scope '$name' at $scopeFile`e[0m"
                    }
                    if ($pkgs.Count -gt 0) {
                        $validated = [System.Collections.Generic.List[string]]::new()
                        foreach ($p in $pkgs) {
                            Write-Host "`e[90mvalidating $p...`e[0m" -NoNewline
                            if (_nxValidatePkg $p) {
                                Write-Host "`r" -NoNewline
                                $validated.Add($p)
                            } else {
                                Write-Host "`r`e[31m$p not found in nixpkgs`e[0m"
                            }
                        }
                        if ($validated.Count -gt 0) {
                            if (_nxScopeFileAdd -File $scopeFile -Packages $validated.ToArray()) {
                                Copy-Item $scopeFile ([IO.Path]::Combine($scopesDir, "local_$name.nix"))
                                _nxApply
                            }
                        }
                    } elseif ($created) {
                        Write-Host "Add packages: `e[1mnx scope add $name <pkg> [pkg...]`e[0m"
                    } else {
                        Write-Host "`e[33mScope '$name' already exists.`e[0m Add packages: nx scope add $name <pkg>"
                    }
                }
                'edit' {
                    if (-not $subArgs) { Write-Host 'Usage: nx scope edit <name>' -ForegroundColor Yellow; return }
                    $name = $subArgs[0] -replace '-', '_'
                    $ovDir = if ($env:NIX_ENV_OVERLAY_DIR -and (Test-Path $env:NIX_ENV_OVERLAY_DIR -PathType Container)) {
                        $env:NIX_ENV_OVERLAY_DIR
                    } else {
                        [IO.Path]::Combine($envDir, 'local')
                    }
                    $scopeFile = [IO.Path]::Combine($ovDir, 'scopes', "$name.nix")
                    if (-not [IO.File]::Exists($scopeFile)) {
                        Write-Host "`e[31mScope '$name' not found.`e[0m Create it first: nx scope add $name"
                        return
                    }
                    $editor = if ($env:EDITOR) { $env:EDITOR } else { 'vi' }
                    & $editor $scopeFile
                    Copy-Item $scopeFile ([IO.Path]::Combine($scopesDir, "local_$name.nix"))
                    Write-Host "`e[32mSynced scope '$name'.`e[0m Run `e[1mnx upgrade`e[0m to apply."
                }
                default {
                    Write-Host @'
Usage: nx scope <command> [args]

Commands:
  list                      List enabled scopes
  show <scope>              Show packages in a scope
  tree                      Show all scopes with their packages
  add <name> [pkg...]       Create a scope or add packages to it
  edit <name>               Open a scope file in $EDITOR
  remove <scope> [scope...] Remove one or more scopes
'@
                }
            }
        }
        'overlay' {
            $subCmd = if ($Xargs.Count -gt 0) { $Xargs[0] } else { 'list' }
            $ovDir = if ($env:NIX_ENV_OVERLAY_DIR -and (Test-Path $env:NIX_ENV_OVERLAY_DIR -PathType Container)) {
                $env:NIX_ENV_OVERLAY_DIR
            } elseif (Test-Path ([IO.Path]::Combine($envDir, 'local')) -PathType Container) {
                [IO.Path]::Combine($envDir, 'local')
            } else {
                $null
            }

            switch ($subCmd) {
                { $_ -in 'list', 'ls' } {
                    if (-not $ovDir) {
                        Write-Host "`e[33mNo overlay directory active.`e[0m"
                        Write-Host "Create one at $envDir/local/ or set NIX_ENV_OVERLAY_DIR."
                        return
                    }
                    Write-Host "`e[96mOverlay directory:`e[0m $ovDir"
                    $scDir = [IO.Path]::Combine($ovDir, 'scopes')
                    if (Test-Path $scDir -PathType Container) {
                        $nixFiles = Get-ChildItem "$scDir/*.nix" -ErrorAction SilentlyContinue
                        if ($nixFiles) {
                            Write-Host "`e[96mScopes:`e[0m"
                            $nixFiles | ForEach-Object { Write-Host "  `e[1m*`e[0m $($_.BaseName)" }
                        }
                    }
                    $cfgDir = [IO.Path]::Combine($ovDir, 'bash_cfg')
                    if (Test-Path $cfgDir -PathType Container) {
                        $shFiles = Get-ChildItem "$cfgDir/*.sh" -ErrorAction SilentlyContinue
                        if ($shFiles) {
                            Write-Host "`e[96mShell config:`e[0m"
                            $shFiles | ForEach-Object { Write-Host "  `e[1m*`e[0m $($_.Name)" }
                        }
                    }
                    foreach ($hookDir in 'pre-setup.d', 'post-setup.d') {
                        $hPath = [IO.Path]::Combine($ovDir, 'hooks', $hookDir)
                        if (Test-Path $hPath -PathType Container) {
                            $hooks = Get-ChildItem "$hPath/*.sh" -ErrorAction SilentlyContinue
                            if ($hooks) {
                                Write-Host "`e[96mHooks ($hookDir):`e[0m"
                                $hooks | ForEach-Object { Write-Host "  `e[1m*`e[0m $($_.Name)" }
                            }
                        }
                    }
                }
                'status' {
                    Write-Host -NoNewline "`e[96mOverlay:`e[0m "
                    if ($ovDir) {
                        Write-Host $ovDir
                    } else {
                        Write-Host "`e[33mnone`e[0m"
                    }
                    $hasLocal = $false
                    if (Test-Path $scopesDir -PathType Container) {
                        $localFiles = Get-ChildItem "$scopesDir/local_*.nix" -ErrorAction SilentlyContinue
                        if ($localFiles) {
                            Write-Host "`e[96mOverlay scopes (synced):`e[0m"
                            foreach ($f in $localFiles) {
                                $name = $f.BaseName -replace '^local_', ''
                                $indicator = ''
                                if ($ovDir) {
                                    $srcFile = [IO.Path]::Combine($ovDir, 'scopes', "$name.nix")
                                    if ([IO.File]::Exists($srcFile)) {
                                        if ((Get-FileHash $srcFile).Hash -ne (Get-FileHash $f.FullName).Hash) {
                                            $indicator = " `e[33m(modified)`e[0m"
                                        }
                                    } else {
                                        $indicator = " `e[33m(source missing)`e[0m"
                                    }
                                } else {
                                    $indicator = " `e[33m(source missing)`e[0m"
                                }
                                Write-Host "  `e[1m*`e[0m $name$indicator"
                            }
                            $hasLocal = $true
                        }
                    }
                    if (-not $hasLocal) {
                        Write-Host "`e[90mNo overlay scopes synced.`e[0m"
                    }
                    if ($ovDir) {
                        $cfgDir = [IO.Path]::Combine($ovDir, 'bash_cfg')
                        if (Test-Path $cfgDir -PathType Container) {
                            $shFiles = Get-ChildItem "$cfgDir/*.sh" -ErrorAction SilentlyContinue
                            if ($shFiles) {
                                Write-Host "`e[96mOverlay shell config:`e[0m"
                                foreach ($f in $shFiles) {
                                    $installed = [IO.Path]::Combine($env:HOME, '.config', 'bash', $f.Name)
                                    $indicator = ''
                                    if ([IO.File]::Exists($installed)) {
                                        if ((Get-FileHash $f.FullName).Hash -eq (Get-FileHash $installed).Hash) {
                                            $indicator = " `e[32m(synced)`e[0m"
                                        } else {
                                            $indicator = " `e[33m(differs)`e[0m"
                                        }
                                    } else {
                                        $indicator = " `e[33m(not installed)`e[0m"
                                    }
                                    Write-Host "  `e[1m*`e[0m $($f.Name)$indicator"
                                }
                            }
                        }
                    }
                }
                default {
                    Write-Host @'
Usage: nx overlay <command>

Commands:
  list      Show active overlay directory and contents
  status    Show sync status of overlay files
  help      Show this help
'@
                }
            }
        }
        { $_ -in 'prune' } {
            # remove stale imperative profile entries (anything not 'nix-env')
            try {
                $profileJson = nix profile list --json 2>$null | ConvertFrom-Json
            } catch {
                Write-Host "`e[31mFailed to list nix profile.`e[0m" -NoNewline
                return
            }
            $staleNames = [System.Collections.Generic.List[string]]::new()
            foreach ($prop in $profileJson.elements.PSObject.Properties) {
                if ($prop.Name -ne 'nix-env') {
                    $staleNames.Add($prop.Name)
                }
            }
            if ($staleNames.Count -eq 0) {
                Write-Host "`e[32mNo stale profile entries found.`e[0m"
                return
            }
            Write-Host "`e[96mStale profile entries:`e[0m"
            foreach ($name in $staleNames) {
                Write-Host "  `e[1m*`e[0m $name"
            }
            Write-Host "`e[96mRemoving...`e[0m"
            foreach ($name in $staleNames) {
                nix profile remove $name
                Write-Host "`e[32mremoved $name`e[0m"
            }
            Write-Host "`e[32mdone.`e[0m Run `e[1mnx gc`e[0m to free disk space."
        }
        { $_ -in 'gc', 'clean' } {
            nix profile wipe-history
            nix store gc
        }
        'rollback' {
            nix profile rollback
            if ($?) {
                Write-Host "`e[32mRolled back to previous profile generation.`e[0m"
                Write-Host "Restart your shell to apply changes."
            } else {
                Write-Host "`e[31mnix profile rollback failed`e[0m" -ForegroundColor Red
            }
        }
        'pin' {
            $pinFile = Join-Path $envDir 'pinned_rev'
            $sub = if ($Xargs.Count -gt 0) { $Xargs[0] } else { 'show' }
            switch ($sub) {
                'set' {
                    $rev = if ($Xargs.Count -ge 2) { $Xargs[1] } else { '' }
                    if (-not $rev) {
                        $lockFile = Join-Path $envDir 'flake.lock'
                        if (-not (Test-Path $lockFile)) {
                            Write-Host "`e[31mNo flake.lock found - run nx upgrade first.`e[0m"
                            return
                        }
                        $lock = Get-Content $lockFile -Raw | ConvertFrom-Json
                        $rev = $lock.nodes.nixpkgs.locked.rev
                        if (-not $rev) {
                            Write-Host "`e[31mCould not read nixpkgs revision from flake.lock.`e[0m"
                            return
                        }
                    }
                    [IO.File]::WriteAllText($pinFile, "$rev`n")
                    Write-Host "`e[32mPinned nixpkgs to $rev`e[0m"
                }
                { $_ -in 'remove', 'rm' } {
                    if (Test-Path $pinFile) {
                        Remove-Item $pinFile
                        Write-Host "`e[32mPin removed.`e[0m Upgrades will use latest nixpkgs-unstable."
                    } else {
                        Write-Host "`e[90mNo pin set.`e[0m"
                    }
                }
                'show' {
                    if (Test-Path $pinFile) {
                        $rev = (Get-Content $pinFile -Raw).Trim()
                        Write-Host "`e[96mPinned to:`e[0m $rev"
                    } else {
                        Write-Host "`e[90mNo pin set.`e[0m Upgrades use latest nixpkgs-unstable."
                    }
                }
                default {
                    Write-Host @'
Usage: nx pin <command>

Commands:
  set [rev]   Pin nixpkgs to a commit SHA (default: current flake.lock rev)
  remove      Remove the pin (use latest nixpkgs-unstable)
  show        Show current pin status (default)
  help        Show this help

The pin takes effect on the next `nx upgrade` or `nix/setup.sh --upgrade`.
'@
                }
            }
        }
        'doctor' {
            $doctorScript = Join-Path $env:HOME '.config/nix-env/nx_doctor.sh'
            if (Test-Path $doctorScript) {
                & bash $doctorScript @Xargs
            } else {
                Write-Host "`e[31mnx doctor not found`e[0m"
            }
        }
        'version' {
            devenv
        }
        default {
            Write-Host @'
Usage: nx <command> [args]

Commands:
  search  <query>         Search for packages in nixpkgs
  install <pkg> [pkg...]  Install packages (declarative, via packages.nix)
  remove  <pkg> [pkg...]  Remove user-installed packages
  upgrade                 Upgrade all packages to latest nixpkgs
  rollback                Roll back to previous profile generation
  pin                     Pin nixpkgs to a specific revision (nx pin help)
  list                    List all installed packages with scope annotations
  scope                   Manage scopes (nx scope help)
  overlay                 Manage overlay directory (nx overlay help)
  doctor                  Run health checks on the nix-env environment
  prune                   Remove stale imperative profile entries
  gc                      Garbage collect old versions and free disk space
  version                 Show installation provenance and version info
  help                    Show this help
'@
        }
    }
}

Register-ArgumentCompleter -CommandName nx -Native -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $tokens = $commandAst.CommandElements
    $pos = $tokens.Count
    if ($wordToComplete) { $pos-- }

    $completions = switch ($pos) {
        1 { 'search', 'install', 'remove', 'upgrade', 'rollback', 'pin', 'list', 'scope', 'overlay', 'doctor', 'prune', 'gc', 'version', 'help' }
        2 {
            if ($tokens[1].Value -eq 'scope') { 'list', 'show', 'tree', 'add', 'edit', 'remove' }
            elseif ($tokens[1].Value -eq 'overlay') { 'list', 'status', 'help' }
            elseif ($tokens[1].Value -eq 'pin') { 'set', 'remove', 'show', 'help' }
        }
    }
    $completions | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
#endregion
