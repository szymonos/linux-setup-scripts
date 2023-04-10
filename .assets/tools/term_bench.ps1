#!/usr/bin/env -S pwsh -nop
<#
.SYNOPSIS
Script synopsis.
.EXAMPLE
.assets/tools/term_bench.ps1 1000
.assets/tools/term_bench.ps1 10000
.assets/tools/term_bench.ps1 100000
#>
param (
    [int]$Iterations
)

$duration = Measure-Command {
    foreach ($i in 1..$Iterations) {
        [Console]::WriteLine('')
        [Console]::WriteLine("`e[0K`e[1mBold`e[0m `e[7mInvert`e[0m `e[4mUnderline`e[0m")
        [Console]::WriteLine("`e[0K`e[1m`e[7m`e[4mBold & Invert & Underline`e[0m")
        [Console]::WriteLine('')
        [Console]::WriteLine("`e[0K`e[31m Red `e[32m Green `e[33m Yellow `e[34m Blue `e[35m Magenta `e[36m Cyan `e[0m")
        [Console]::WriteLine("`e[0K`e[1m`e[4m`e[31m Red `e[32m Green `e[33m Yellow `e[34m Blue `e[35m Magenta `e[36m Cyan `e[0m")
        [Console]::WriteLine('')
        [Console]::WriteLine("`e[0K`e[41m Red `e[42m Green `e[43m Yellow `e[44m Blue `e[45m Magenta `e[46m Cyan `e[0m")
        [Console]::WriteLine("`e[0K`e[1m`e[4m`e[41m Red `e[42m Green `e[43m Yellow `e[44m Blue `e[45m Magenta `e[46m Cyan `e[0m")
        [Console]::WriteLine('')
        [Console]::WriteLine("`e[0K`e[30m`e[41m Red `e[42m Green `e[43m Yellow `e[44m Blue `e[45m Magenta `e[46m Cyan `e[0m")
        [Console]::WriteLine("`e[0K`e[30m`e[1m`e[4m`e[41m Red `e[42m Green `e[43m Yellow `e[44m Blue `e[45m Magenta `e[46m Cyan `e[0m")
    }
}

return $duration.ToString('m\ms\.fff\s')
