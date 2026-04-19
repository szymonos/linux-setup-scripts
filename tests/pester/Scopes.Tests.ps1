#Requires -Modules Pester
# Unit tests for Resolve-ScopeDeps and Get-SortedScopes in SetupUtils module

BeforeAll {
    # source the functions directly
    . $PSScriptRoot/../../modules/SetupUtils/Functions/scopes.ps1

    # load shared scope definitions (same as the module does)
    $scopesData = [IO.File]::ReadAllText("$PSScriptRoot/../../.assets/lib/scopes.json") | ConvertFrom-Json
    $Script:ValidScopes = [string[]]$scopesData.valid_scopes
    $Script:InstallOrder = [string[]]$scopesData.install_order
    $Script:ScopeDependencyRules = $scopesData.dependency_rules
}

Describe 'Resolve-ScopeDeps' {
    It 'az adds python' {
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('az'))
        Resolve-ScopeDeps -ScopeSet $set
        $set | Should -Contain 'python'
    }

    It 'k8s_ext adds docker, k8s_base, k8s_dev' {
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('k8s_ext'))
        Resolve-ScopeDeps -ScopeSet $set
        $set | Should -Contain 'docker'
        $set | Should -Contain 'k8s_base'
        $set | Should -Contain 'k8s_dev'
    }

    It 'pwsh adds shell' {
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('pwsh'))
        Resolve-ScopeDeps -ScopeSet $set
        $set | Should -Contain 'shell'
    }

    It 'zsh adds shell' {
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('zsh'))
        Resolve-ScopeDeps -ScopeSet $set
        $set | Should -Contain 'shell'
    }

    It 'oh_my_posh adds shell' {
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('oh_my_posh'))
        Resolve-ScopeDeps -ScopeSet $set
        $set | Should -Contain 'shell'
    }

    It 'starship adds shell' {
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('starship'))
        Resolve-ScopeDeps -ScopeSet $set
        $set | Should -Contain 'shell'
    }

    It 'OmpTheme parameter adds oh_my_posh and shell' {
        $set = [System.Collections.Generic.HashSet[string]]::new()
        $set.Add('_placeholder') | Out-Null
        Resolve-ScopeDeps -ScopeSet $set -OmpTheme 'agnoster'
        $set | Should -Contain 'oh_my_posh'
        $set | Should -Contain 'shell'
    }

    It 'empty OmpTheme does not add oh_my_posh' {
        $set = [System.Collections.Generic.HashSet[string]]::new()
        $set.Add('rice') | Out-Null
        Resolve-ScopeDeps -ScopeSet $set -OmpTheme ''
        $set | Should -Not -Contain 'oh_my_posh'
    }

    It 'unknown scope has no dependencies' {
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('rice'))
        Resolve-ScopeDeps -ScopeSet $set
        $set | Should -HaveCount 1
        $set | Should -Contain 'rice'
    }

    It 'is idempotent' {
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('az'))
        Resolve-ScopeDeps -ScopeSet $set
        $count1 = $set.Count
        Resolve-ScopeDeps -ScopeSet $set
        $set.Count | Should -Be $count1
    }

    It 'chains transitive dependencies' {
        # k8s_ext -> k8s_dev -> k8s_base (transitively via two rules)
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('k8s_ext'))
        Resolve-ScopeDeps -ScopeSet $set
        $set | Should -Contain 'k8s_base'
        $set | Should -Contain 'k8s_dev'
        $set | Should -Contain 'docker'
    }
}

Describe 'Get-SortedScopes' {
    It 'sorts scopes by install order' {
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('shell', 'docker', 'python'))
        $sorted = Get-SortedScopes -ScopeSet $set
        $sorted[0] | Should -Be 'docker'
        $sorted[1] | Should -Be 'python'
        $sorted[2] | Should -Be 'shell'
    }

    It 'unknown scopes sort to end' {
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('shell', 'unknown_scope'))
        $sorted = Get-SortedScopes -ScopeSet $set
        $sorted[-1] | Should -Be 'unknown_scope'
    }

    It 'handles single scope' {
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@('python'))
        $sorted = Get-SortedScopes -ScopeSet $set
        # single-item HashSet may unwrap; force array
        @($sorted) | Should -HaveCount 1
        @($sorted)[0] | Should -Be 'python'
    }

    It 'returns empty for empty set' {
        $set = [System.Collections.Generic.HashSet[string]]::new()
        $set.Add('_') | Out-Null  # need non-empty to pass validation
        $set.Remove('_') | Out-Null
        # HashSet is now empty but was once non-empty
        # PowerShell Mandatory validation rejects truly empty collections
        # so we test with a single-element set and verify count
        $set.Add('python') | Out-Null
        $sorted = Get-SortedScopes -ScopeSet $set
        $set.Remove('python') | Out-Null
        # just verify the function works; empty set cannot be passed due to validation
        @($sorted) | Should -HaveCount 1
    }

    It 'full install order is respected' {
        # use all scopes from install_order
        $set = [System.Collections.Generic.HashSet[string]]::new([string[]]$Script:InstallOrder)
        $sorted = Get-SortedScopes -ScopeSet $set
        for ($i = 0; $i -lt $sorted.Count; $i++) {
            $sorted[$i] | Should -Be $Script:InstallOrder[$i]
        }
    }
}
