#!/usr/bin/env -S pwsh -nop
#Requires -PSEdition Core
<#
.SYNOPSIS
Script running a specified command number of iterations and displaying time statistics.

.PARAMETER Command
The command to be benched.
.PARAMETER Iterations
The number of iterations the command should be performed.
.PARAMETER WarmUp
Do specified number of warmup iterations

.EXAMPLE
# ~specify command
$Command = { git status }
$Command = { prompt }
$Command = { python -V }
$Command = { pwsh -noni -c exit }
$Command = { pwsh -nop -noni -c exit }
$Command = { powershell -nop -noni -c exit }
$Command = { cmd /c exit }
$Command = { bash -c exit }
# ~run benchmark
.assets/tools/cmd_bench.ps1 $Command
$Iterations = 100
.assets/tools/cmd_bench.ps1 $Command -i $Iterations
$WarmUp = 10
.assets/tools/cmd_bench.ps1 $Command -i $Iterations -w $WarmUp
#>
using module do-common

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0, HelpMessage = 'The command to be benched.')]
    [scriptblock]$Command,

    [Parameter(HelpMessage = 'The number of iterations the command should be performed.')]
    [int]$Iterations = 10,

    [Parameter(HelpMessage = 'The number of iterations the command should be performed.')]
    [int]$WarmUp
)

begin {
    $ErrorActionPreference = 'Stop'

    $results = [Collections.Generic.List[decimal]]::new()
}

process {
    # perform warming up
    if ($WarmUp) {
        for ($i = 1; $i -le $WarmUp; $i++) {
            $pct = $i / $WarmUp
            Write-Progress -Activity 'Warming up' -Status ('Processing: {0:P0}' -f $pct) -PercentComplete ($pct * 100)
            Invoke-Command $Command | Out-Null
        }
        Write-Progress -Activity 'Warming up' -Completed
    }
    # perform benchmark
    for ($i = 1; $i -le $Iterations; $i++) {
        $pct = $i / $Iterations
        Write-Progress -Activity 'Bench command' -Status ('Processing: {0:P0}' -f $pct) -PercentComplete ($pct * 100)
        $results.Add((Measure-Command -Expression $Command).TotalMilliseconds)
    }
    Write-Progress -Activity 'Bench command' -Completed
    # calculate statistics
    $timeStats = $results | Measure-Object -AllStats
    # create result hashtable
    $benchmarkResult = [PSCustomObject]@{
        TimeStamp             = (Get-Date).ToString('s')
        Command               = $Command.ToString().Trim() -replace "`r?`n", ';' -replace ' {2,}', ' '
        Count                 = $timeStats.Count
        Average               = Format-Duration ([timespan]::FromMilliseconds($timeStats.Average))
        Minimum               = Format-Duration ([timespan]::FromMilliseconds($timeStats.Minimum))
        Maximum               = Format-Duration ([timespan]::FromMilliseconds($timeStats.Maximum))
        StandardDeviation     = Format-Duration ([timespan]::FromMilliseconds($timeStats.StandardDeviation))
        CoeficientOfVariation = ($timeStats.StandardDeviation / $timeStats.Average).ToString('P1')
        TotalTime             = Format-Duration ([timespan]::FromMilliseconds($timeStats.Sum))
    }
}

end {
    return $benchmarkResult
}
