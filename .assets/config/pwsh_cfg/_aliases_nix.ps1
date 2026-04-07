# nix package management wrapper (apt/brew-like UX)
function nx {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Command,

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Args
    )

    switch ($Command) {
        'search' {
            if (-not $Args) { Write-Host 'Usage: nx search <query>' -ForegroundColor Yellow; return }
            nix search nixpkgs @Args
        }
        { $_ -in 'install', 'add' } {
            if (-not $Args) { Write-Host 'Usage: nx install <pkg> [pkg...]' -ForegroundColor Yellow; return }
            $pkgs = $Args.ForEach({ "nixpkgs#$_" })
            nix profile add @pkgs
        }
        { $_ -in 'remove', 'uninstall' } {
            if (-not $Args) { Write-Host 'Usage: nx remove <pkg> [pkg...]' -ForegroundColor Yellow; return }
            foreach ($p in $Args) {
                nix profile remove $p
            }
        }
        { $_ -in 'upgrade', 'update' } {
            if (-not $Args) {
                nix profile upgrade --all
            } else {
                foreach ($p in $Args) { nix profile upgrade "nixpkgs#$p" }
            }
        }
        { $_ -in 'list', 'ls' } {
            nix profile list
        }
        { $_ -in 'gc', 'clean' } {
            nix profile wipe-history
            nix store gc
        }
        default {
            Write-Host @'
Usage: nx <command> [args]

Commands:
  search  <query>         Search for packages in nixpkgs
  install <pkg> [pkg...]  Install one or more packages
  remove  <pkg> [pkg...]  Remove one or more packages
  upgrade [pkg]           Upgrade all packages or a specific one
  list                    List installed packages
  gc                      Garbage collect old versions and free disk space
  help                    Show this help
'@
        }
    }
}

Register-ArgumentCompleter -CommandName nx -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)
    @('search', 'install', 'remove', 'upgrade', 'list', 'gc', 'help') | Where-Object {
        $_ -like "$wordToComplete*"
    } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
