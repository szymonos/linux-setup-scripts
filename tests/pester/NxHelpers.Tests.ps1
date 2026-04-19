#Requires -Modules Pester
# Unit tests for nx helper functions in _aliases_nix.ps1
# Tests: _nxReadPkgs, _nxWritePkgs, _nxScopePkgs, _nxScopes, _nxIsInit, _nxAllScopePkgMap

BeforeAll {
    # set up script-scoped variables that the helpers rely on
    $Script:_nxEnvDir = $null
    $Script:_nxPkgFile = $null

    # source only the helper functions by extracting them
    # (the file has side effects at top-level; re-define the helpers inline)
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
}

Describe 'nx helpers' {
    BeforeEach {
        $Script:_nxEnvDir = Join-Path ([IO.Path]::GetTempPath()) "pester-nx-$([guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -Path $Script:_nxEnvDir -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $Script:_nxEnvDir 'scopes') -ItemType Directory -Force | Out-Null
        $Script:_nxPkgFile = Join-Path $Script:_nxEnvDir 'packages.nix'
    }

    AfterEach {
        if (Test-Path $Script:_nxEnvDir) {
            Remove-Item $Script:_nxEnvDir -Recurse -Force
        }
    }

# =============================================================================
# _nxReadPkgs / _nxWritePkgs
# =============================================================================

Context '_nxReadPkgs' {
    It 'returns nothing when file does not exist' {
        $result = @(_nxReadPkgs)
        $result | Should -HaveCount 0
    }

    It 'returns nothing for empty list' {
        Set-Content -Path $Script:_nxPkgFile -Value @('[', ']')
        $result = @(_nxReadPkgs)
        $result | Should -HaveCount 0
    }

    It 'extracts package names' {
        Set-Content -Path $Script:_nxPkgFile -Value @('[', '  "ripgrep"', '  "fd"', '  "jq"', ']')
        $result = @(_nxReadPkgs)
        $result | Should -HaveCount 3
        $result[0] | Should -Be 'ripgrep'
        $result[1] | Should -Be 'fd'
        $result[2] | Should -Be 'jq'
    }

    It 'ignores comments and blank lines' {
        Set-Content -Path $Script:_nxPkgFile -Value @('[', '  # comment', '  "ripgrep"', '', '  "fd"', ']')
        $result = @(_nxReadPkgs)
        $result | Should -HaveCount 2
    }
}

Context '_nxWritePkgs' {
    It 'creates valid nix list' {
        _nxWritePkgs -Packages @('ripgrep', 'fd')
        $content = Get-Content $Script:_nxPkgFile
        $content[0] | Should -Be '['
        $content[1] | Should -Be '  "fd"'
        $content[2] | Should -Be '  "ripgrep"'
        $content[-1] | Should -Be ']'
    }

    It 'sorts and deduplicates' {
        _nxWritePkgs -Packages @('zoxide', 'ripgrep', 'fd', 'ripgrep')
        $result = @(_nxReadPkgs)
        $result | Should -HaveCount 3
        $result[0] | Should -Be 'fd'
        $result[1] | Should -Be 'ripgrep'
        $result[2] | Should -Be 'zoxide'
    }

    It 'skips empty strings' {
        _nxWritePkgs -Packages @('', 'ripgrep', '', 'fd', '')
        $result = @(_nxReadPkgs)
        $result | Should -HaveCount 2
    }

    It 'creates empty list for empty input' {
        _nxWritePkgs -Packages @()
        $content = Get-Content $Script:_nxPkgFile
        $content[0] | Should -Be '['
        $content[-1] | Should -Be ']'
        $content | Should -HaveCount 2
    }
}

Context '_nxReadPkgs / _nxWritePkgs roundtrip' {
    It 'write then read preserves packages' {
        _nxWritePkgs -Packages @('jq', 'curl', 'wget')
        $result = @(_nxReadPkgs)
        $result[0] | Should -Be 'curl'
        $result[1] | Should -Be 'jq'
        $result[2] | Should -Be 'wget'
    }

    It 'add to existing list' {
        _nxWritePkgs -Packages @('fd', 'ripgrep')
        $current = @(_nxReadPkgs)
        _nxWritePkgs -Packages ($current + @('jq'))
        $result = @(_nxReadPkgs)
        $result | Should -HaveCount 3
        $result | Should -Contain 'jq'
    }
}

# =============================================================================
# _nxScopePkgs
# =============================================================================

Context '_nxScopePkgs' {
    It 'parses standard scope file' {
        $file = Join-Path $Script:_nxEnvDir 'scopes/shell.nix'
        Set-Content -Path $file -Value @(
            '# Shell tools'
            '{ pkgs }: with pkgs; ['
            '  fzf'
            '  eza'
            '  bat'
            ']'
        )
        $result = @(_nxScopePkgs $file)
        $result | Should -HaveCount 3
        $result | Should -Contain 'fzf'
        $result | Should -Contain 'eza'
        $result | Should -Contain 'bat'
    }

    It 'filters out pkgs and with keywords' {
        $file = Join-Path $Script:_nxEnvDir 'scopes/test.nix'
        Set-Content -Path $file -Value @(
            '{ pkgs }: with pkgs; ['
            '  git'
            ']'
        )
        $result = @(_nxScopePkgs $file)
        $result | Should -Not -Contain 'pkgs'
        $result | Should -Not -Contain 'with'
        $result | Should -Contain 'git'
    }

    It 'handles inline comments' {
        $file = Join-Path $Script:_nxEnvDir 'scopes/test.nix'
        Set-Content -Path $file -Value @(
            '{ pkgs }: with pkgs; ['
            '  bind          # provides dig'
            '  git'
            ']'
        )
        $result = @(_nxScopePkgs $file)
        $result | Should -Contain 'bind'
        $result | Should -Contain 'git'
    }

    It 'handles packages with hyphens' {
        $file = Join-Path $Script:_nxEnvDir 'scopes/test.nix'
        Set-Content -Path $file -Value @(
            '{ pkgs }: with pkgs; ['
            '  bash-completion'
            '  yq-go'
            ']'
        )
        $result = @(_nxScopePkgs $file)
        $result | Should -Contain 'bash-completion'
        $result | Should -Contain 'yq-go'
    }

    It 'returns nothing for nonexistent file' {
        $result = @(_nxScopePkgs '/nonexistent/file.nix')
        $result | Should -HaveCount 0
    }

    It 'returns nothing for empty list' {
        $file = Join-Path $Script:_nxEnvDir 'scopes/empty.nix'
        Set-Content -Path $file -Value @('{ pkgs }: with pkgs; [', ']')
        $result = @(_nxScopePkgs $file)
        $result | Should -HaveCount 0
    }
}

# =============================================================================
# _nxScopes
# =============================================================================

Context '_nxScopes' {
    It 'returns nothing when config.nix missing' {
        $result = @(_nxScopes)
        $result | Should -HaveCount 0
    }

    It 'parses multiple scopes' {
        $configFile = Join-Path $Script:_nxEnvDir 'config.nix'
        Set-Content -Path $configFile -Value @(
            '{'
            '  isInit = true;'
            ''
            '  scopes = ['
            '    "shell"'
            '    "python"'
            '    "docker"'
            '  ];'
            '}'
        )
        $result = @(_nxScopes)
        $result | Should -HaveCount 3
        $result[0] | Should -Be 'shell'
        $result[1] | Should -Be 'python'
        $result[2] | Should -Be 'docker'
    }

    It 'parses empty scopes' {
        $configFile = Join-Path $Script:_nxEnvDir 'config.nix'
        Set-Content -Path $configFile -Value @(
            '{'
            '  isInit = false;'
            '  scopes = ['
            '  ];'
            '}'
        )
        $result = @(_nxScopes)
        $result | Should -HaveCount 0
    }

    It 'parses single scope' {
        $configFile = Join-Path $Script:_nxEnvDir 'config.nix'
        Set-Content -Path $configFile -Value @(
            '{'
            '  isInit = false;'
            '  scopes = ['
            '    "shell"'
            '  ];'
            '}'
        )
        $result = @(_nxScopes)
        $result | Should -HaveCount 1
        $result[0] | Should -Be 'shell'
    }
}

# =============================================================================
# _nxIsInit
# =============================================================================

Context '_nxIsInit' {
    It 'returns false when config.nix missing' {
        $result = _nxIsInit
        $result | Should -Be 'false'
    }

    It 'returns true when isInit is true' {
        $configFile = Join-Path $Script:_nxEnvDir 'config.nix'
        Set-Content -Path $configFile -Value @(
            '{'
            '  isInit = true;'
            '  scopes = [];'
            '}'
        )
        $result = _nxIsInit
        $result | Should -Be 'true'
    }

    It 'returns false when isInit is false' {
        $configFile = Join-Path $Script:_nxEnvDir 'config.nix'
        Set-Content -Path $configFile -Value @(
            '{'
            '  isInit = false;'
            '  scopes = [];'
            '}'
        )
        $result = _nxIsInit
        $result | Should -Be 'false'
    }

    It 'parses single-line config.nix format' {
        $configFile = Join-Path $Script:_nxEnvDir 'config.nix'
        Set-Content -Path $configFile -Value '{ isInit = true; scopes = []; }'
        $result = _nxIsInit
        $result | Should -Be 'true'
    }
}

# =============================================================================
# _nxAllScopePkgMap
# =============================================================================

Context '_nxAllScopePkgMap' {
    It 'includes base packages' {
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  git', '  jq', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
            '{ isInit = false; scopes = []; }'
        )
        $map = _nxAllScopePkgMap
        $map['git'] | Should -Be 'base'
        $map['jq'] | Should -Be 'base'
    }

    It 'includes base_init when isInit is true' {
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  git', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base_init.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  nano', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
            '{'
            '  isInit = true;'
            '  scopes = [];'
            '}'
        )
        $map = _nxAllScopePkgMap
        $map['nano'] | Should -Be 'base_init'
    }

    It 'excludes base_init when isInit is false' {
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  git', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base_init.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  nano', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
            '{'
            '  isInit = false;'
            '  scopes = [];'
            '}'
        )
        $map = _nxAllScopePkgMap
        $map.ContainsKey('nano') | Should -BeFalse
    }

    It 'includes configured scope packages' {
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  git', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/shell.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  fzf', '  bat', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
            '{'
            '  isInit = false;'
            '  scopes = ['
            '    "shell"'
            '  ];'
            '}'
        )
        $map = _nxAllScopePkgMap
        $map['fzf'] | Should -Be 'shell'
        $map['bat'] | Should -Be 'shell'
        $map['git'] | Should -Be 'base'
    }

    It 'handles multiple scopes' {
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  git', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/shell.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  fzf', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/python.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  uv', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
            '{'
            '  isInit = false;'
            '  scopes = ['
            '    "shell"'
            '    "python"'
            '  ];'
            '}'
        )
        $map = _nxAllScopePkgMap
        $map['fzf'] | Should -Be 'shell'
        $map['uv'] | Should -Be 'python'
        $map['git'] | Should -Be 'base'
    }

    It 'returns empty when no scopes dir' {
        Remove-Item (Join-Path $Script:_nxEnvDir 'scopes') -Recurse -Force
        $map = _nxAllScopePkgMap
        $map.Count | Should -Be 0
    }
}

