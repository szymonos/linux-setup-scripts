#!/usr/bin/pwsh -nop
#Requires -PSEdition Core
<#
.SYNOPSIS
Compare performance of two scripts.
.PARAMETER Command1
First command string to be compared.
.PARAMETER Command2
Second command string to be compared.
.PARAMETER Iterations
Number of iterations to run the comparison. Default is 10.
.PARAMETER WarmUp
Do specified number of warmup iterations.
.PARAMETER ShowIterations
Show iteration results during benchmark.

.EXAMPLE
# :specify command
$Command1 = { pwsh -nop -c exit }
$Command2 = { pwsh -c exit }
# :run benchmark
.assets/tools/cmd_bench_compare.ps1 $Command1 $Command2
$Iterations = 5
.assets/tools/cmd_bench_compare.ps1 $Command1 $Command2 -i $Iterations
$WarmUp = 2
.assets/tools/cmd_bench_compare.ps1 $Command1 $Command2 -i $Iterations -w $WarmUp
#>
using module do-common

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0, HelpMessage = 'The first command to be benched.')]
    [scriptblock]$Command1,

    [Parameter(Mandatory, Position = 1, HelpMessage = 'The second command to be benched.')]
    [scriptblock]$Command2,

    [Parameter(HelpMessage = 'The number of iterations the command should be performed.')]
    [int]$Iterations = 10,

    [Parameter(HelpMessage = 'The number of iterations the command should be performed.')]
    [int]$WarmUp,

    [switch]$ShowIterations
)

begin {
    $ErrorActionPreference = 'Stop'
    Write-Verbose "Starting benchmark with $Iterations iterations and $WarmUp warm-up runs."

    # instantiate results list
    $results = [Collections.Generic.List[PSCustomObject]]::new()
    # length of the Iterations string
    $iterLen = "$Iterations".Length
    # initialize hashtable holding winning results
    $propWins = [ordered]@{
        Measure  = 'Wins'
        Command1 = 0
        Command2 = 0
    }
    # clear screen
    Clear-Host
}

process {
    # perform warming up
    if ($WarmUp) {
        for ($i = 1; $i -le $WarmUp; $i++) {
            $pct = $i / $WarmUp
            Write-Progress -Activity 'Warming up' -Status ('Processing: {0:P0}' -f $pct) -PercentComplete ($pct * 100)
            Invoke-Command $Command1 | Out-Null
            Invoke-Command $Command2 | Out-Null
        }
        Write-Progress -Activity 'Warming up' -Completed
    }
    # perform benchmark
    for ($i = 1; $i -le $Iterations; $i++) {
        $res = [PSCustomObject]@{
            '#' = $i;
            ms1 = Measure-Command -Expression $Command1
            ms2 = Measure-Command -Expression $Command2
        }
        $results.Add($res)
        $winner = $res.ms1.Ticks -le $res.ms2.Ticks ? 1 : 2
        $propWins["Command${winner}"] += 1
        if ($ShowIterations) {
            # calculate results to display
            $t2 = Format-Duration ([timespan]::FromMilliseconds($res.ms2.TotalMilliseconds))
            $t1 = Format-Duration ([timespan]::FromMilliseconds($res.ms1.TotalMilliseconds))
            $diffPct = $($res.ms2.Ticks / $res.ms1.Ticks).ToString('P0')
            # write header
            if ($i -eq 1) {
                "`e[92m$(' ' * ($iterLen - 1))# Command1 Command2 Winner Difference`e[0m"
                "`e[92m$(' ' * ($iterLen - 1))- -------- -------- ------ ----------`e[0m"
            }
            # write results
            $formatArgs = @(
                $(' ' * ($iterLen - "$i".Length)), $i
                $(' ' * (9 - "$t1".Length)), $t1
                $(' ' * (9 - "$t2".Length)), $t2
                $(' ' * 6), $winner
                $(' ' * (11 - "$diffPct".Length)), $diffPct
            )
            '{0}{1}{2}{3}{4}{5}{6}{7}{8}{9}' -f $formatArgs
        } else {
            $pct = $i / $Iterations
            Write-Progress -Activity 'Benchmark' -Status ('Processing: {0:P0}' -f $pct) -PercentComplete ($pct * 100)
        }
    }
    if (-not $ShowIterations) {
        Write-Progress -Activity 'Benchmark' -Completed
    }
    # measure statistics
    $measure1 = $results.ms1.TotalMilliseconds | Measure-Object -AllStats
    $measure2 = $results.ms2.TotalMilliseconds | Measure-Object -AllStats
    # calculate summary results
    $summary = @(
        [PSCustomObject]$propWins
        [PSCustomObject]@{
            Measure  = 'Average';
            Command1 = Format-Duration ([timespan]::FromMilliseconds($measure1.Average))
            Command2 = Format-Duration ([timespan]::FromMilliseconds($measure2.Average))
        }
        [PSCustomObject]@{
            Measure  = 'Minimum';
            Command1 = Format-Duration ([timespan]::FromMilliseconds($measure1.Minimum))
            Command2 = Format-Duration ([timespan]::FromMilliseconds($measure2.Minimum))
        }
        [PSCustomObject]@{
            Measure  = 'Maximum';
            Command1 = Format-Duration ([timespan]::FromMilliseconds($measure1.Maximum))
            Command2 = Format-Duration ([timespan]::FromMilliseconds($measure2.Maximum))
        }
        [PSCustomObject]@{
            Measure  = 'StandardDeviation';
            Command1 = Format-Duration ([timespan]::FromMilliseconds($measure1.StandardDeviation))
            Command2 = Format-Duration ([timespan]::FromMilliseconds($measure2.StandardDeviation))
        }
        [PSCustomObject]@{
            Measure  = 'CoeficientOfVariation';
            Command1 = ($measure1.StandardDeviation / $measure1.Average).ToString('P1')
            Command2 = ($measure2.StandardDeviation / $measure2.Average).ToString('P1')
        }
        [PSCustomObject]@{
            Measure  = 'TotalTime';
            Command1 = Format-Duration ([timespan]::FromMilliseconds($measure1.Sum))
            Command2 = Format-Duration ([timespan]::FromMilliseconds($measure2.Sum))
        }
    )
}

end {
    # write statistics
    $summary
    # Write summary conclusion
    if ($measure1.Sum -lt $measure2.Sum) {
        "`nCommand1 was `e[1m{0:N2}`e[0mx faster than Command2" -f ($measure2.Sum / $measure1.Sum)
    } else {
        "`nCommand2 was `e[1m{0:N2}`e[0mx faster than Command1" -f ($measure1.Sum / $measure2.Sum)
    }
}
