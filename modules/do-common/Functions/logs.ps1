<#
.SYNOPSIS
Function to set the log file and return the path.

.PARAMETER Path
The path to the log file.
.PARAMETER Append
Switch, whether to append to the existing log file.
#>
function Set-LogFile {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [ValidateScript({ $_ -match '\.log$' }, ErrorMessage = 'Specified file should have .log extension.')]
        [string]$Path = "logs/$(Get-Date -Format 'yyyyMMddTHHmmss').log",

        [switch]$Append
    )

    # *ensure that the log file exists
    if (-not (Test-Path $Path -PathType Leaf)) {
        $parent = Split-Path $Path -Parent
        if ($parent -and -not (Test-Path $parent -PathType Container)) {
            New-Item -Path $parent -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
        New-Item -Path $Path -ItemType File -Force -ErrorAction Stop | Out-Null
    } elseif (-not $Append) {
        # clean the existing logfile if it exists
        Set-Content -Path $Path -Value $null
    }

    # return PowerShell provider path
    return Convert-Path $Path
}


<#
.SYNOPSIS
Function to get the log context from the caller.

.PARAMETER Caller
The caller function stack frame.
.PARAMETER ErrorStackTrace
The error stack trace.
#>
function Get-LogContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [System.Management.Automation.CallStackFrame]$Caller,

        [ValidateScript({ $_ -match '\sline\s(\d+)' })]
        [string]$ErrorStackTrace
    )

    begin {
        # get the function call timestamp
        $ts = Get-Date
    }

    process {
        # get the caller function name
        $callerFunction = $Caller.FunctionName -like '<ScriptBlock>*' ? $Caller.FunctionName : "$($Caller.FunctionName)()"
        # get the caller script name
        $callerScript = $Caller.ScriptName ? (Split-Path -Path $Caller.ScriptName -Leaf) : $Caller.Location
        # get the invocation and function line numbers
        if ($PSBoundParameters.ErrorStackTrace) {
            # get the line numbers from the error stack trace
            $stackSplit = $ErrorStackTrace.Split("`n")
            if ($callerFunction -like '<ScriptBlock>*') {
                $invocationLine = $stackSplit `
                    -match '\sline\s(\d+)' `
                    -replace '.*\sline\s(\d+).*', '$1' `
                | Select-Object -First 1
            } else {
                $funcLine = $stackSplit `
                    -match "$callerFunction,.*:\sline\s(\d+)" `
                    -replace '.*\sline\s(\d+).*', '$1'`
                | Select-Object -First 1
                $invocationLine = $stackSplit `
                    -notmatch "$callerFunction" `
                    -match '\sline\s(\d+)' `
                    -replace '.*\sline\s(\d+).*', '$1' `
                | Select-Object -First 1
            }
        } else {
            # get the line numbers from the caller
            if ($callerFunction -like '<ScriptBlock>*') {
                $invocationLine = $caller.ScriptLineNumber
            } else {
                $funcLine = $caller.ScriptLineNumber
                $invocationLine = $caller.InvocationInfo.ScriptLineNumber
            }
        }
    }

    end {
        # return the log context
        return [PSCustomObject]@{
            TimeStamp  = $ts
            Invocation = "${callerScript}:${invocationLine}"
            Function   = "${callerFunction}$($funcLine ? ":$funcLine" : '')"
            IsVerbose  = $Caller.InvocationInfo.BoundParameters.Verbose.IsPresent ?? $false
            IsDebug    = $Caller.InvocationInfo.BoundParameters.Debug.IsPresent ?? $false
        }
    }
}


<#
.SYNOPSIS
Function to get the log line.

.PARAMETER LogContext
The log context - output from Get-LogContext.
.PARAMETER Message
The message to log.
.PARAMETER Level
The level of the log message.
.PARAMETER LineType
The type of the log line to return.
#>
function Get-LogLine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$LogContext,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [string]$Level,

        [ValidateSet('Show', 'Write')]
        [string]$LineType
    )

    switch ($LineType) {
        Show {
            # format log level
            $lvlColor = switch ($Level) {
                'INFO' { "`e[94m" }
                'ERROR' { "`e[91m" }
                'WARNING' { "`e[93m" }
                'VERBOSE' { "`e[96m" }
                'DEBUG' { "`e[35m" }
            }

            # build the log line to show
            [string]::Join('|',
                "`e[32m$($LogContext.TimeStamp.ToString('yyyy-MM-dd HH:mm:ss'))`e[0m",
                "${lvlColor}${Level}`e[0m",
                "`e[90m$($LogContext.Invocation)`e[0m",
                "`e[90m$($LogContext.Function)`e[0m: $Message"
            )
        }
        Write {
            # build the log line to write
            [string]::Join('|',
                $LogContext.TimeStamp.ToString('yyyy-MM-dd HH:mm:ss.fff'),
                $Level,
                $LogContext.Invocation,
                $LogContext.Function,
                $Message
            )
        }
    }
}


<#
.SYNOPSIS
Functions to log messages to the console.

