<#
.SYNOPSIS
Module providing a cli command wrappers.
#>


<#
.SYNOPSIS
Executes dig command and colorizes output for better readability.

.DESCRIPTION
Runs dig with provided arguments, captures all output, and applies color formatting
to hostnames and responses. Each unique host gets assigned a distinct color code.

.PARAMETER ArgumentList
Arguments to pass to dig command. Accepts multiple arguments.

.EXAMPLE
Invoke-DigColored example.com
# Runs dig for example.com and colorizes the output.

.EXAMPLE
Invoke-DigColored example.com -StripRawOutput
# Runs dig for example.com and colorizes the output, without printing raw output.

.EXAMPLE
Invoke-DigColored @('google.com', 'ANY')
# Runs dig with multiple arguments and colorizes the output.
#>
function Invoke-DigColored {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromRemainingArguments)]
        [string[]]$ArgumentList,

        [Alias('s')]
        [switch]$StripRawOutput
    )

    begin {
        $ErrorActionPreference = 'Stop'

        # verify dig is available
        if (-not (Get-Command dig -ErrorAction SilentlyContinue)) {
            throw 'dig command not found. Please install dig (dnsutils package).'
        }
    }

    process {
        try {
            # execute dig and capture all output
            $digOutput = & dig @ArgumentList 2>&1
            if ($?) {
                $allLines = $digOutput.Trim().Where( { -not [string]::IsNullOrWhiteSpace($_) } )
            } else {
                Show-LogContext 'dig command failed to execute.' -Level ERROR
                return
            }

            if ($allLines.Count -eq 0) {
                Show-LogContext 'No output from dig command.' -Level WARNING
                return
            }

            $hosts = [System.Collections.Generic.Dictionary[string, int]]::new()
            $uniqueHostCount = 0

            # calculate max host length for alignment
            $maxHostLength = 0
            foreach ($line in $allLines) {
                if ($line -match '^\s*$' -or $line -match '^;') { continue }
                $parts = $line -split '\s+', 0, 'RegexMatch'
                foreach ($part in $parts) {
                    if ($part.Length -gt $maxHostLength) {
                        $maxHostLength = $part.Length
                    }
                }
            }

            if ($PSBoundParameters.ContainsKey('StripRawOutput')) {
                # write initial new line
                Write-Host ''
            } else {
                # print raw output in dim text
                Write-Host "`e[2m$($allLines -join "`n")`e[0m`n"
            }

            # process and colorize DNS records
            foreach ($line in $allLines) {
                # skip empty lines and comments
                if ($line -match '^\s*$' -or $line -match '^;') { continue }

                # parse DNS record: host, ttl, class, type, value
                if ($line -match '^(\S+)\s+([0-9]+)\s+(\S+)\s+(\S+)\s+(.+)$') {
                    $hostname = $Matches[1]
                    $ttl = $Matches[2]
                    $class = $Matches[3]
                    $type = $Matches[4]
                    $value = $Matches[5]

                    # assign color to host if not seen before (starting at color 91)
                    if (-not $hosts.ContainsKey($hostname)) {
                        $hosts[$hostname] = 91 + $uniqueHostCount++
                    }

                    # assign color to value if not seen before
                    if (-not $hosts.ContainsKey($value)) {
                        $hosts[$value] = 91 + $uniqueHostCount++
                    }

                    # format and print colorized output
                    $hostColor = $hosts[$hostname]
                    $valueColor = $hosts[$value]

                    Write-Host ("`e[1;{0}m{1,-$maxHostLength}`e[0m {2,5} {3} {4,-5} `e[1;{5}m{6}`e[0m" -f `
                            $hostColor, $hostname, $ttl, $class, $type, $valueColor, $value)
                }
            }
        } catch {
            Show-LogContext $_
            throw
        }
    }
    end {
        # write final new line
        Write-Host ''
    }
}

# create alias for convenience
Set-Alias -Name digc -Value Invoke-DigColored -Scope Global -Option AllScope -Force