# =============================================================================
# Install/remove scope-aware validation
# =============================================================================

Context 'nx install scope validation' {
    It 'detects package already in scope' {
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  git', '  jq', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
            '{ isInit = false; scopes = []; }'
        )
        $map = _nxAllScopePkgMap
        $map.ContainsKey('git') | Should -BeTrue
        $map['git'] | Should -Be 'base'
    }

    It 'allows package not in any scope' {
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  git', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
            '{ isInit = false; scopes = []; }'
        )
        $map = _nxAllScopePkgMap
        $map.ContainsKey('ripgrep') | Should -BeFalse
    }
}

Context 'nx remove scope validation' {
    It 'detects scope-managed package' {
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  git', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/shell.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  bat', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
            '{'
            '  isInit = false;'
            '  scopes = ['
            '    "shell"'
            '  ];'
            '}'
        )
        $map = _nxAllScopePkgMap
        $map['bat'] | Should -Be 'shell'
    }

    It 'allows removing extra package' {
        _nxWritePkgs -Packages @('ripgrep', 'fd')
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  git', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
            '{ isInit = false; scopes = []; }'
        )
        $map = _nxAllScopePkgMap
        $map.ContainsKey('ripgrep') | Should -BeFalse
    }

    It 'filters scope packages from removal args' {
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base.nix') -Value @(
            '{ pkgs }: with pkgs; [', '  git', ']'
        )
        Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
            '{ isInit = false; scopes = []; }'
        )
        $map = _nxAllScopePkgMap
        $args = @('git', 'ripgrep', 'fd')
        $filtered = $args | Where-Object { -not $map.ContainsKey($_) }
        $filtered | Should -HaveCount 2
        $filtered | Should -Contain 'ripgrep'
        $filtered | Should -Contain 'fd'
    }
}
} # end Describe 'nx helpers'