.PARAMETER Message
The message to log.
.PARAMETER Level
The level of the log message.
.PARAMETER ErrorStackTrace
The error stack trace for ERROR level messages.
The value can be obtained from $_.ScriptStackTrace property in the catch block.
.PARAMETER FailOnError
Switch, whether to throw an exception on ERROR level messages.
#>
function Show-LogContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Message')]
        [string]$Message,

        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ErrorRecord')]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [ValidateSet('INFO', 'ERROR', 'WARNING', 'VERBOSE', 'DEBUG')]
        [string]$Level = 'INFO',

        [string]$ErrorStackTrace,

        [switch]$FailOnError
    )

    begin {
        # check if error record was passed
        if ($PSCmdlet.ParameterSetName -eq 'ErrorRecord') {
            $Level = 'ERROR'
            $Message = "$ErrorRecord"
        }

        # *fail on error if specified
        if ($Level -eq 'ERROR' -and $PSBoundParameters.FailOnError) {
            throw $Message
        } else {
            # *capitalize the Type
            $Level = $Level.ToUpper()
            # *remove new lines from the message
            $Message = $Message -replace "`r?`n", ' '

            # *get the function caller context
            $callerParam = @{
                Caller = (Get-PSCallStack)[1]
            }
            if ($Level -eq 'ERROR') {
                if ($PSCmdlet.ParameterSetName -eq 'ErrorRecord') {
                    $callerParam.ErrorStackTrace = $ErrorRecord.ScriptStackTrace
                } elseif ($PSBoundParameters.ErrorStackTrace -match '\sline\s(\d+)') {
                    $callerParam.ErrorStackTrace = $PSBoundParameters.ErrorStackTrace
                }
            }
            $ctx = Get-LogContext @callerParam

            # *determine Debug/Verbose preference
            $isVerbose = $ctx.isVerbose -or $VerbosePreference -ge 'Continue'
            $isDebug = $ctx.isDebug -or $DebugPreference -ge 'Continue'
            # calculate if the message should be generated
            $ShowLog = if (($Level -eq 'VERBOSE' -and -not $isVerbose) -or ($Level -eq 'DEBUG' -and -not $isDebug)) {
                $false
            } else {
                $true
            }
        }
    }

    process {
        # calculate if the message should be generated
        if ($ShowLog) {
            $showLine = Get-LogLine -LogContext $ctx -Message $Message -Level $Level -LineType 'Show'
        }
    }

    end {
        if ($ShowLog) {
            Write-Host $showLine
        }
    }
}


<#
.SYNOPSIS
Function to log messages to a log file.

.PARAMETER Path
The path to the log file.
.PARAMETER Message
The message to log.
.PARAMETER Level
The level of the log message.
.PARAMETER ErrorStackTrace
The error stack trace.
.PARAMETER ShowLog
Switch, whether to show the log message in the console.
#>
function Write-LogContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Message')]
        [string]$Message,

        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ErrorRecord')]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [ValidateSet('INFO', 'ERROR', 'WARNING', 'VERBOSE', 'DEBUG')]
        [string]$Level = 'INFO',

        [string]$ErrorStackTrace,

        [ValidateScript({ $_ -match '\.log$' }, ErrorMessage = 'Specified file should have .log extension.')]
        [string]$Path,

        [switch]$ShowLog,

        [switch]$FailOnError
    )

    begin {
        # check if error record was passed
        if ($PSCmdlet.ParameterSetName -eq 'ErrorRecord') {
            $Level = 'ERROR'
            $Message = "$ErrorRecord"
        }


        # *fail on error if specified
        if ($Level -eq 'ERROR' -and $PSBoundParameters.FailOnError) {
            throw $Message
        } else {
            # *capitalize the Type
            $Level = $Level.ToUpper()
            # *remove new lines from the message
            $Message = $Message -replace "`r?`n", ' '

            # *create the log file if it doesn't exist
            if (-not (Test-Path $Path -PathType Leaf)) {
                Set-LogFile -Path $Path | Out-Null
            }

            # *get the function caller context
            $callerParam = @{
                Caller = (Get-PSCallStack)[1]
            }
            if ($Level -eq 'ERROR') {
                if ($PSCmdlet.ParameterSetName -eq 'ErrorRecord') {
                    $callerParam.ErrorStackTrace = $ErrorRecord.ScriptStackTrace
                } elseif ($PSBoundParameters.ErrorStackTrace -match '\sline\s(\d+)') {
                    $callerParam.ErrorStackTrace = $PSBoundParameters.ErrorStackTrace
                }
            }
            $ctx = Get-LogContext @callerParam

            # *determine Debug/Verbose preference
            if ($ShowLog) {
                $isVerbose = $ctx.isVerbose -or $VerbosePreference -ge 'Continue'
                $isDebug = $ctx.isDebug -or $DebugPreference -ge 'Continue'
                # calculate if the message should be displayed
                if (($Level -eq 'VERBOSE' -and -not $isVerbose) -or ($Level -eq 'DEBUG' -and -not $isDebug)) {
                    $ShowLog = $false
                }
            }
        }
    }

    process {
        # get the log line to write
        [string[]]$writeLine = Get-LogLine -LogContext $ctx -Message $Message -Level $Level -LineType 'Write'

        if ($ShowLog) {
            # get the log line to show
            $showLine = Get-LogLine -LogContext $ctx -Message $Message -Level $Level -LineType 'Show'
        }
    }

    end {
        # write the log line to the log file
        [System.IO.File]::AppendAllLines($Path, $writeLine)
        # show the log line in the console
        if ($ShowLog) {
            Write-Host $showLine
        }
    }
}
