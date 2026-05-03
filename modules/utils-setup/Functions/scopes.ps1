function Resolve-ScopeDeps {
    <#
    .SYNOPSIS
    Expands implicit scope dependencies in a HashSet using shared rules from scopes.json.
    .PARAMETER ScopeSet
    A HashSet[string] of enabled scopes - modified in-place.
    .PARAMETER OmpTheme
    If non-empty, implies oh_my_posh scope.
    #>
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.HashSet[string]]$ScopeSet,

        [string]$OmpTheme
    )

    if ($OmpTheme) {
        $ScopeSet.Add('oh_my_posh') | Out-Null
    }

    foreach ($rule in $Script:ScopeDependencyRules) {
        if ($ScopeSet.Contains($rule.if)) {
            $rule.add.ForEach({ $ScopeSet.Add($_) | Out-Null })
        }
    }
}

function Get-SortedScopes {
    <#
    .SYNOPSIS
    Returns scopes sorted by install order from scopes.json.
    .PARAMETER ScopeSet
    A HashSet[string] or string array of enabled scopes.
    #>
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.HashSet[string]]$ScopeSet
    )

    [string[]]$sorted = $ScopeSet | Sort-Object -Unique {
        $idx = [array]::IndexOf($Script:InstallOrder, $_)
        if ($idx -ge 0) { $idx } else { 999 }
    }
    return $sorted
}
