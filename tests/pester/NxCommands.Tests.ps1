#Requires -Modules Pester
# Unit tests for nx CLI commands (pin, rollback, scope remove, scope edit, help)

BeforeAll {
    # dot-source the aliases file (side effects are harmless: alias/function defs)
    . (Join-Path $PSScriptRoot '../../.assets/config/pwsh_cfg/_aliases_nix.ps1')

    # override functions that call external commands
    function _nxApply { }
    function _nxValidatePkg { param([string]$Name); return $true }
    function nix { param([Parameter(ValueFromRemainingArguments)][string[]]$a) }
}

Describe 'nx commands' {
    BeforeEach {
        $Script:_nxEnvDir = Join-Path ([IO.Path]::GetTempPath()) "pester-nxcmd-$([guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -Path $Script:_nxEnvDir -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $Script:_nxEnvDir 'scopes') -ItemType Directory -Force | Out-Null
        $Script:_nxPkgFile = Join-Path $Script:_nxEnvDir 'packages.nix'
    }

    AfterEach {
        if (Test-Path $Script:_nxEnvDir) {
            Remove-Item $Script:_nxEnvDir -Recurse -Force
        }
    }

    # =========================================================================
    # help
    # =========================================================================

    Context 'help' {
        It 'nx help shows usage' {
            $result = nx help 6>&1 | Out-String
            $result | Should -Match 'Usage: nx'
            $result | Should -Match 'install'
            $result | Should -Match 'upgrade'
            $result | Should -Match 'pin'
            $result | Should -Match 'rollback'
        }

        It 'nx without args shows help' {
            $result = nx 6>&1 | Out-String
            $result | Should -Match 'Usage: nx'
        }

        It 'nx unknown command shows help' {
            $result = nx fakecmd 6>&1 | Out-String
            $result | Should -Match 'Usage: nx'
        }
    }

    # =========================================================================
    # scope help
    # =========================================================================

    Context 'scope help' {
        It 'nx scope without subcommand shows help' {
            $result = nx scope 6>&1 | Out-String
            $result | Should -Match 'Usage: nx scope'
            $result | Should -Match 'list'
            $result | Should -Match 'add'
            $result | Should -Match 'edit'
            $result | Should -Match 'remove'
        }
    }

    # =========================================================================
    # pin set
    # =========================================================================

    Context 'pin set' {
        It 'pin set without rev reads from flake.lock' {
            $lockContent = @{
                nodes = @{
                    nixpkgs = @{
                        locked = @{
                            rev = 'abc123def456'
                        }
                    }
                }
            } | ConvertTo-Json -Depth 5
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'flake.lock') -Value $lockContent

            $result = nx pin set 6>&1 | Out-String
            $result | Should -Match 'Pinned nixpkgs to abc123def456'
            $pinFile = Join-Path $Script:_nxEnvDir 'pinned_rev'
            Test-Path $pinFile | Should -BeTrue
            (Get-Content $pinFile -Raw).Trim() | Should -Be 'abc123def456'
        }

        It 'pin set with explicit rev uses that rev' {
            $result = nx pin set deadbeef123 6>&1 | Out-String
            $result | Should -Match 'Pinned nixpkgs to deadbeef123'
            $pinFile = Join-Path $Script:_nxEnvDir 'pinned_rev'
            (Get-Content $pinFile -Raw).Trim() | Should -Be 'deadbeef123'
        }

        It 'pin set without rev fails when no flake.lock' {
            $result = nx pin set 6>&1 | Out-String
            $result | Should -Match 'No flake.lock found'
        }

        It 'pin set overwrites existing pin' {
            $pinFile = Join-Path $Script:_nxEnvDir 'pinned_rev'
            Set-Content -Path $pinFile -Value "oldrev`n"
            nx pin set newrev 6>&1 | Out-Null
            (Get-Content $pinFile -Raw).Trim() | Should -Be 'newrev'
        }
    }

    # =========================================================================
    # pin show
    # =========================================================================

    Context 'pin show' {
        It 'displays current pin' {
            $pinFile = Join-Path $Script:_nxEnvDir 'pinned_rev'
            Set-Content -Path $pinFile -Value "abc123`n"
            $result = nx pin show 6>&1 | Out-String
            $result | Should -Match 'Pinned to:'
            $result | Should -Match 'abc123'
        }

        It 'reports no pin when file missing' {
            $result = nx pin show 6>&1 | Out-String
            $result | Should -Match 'No pin set'
        }
    }

    # =========================================================================
    # pin remove
    # =========================================================================

    Context 'pin remove' {
        It 'deletes pin file' {
            $pinFile = Join-Path $Script:_nxEnvDir 'pinned_rev'
            Set-Content -Path $pinFile -Value "abc123`n"
            $result = nx pin remove 6>&1 | Out-String
            $result | Should -Match 'Pin removed'
            Test-Path $pinFile | Should -BeFalse
        }

        It 'reports no pin when file missing' {
            $result = nx pin remove 6>&1 | Out-String
            $result | Should -Match 'No pin set'
        }
    }

    # =========================================================================
    # pin help
    # =========================================================================

    Context 'pin help' {
        It 'shows usage' {
            $result = nx pin help 6>&1 | Out-String
            $result | Should -Match 'Usage: nx pin'
            $result | Should -Match 'set'
            $result | Should -Match 'remove'
            $result | Should -Match 'show'
        }

        It 'pin without subcommand shows current pin status' {
            $result = nx pin 6>&1 | Out-String
            $result | Should -Match 'No pin set'
        }
    }

    # =========================================================================
    # upgrade with pinned_rev
    # =========================================================================

    Context 'upgrade' {
        It 'reads pinned_rev file when present' {
            $pinFile = Join-Path $Script:_nxEnvDir 'pinned_rev'
            Set-Content -Path $pinFile -Value "pinnedabc123`n"
            $result = nx upgrade 6>&1 | Out-String
            $result | Should -Match 'pinning nixpkgs to pinnedabc123'
        }

        It 'without pin does normal update' {
            $result = nx upgrade 6>&1 | Out-String
            $result | Should -Not -Match 'pinning nixpkgs'
        }
    }

    # =========================================================================
    # scope remove with local_ prefix
    # =========================================================================

    Context 'scope remove' {
        It 'handles local_ prefix transparently' {
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
                '{'
                '  isInit = false;'
                ''
                '  scopes = ['
                '    "shell"'
                '    "local_devtools"'
                '  ];'
                '}'
            )
            $localDir = Join-Path $Script:_nxEnvDir 'local/scopes'
            New-Item -Path $localDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $localDir 'devtools.nix') -Value '{ pkgs }: with pkgs; []'
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/local_devtools.nix') -Value '{ pkgs }: with pkgs; []'

            $result = nx scope remove devtools 6>&1 | Out-String
            $result | Should -Match 'removed scope: devtools'
            $configContent = Get-Content (Join-Path $Script:_nxEnvDir 'config.nix') -Raw
            $configContent | Should -Not -Match 'local_devtools'
            Test-Path (Join-Path $localDir 'devtools.nix') | Should -BeFalse
            Test-Path (Join-Path $Script:_nxEnvDir 'scopes/local_devtools.nix') | Should -BeFalse
        }

        It 'handles repo scope by name' {
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
                '{'
                '  isInit = false;'
                ''
                '  scopes = ['
                '    "shell"'
                '    "python"'
                '  ];'
                '}'
            )

            $result = nx scope remove python 6>&1 | Out-String
            $result | Should -Match 'removed scope: python'
            $configContent = Get-Content (Join-Path $Script:_nxEnvDir 'config.nix') -Raw
            $configContent | Should -Not -Match '"python"'
            $configContent | Should -Match '"shell"'
        }

        It 'cleans orphaned overlay files' {
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
                '{'
                '  isInit = false;'
                ''
                '  scopes = ['
                '    "shell"'
                '  ];'
                '}'
            )
            $localDir = Join-Path $Script:_nxEnvDir 'local/scopes'
            New-Item -Path $localDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $localDir 'orphan.nix') -Value '{ pkgs }: with pkgs; []'
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/local_orphan.nix') -Value '{ pkgs }: with pkgs; []'

            nx scope remove orphan 6>&1 | Out-Null
            Test-Path (Join-Path $localDir 'orphan.nix') | Should -BeFalse
            Test-Path (Join-Path $Script:_nxEnvDir 'scopes/local_orphan.nix') | Should -BeFalse
        }

        It 'removes multiple scopes at once' {
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
                '{'
                '  isInit = false;'
                ''
                '  scopes = ['
                '    "shell"'
                '    "python"'
                '    "local_devtools"'
                '  ];'
                '}'
            )
            $localDir = Join-Path $Script:_nxEnvDir 'local/scopes'
            New-Item -Path $localDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $localDir 'devtools.nix') -Value '{ pkgs }: with pkgs; []'
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/local_devtools.nix') -Value '{ pkgs }: with pkgs; []'

            $result = nx scope remove python devtools 6>&1 | Out-String
            $result | Should -Match 'removed scope: python'
            $result | Should -Match 'removed scope: devtools'
            $configContent = Get-Content (Join-Path $Script:_nxEnvDir 'config.nix') -Raw
            $configContent | Should -Match '"shell"'
            $configContent | Should -Not -Match '"python"'
            $configContent | Should -Not -Match 'local_devtools'
        }

        It 'reports unknown scope' {
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
                '{'
                '  isInit = false;'
                ''
                '  scopes = ['
                '    "shell"'
                '  ];'
                '}'
            )
            $result = nx scope remove nonexistent 6>&1 | Out-String
            $result | Should -Match 'not configured'
        }
    }

    # =========================================================================
    # scope edit
    # =========================================================================

    Context 'scope edit' {
        It 'fails for nonexistent scope' {
            $result = nx scope edit nonexistent 6>&1 | Out-String
            $result | Should -Match 'not found'
        }

        It 'opens file and syncs copy' {
            $localDir = Join-Path $Script:_nxEnvDir 'local/scopes'
            New-Item -Path $localDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $localDir 'mytools.nix') -Value '{ pkgs }: with pkgs; []'
            # use 'true' as EDITOR to simulate a no-op edit
            $env:EDITOR = 'true'
            $result = nx scope edit mytools 6>&1 | Out-String
            $result | Should -Match 'Synced scope'
            Test-Path (Join-Path $Script:_nxEnvDir 'scopes/local_mytools.nix') | Should -BeTrue
            Remove-Item Env:EDITOR -ErrorAction SilentlyContinue
        }
    }

    # =========================================================================
    # scope add
    # =========================================================================

    Context 'scope add' {
        It 'creates scope and reports guidance' {
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
                '{'
                '  isInit = false;'
                '  scopes = [];'
                '}'
            )

            $result = nx scope add newscope 6>&1 | Out-String
            $result | Should -Match 'Created scope'
            $result | Should -Match 'nx scope add newscope'
            $scopeFile = Join-Path $Script:_nxEnvDir 'local/scopes/newscope.nix'
            Test-Path $scopeFile | Should -BeTrue
        }

        It 'reports existing scope' {
            $localDir = Join-Path $Script:_nxEnvDir 'local/scopes'
            New-Item -Path $localDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $localDir 'existing.nix') -Value '{ pkgs }: with pkgs; []'
            $result = nx scope add existing 6>&1 | Out-String
            $result | Should -Match 'already exists'
        }
    }

    # =========================================================================
    # scope list
    # =========================================================================

    Context 'scope list' {
        It 'shows installed scopes' {
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
                '{'
                '  isInit = false;'
                ''
                '  scopes = ['
                '    "shell"'
                '    "python"'
                '  ];'
                '}'
            )
            $result = nx scope list 6>&1 | Out-String
            $result | Should -Match 'shell'
            $result | Should -Match 'python'
        }

        It 'shows no scopes when empty' {
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
                '{'
                '  isInit = false;'
                '  scopes = [];'
                '}'
            )
            $result = nx scope list 6>&1 | Out-String
            $result | Should -Match 'No scopes'
        }
    }

    # =========================================================================
    # scope show
    # =========================================================================

    Context 'scope show' {
        It 'displays packages in a scope' {
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/shell.nix') -Value @(
                '{ pkgs }: with pkgs; ['
                '  fzf'
                '  bat'
                '  ripgrep'
                ']'
            )
            $result = nx scope show shell 6>&1 | Out-String
            $result | Should -Match 'fzf'
            $result | Should -Match 'bat'
            $result | Should -Match 'ripgrep'
        }

        It 'reports unknown scope' {
            $result = nx scope show nonexistent 6>&1 | Out-String
            $result | Should -Match 'not found'
        }
    }

    # =========================================================================
    # scope tree
    # =========================================================================

    Context 'scope tree' {
        It 'shows scopes with packages' {
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'config.nix') -Value @(
                '{'
                '  isInit = false;'
                ''
                '  scopes = ['
                '    "shell"'
                '  ];'
                '}'
            )
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/shell.nix') -Value @(
                '{ pkgs }: with pkgs; ['
                '  fzf'
                '  bat'
                ']'
            )
            Set-Content -Path (Join-Path $Script:_nxEnvDir 'scopes/base.nix') -Value @(
                '{ pkgs }: with pkgs; ['
                '  git'
                ']'
            )
            $result = nx scope tree 6>&1 | Out-String
            $result | Should -Match 'shell'
            $result | Should -Match 'fzf'
        }
    }

    # =========================================================================
    # _nxScopeFileAdd helper
    # =========================================================================

    Context '_nxScopeFileAdd' {
        It 'adds packages to scope file' {
            $file = Join-Path $Script:_nxEnvDir 'test.nix'
            Set-Content -Path $file -Value '{ pkgs }: with pkgs; []'
            _nxScopeFileAdd -File $file -Packages @('httpie', 'jq')
            $content = Get-Content $file -Raw
            $content | Should -Match 'httpie'
            $content | Should -Match 'jq'
        }

        It 'deduplicates existing packages' {
            $file = Join-Path $Script:_nxEnvDir 'test.nix'
            Set-Content -Path $file -Value @(
                '{ pkgs }: with pkgs; ['
                '  httpie'
                ']'
            )
            $result = _nxScopeFileAdd -File $file -Packages @('httpie') 6>&1 | Out-String
            $result | Should -Match 'already in scope'
        }

        It 'sorts packages' {
            $file = Join-Path $Script:_nxEnvDir 'test.nix'
            Set-Content -Path $file -Value '{ pkgs }: with pkgs; []'
            _nxScopeFileAdd -File $file -Packages @('zoxide', 'bat', 'httpie')
            $pkgs = @(_nxScopePkgs $file)
            $pkgs[0] | Should -Be 'bat'
            $pkgs[1] | Should -Be 'httpie'
            $pkgs[2] | Should -Be 'zoxide'
        }
    }

    # =========================================================================
    # rollback
    # =========================================================================

    Context 'rollback' {
        It 'succeeds when nix profile rollback succeeds' {
            $result = nx rollback 6>&1 | Out-String
            $result | Should -Match 'Rolled back'
            $result | Should -Match 'Restart your shell'
        }
    }

    # =========================================================================
    # overlay help
    # =========================================================================

    Context 'overlay' {
        It 'overlay help shows usage' {
            $result = nx overlay help 6>&1 | Out-String
            $result | Should -Match 'Usage: nx overlay'
        }
    }
} # end Describe 'nx commands'
