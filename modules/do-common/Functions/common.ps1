<#
.SYNOPSIS
Convert text from base64 string.

.PARAMETER InputObject
Base64 encoded string to be converted.
#>
function ConvertFrom-Base64 {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$InputObject
    )

    process {
        return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($InputObject))
    }
}


<#
.SYNOPSIS
Convert text to base64 string.

.PARAMETER InputObject
Text to be converted to base64 string.
$InputObject = (Get-AzAccessToken -ResourceUrl 'https://cognitiveservices.azure.com').Token | ConvertFrom-SecureString -AsPlainText
#>
function ConvertTo-Base64 {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$InputObject
    )

    process {
        return [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($InputObject))
    }
}


<#
.SYNOPSIS
Convert text from base64url encoded string.

.PARAMETER InputObject
Base64url encoded string to be converted.
#>
function ConvertFrom-Base64Url {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$InputObject
    )

    process {
        $base64 = $InputObject.Replace('-', '+').Replace('_', '/')
        switch ($base64.Length % 4) {
            2 { $base64 += '==' }
            3 { $base64 += '=' }
            0 { }
            default { throw 'Invalid base64url string length' }
        }
        return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($base64))
    }
}


<#
.SYNOPSIS
Decode JWT token.

.PARAMETER InputObject
JWT token string to be converted.
#>
function ConvertFrom-JWT {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$InputObject
    )

    process {
        # get JWT header and payload
        $header, $payload = $InputObject.Split('.')[0..1].ForEach({
                try { $_ | ConvertFrom-Base64Url | ConvertFrom-Json -AsHashtable } catch { @{} }
            }
        )

        # convert iat, nbf, exp to DateTime
        if ($payload.iat) {
            $payload.iat = [DateTimeOffset]::FromUnixTimeSeconds($payload.iat).DateTime
        }
        if ($payload.nbf) {
            $payload.nbf = [DateTimeOffset]::FromUnixTimeSeconds($payload.nbf).DateTime
        }
        if ($payload.exp) {
            $payload.exp = [DateTimeOffset]::FromUnixTimeSeconds($payload.exp).DateTime
        }

        # merge header and payload into a single ordered dictionary
        $merged = [ordered]@{}
        $header.GetEnumerator().ForEach({ $merged[$_.Key] = $_.Value })
        $payload.GetEnumerator().ForEach({ $merged[$_.Key] = $_.Value })
    }

    end {
        # return merged JWT claims
        return [PSCustomObject]$merged
    }
}


<#
.SYNOPSIS
Converts configuration file to an ordered dictionary.

.PARAMETER Path
Path to the configuration file.
.PARAMETER InputObject
Configuration file content passed to the cmdlet through pipeline.
#>
function ConvertFrom-Cfg {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'FromFile')]
        [ValidateScript({ Test-Path $_ -PathType Leaf }, ErrorMessage = "'{0}' is not a valid file path.")]
        [string]$Path,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromPipeline')]
        [object]$InputObject
    )

    begin {
        # instantiate generic list for the configuration content
        $cfgList = [System.Collections.Generic.List[string]]::new()
    }

    process {
        switch ($PsCmdlet.ParameterSetName) {
            FromFile {
                $content = [System.IO.File]::ReadAllLines((Resolve-Path $Path))
                $content.ForEach({ $cfgList.Add($_) })
            }
            FromPipeline {
                if ($InputObject) {
                    $cfgList.Add( $InputObject )
                }
            }
        }
    }

    end {
        # build an ordered dictionary from cfg object
        $cfg = [ordered]@{}
        $header = @()
        $section = $null
        $CommentCount = 0

        foreach ($line in $cfgList) {
            if (-not $section -and $line -match '^\s*\[(.+)\]') {
                # first section encountered; store section header
                $section = $matches[1]
                $cfg[$section] = [ordered]@{}
                continue
            }
            if (-not $section) {
                # before any section header, preserve header comments (only if they are comments)
                if ($line -match '^\s*[#;].*') {
                    $header += $line
                }
                continue
            }
            if ($line -match '^\s*\[(.+)\]') {
                # new section header encountered
                $section = $matches[1]
                $cfg[$section] = [ordered]@{}
                $CommentCount = 0
                continue
            }
            elseif ($line -match '^\s*([#;].*)') {
                # Comment within section
                $CommentCount++
                $name = "Comment$CommentCount"
                $cfg[$section][$name] = $matches[1]
                continue
            }
            elseif ($line -match '^\s*(\w+)\s*=(.*)') {
                # Key value pair
                $name, $value = $matches[1..2]
                $cfg[$section][$name] = $value.Trim()
                continue
            }
        }
        # store header in special key if any header comments were collected
        if ($header.Count -gt 0) {
            $cfg['__header__'] = $header -join "`n"
        }
        return $cfg
    }
}


<#
.SYNOPSIS
Converts ordered dictionary to a configuration file/string.

.PARAMETER OrderedDict
Input hashtable consisting a content to be converted to a configuration file.
.PARAMETER Path
Path to the configuration file to save the content to.
Without providing the parameter, prints the configuration string.
.PARAMETER LineFeed
Output the configuration file using LF EOF.
.PARAMETER Force
Force overwrite the destination file.
#>
function ConvertTo-Cfg {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [System.Collections.IDictionary]$OrderedDict,

        [string]$Path,

        [switch]$LineFeed,

        [switch]$Force
    )

    $ErrorActionPreference = 'Stop'

    if (-not $Force -and (Test-Path $Path)) {
        Write-Error "$Path destination already exists."
    }

    $builder = [System.Text.StringBuilder]::new()
    # Restore header comments at the beginning if they exist
    if ($OrderedDict.Contains("__header__")) {
        $builder.AppendLine($OrderedDict['__header__']) | Out-Null
    }
    foreach ($enum in $OrderedDict.GetEnumerator()) {
        if ($enum.Key -eq '__header__') { continue }
        $section = $enum.Key
        $builder.AppendLine("`n[$section]") | Out-Null
        foreach ($cfg in $enum.Value.GetEnumerator()) {
            if ($cfg.Key -like 'Comment*') {
                $builder.AppendLine($cfg.Value) | Out-Null
            } else {
                $builder.AppendLine([string]::Join(' = ', $cfg.Key, $cfg.Value)) | Out-Null
            }
        }
    }

    $content = $builder.ToString().Trim()
    if ($LineFeed) {
        $content = $content.Replace("`r`n", "`n")
    }
    if ($Path) {
        Set-Content -Value $content -Path $Path
    } else {
        $content
    }
}


<#
.SYNOPSIS
Convert all files in a directory to UTF8 and change EOLs from CRLF to LF.

.PARAMETER Path
Directory to convert all files from.
#>
function ConvertTo-UTF8LF {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "'{0}' is not a valid folder path.")]
        [string]$Path = '.'
    )

    begin {
        $encoding = [System.Text.UTF8Encoding]::new($false)
        $fileCnt = 0
    }

    process {
        # get list of files to process, excluding .git subdirectory
        $files = (Get-ChildItem $Path -File -Force -Recurse).Where({ $_.DirectoryName -notmatch '(/|\\)\.git\b' })
        # convert files
        foreach ($file in $files) {
            $content = [System.IO.File]::ReadAllText($file).Replace("`r`n", "`n")
            [System.IO.File]::WriteAllText($file, $content, $encoding)
        }
        $fileCnt += $files.Count
    }

    end {
        Write-Host "Converted $fileCnt file(s)."
    }
}


<#
.SYNOPSIS
Obfuscate input string by shifting letters in string by 13 positions.
To "decode" obfuscated text you should just run the function again as there are 26 base letters.

.PARAMETER Text
Input string to be obfuscated.
#>
function Convert-ROT13 {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Text
    )

    begin {
        $strLen = $Text.Length
        $rot13 = [char[]]::new($strLen)
    }

    process {
        for ($i = 0; $i -lt $strLen; $i++) {
            [char]$c = $Text[$i]
            $rot13[$i] = if ([char]::IsLetter($c)) {
                [char]$base = [char]::IsUpper($c) ? 'A' : 'a'
                [char](($c - $base + 13) % 26 + $base)
            } else {
                $c
            }
        }
    }

    end {
        return [string]::Join('', $rot13)
    }
}


<#
.SYNOPSIS
Converts PowerShell object to json and prints it formatted if jq is available.

.PARAMETER InputObject
Input object to be converted to json.
#>
function ConvertTo-JsonFormatted {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject
    )

    begin {
        $jq = (Get-Command 'jq' -CommandType Application -ErrorAction SilentlyContinue) ? $true : $false
    }

    process {
        if ($jq) {
            $InputObject | ConvertTo-Json -Depth 99 | jq
        } else {
            $InputObject | ConvertTo-Json -Depth 99
        }
    }
}

Set-Alias -Name json -Value ConvertTo-JsonFormatted


<#
.SYNOPSIS
Get item index(es) or value(s) of the provided array from selection menu.

.PARAMETER Array
Array of strings to get the selection menu.
.PARAMETER Message
Optional menu header to display.
.PARAMETER Value
Flag to return value(s) instead of index(es).
.PARAMETER List
Flag to choose from selection list instead of single value.
.PARAMETER AllowNoSelection
Allow empty selection, otherwise keep prompting for input.
#>
function Get-ArrayIndexMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [object[]]$Array,

        [Parameter(Position = 1)]
        [string]$Message,

        [switch]$Value,

        [switch]$List,

        [switch]$AllowNoSelection
    )
    begin {
        # instantiate generic list to store the input array
        $lst = [System.Collections.Generic.List[object]]::new()
    }

    process {
        # determine if the input array has multiple properties
        if (-not $arrayType) {
            $arrayType = ($Array | Select-Object * | Get-Member -MemberType NoteProperty).Count -gt 1 ? 'object' : 'string'
        }
        # add input array items to the generic list
        $Array.ForEach({ $lst.Add($_) })
    }

    end {
        # return if the input array has less then 2 items
        if ($lst.Count -eq 0) {
            return
        } elseif ($lst.Count -eq 1) {
            $indexes = [System.Collections.Generic.HashSet[int]]::new([int[]]0)
        } else {
            # create selection menu
            $menu = switch ($arrayType) {
                object {
                    $i = 0
                    $lst `
                    | Select-Object @{ N = '#'; E = { $lst.IndexOf($_) } }, @{ N = ' '; E = { '-' } }, * `
                    | Format-Table -AutoSize `
                    | Out-String -Stream `
                    | ForEach-Object { $i -lt 3 ? "`e[1;92m$_`e[0m" : $_; $i++ } `
                    | Out-String
                    continue
                }
                string {
                    $lst.ToArray().ForEach({ [PSCustomObject]@{ '#' = $lst.IndexOf($_); ' ' = '-'; 'V' = $_ } }) `
                    | Format-Table -AutoSize -HideTableHeaders `
                    | Out-String
                    continue
                }
            }

            # create prompt message
            if (-not $Message) {
                $Message = $List ? 'Enter comma/space separated selection list' : 'Enter selection'
            }
            $msg = "`n`e[4m$Message`e[0m:`n$menu"

            # read and validate input
            do {
                # instantiate indexes collection
                $indexes = [System.Collections.Generic.HashSet[int]]::new()
                # prompt for a selection from the input array
                (Read-Host -Prompt $msg).Split([char[]]@(' ', ','), [StringSplitOptions]::RemoveEmptyEntries).ForEach({
                        try { $indexes.Add($_) | Out-Null } catch { }
                    }
                )
                # calculate stats for returned indexes
                $stat = $indexes | Measure-Object -Minimum -Maximum
                # evaluate if the Read-Host input is valid
                $continue = if ($stat.Count -eq 0) {
                    $AllowNoSelection
                } elseif ($stat.Count -eq 1 -or ($List -and $stat.Count -gt 0)) {
                    $stat.Minimum -ge 0 -and $stat.Maximum -lt $lst.Count
                } else {
                    $false
                }
            } until ($continue)
        }

        # return result
        return $Value ? $indexes.ForEach({ $lst[$_] }) : [int[]]$indexes.ForEach({ $_ })
    }
}


<#
.SYNOPSIS
Get the aliases for any cmdlet.

.PARAMETER CmdletName
Name of the cmdlet to get aliases for.
#>
function Get-CmdletAlias {
    [CmdletBinding()]
    param (
        [string]$CmdletName
    )

    Get-Alias | `
        Where-Object -FilterScript { $_.Definition -match $CmdletName } | `
        Sort-Object -Property Definition, Name | `
        Select-Object -Property Definition, Name
}

Set-Alias -Name alias -Value Get-CmdletAlias


<#
.SYNOPSIS
Get environment variables from env file.

.PARAMETER Path
Path to the env file.
#>
function Get-DotEnv {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Path = '.env'
    )

    begin {
        # load content of the env file
        try {
            $envContent = Get-Content -Path $Path -ErrorAction Stop
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Warning "File does not exist ($Path)."
            return
        } catch {
            Write-Verbose $_.Exception.GetType().FullName
            Write-Error $_
        }
        # instantiate hashtable to store variables
        $envHash = [ordered]@{}
    }

    process {
        $envContent | ForEach-Object {
            if ($_ -match '^([a-zA-Z_]+[a-zA-Z0-9_]*)=(.+)$') {
                $envHash[$matches[1]] = $matches[2].Trim().Trim("'|`"")
            }
        }
    }

    end {
        return $envHash
    }
}


<#
.SYNOPSIS
Set environment variables from env file.

.PARAMETER Path
Path to the env file.
#>
function Set-DotEnv {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Path = '.env'
    )

    $envHash = Get-DotEnv $Path

    foreach ($key in $envHash.Keys) {
        [Environment]::SetEnvironmentVariable($key, $envHash[$key])
    }

    if ($envHash) {
        Write-Verbose "Environmet variables set: $($envHash.Keys | Join-String -Separator ', ')"
    }
}

Set-Alias -Name src -Value Set-DotEnv


<#
.SYNOPSIS
Formats log message.

.PARAMETER Message
Log message text to be printed.
.PARAMETER Level
Log level.
#>
function Get-LogMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL')]
        [string]$Level = 'INFO'
    )

    # calculate message color
    $msgColor = switch ($Level) {
        DEBUG { "`e[36m" }
        INFO { "`e[34m" }
        WARNING { "`e[33m" }
        ERROR { "`e[31m" }
        CRITICAL { "`e[91m" }
    }
    # calculate message information
    $position = "$(Split-Path $MyInvocation.ScriptName -Leaf):$($MyInvocation.ScriptLineNumber)"
    $ts = (Get-Date).ToString('s').Replace('T', ' ')

    # print log message
    $msg = "`e[32m{0}`e[0m|`e[30m{1}`e[0m|{2} - $msgColor{3}`e[0m" -f $ts, $Level.ToUpper(), $position, $Message
    Write-Host $msg
}


<#
.SYNOPSIS
Get PSReadLine history.

.PARAMETER Pattern
Regex pattern to filter history entries.
.PARAMETER Last
Number of last matching entries to return. Default is 30.
.PARAMETER First
Number of first matching entries to return.
.PARAMETER Unique
Return sorted, unique matching entries.

.EXAMPLE
Get-PSReadLineHistory -Pattern 'Connect-Az.*' -Last 10
# get last 10 PSReadLine history entries matching 'Connect-Az.*' pattern

.EXAMPLE
Get-PSReadLineHistory 'Connect-Az.*' 10
# omit parameters as Pattern is mandatory and Last is default

.EXAMPLE
Get-PSReadLineHistory -Pattern 'git' -First 5
# get first 5 PSReadLine history entries matching 'git' pattern
#>
function Get-PSReadLineHistory {
    [CmdletBinding(DefaultParameterSetName = 'last')]
    param (
        [Parameter(ValueFromPipeline, Position = 0)]
        [string]$Pattern,

        [Parameter(Position = 1, ParameterSetName = 'last')]
        [int]$Last = 30,

        [Parameter(ParameterSetName = 'first')]
        [int]$First,

        [switch]$Unique
    )

    begin {
        # determine limit for the matching results
        $limit = $First ? $First : $Last

        # get PSReadLine history file path
        $historyPath = (Get-PSReadLineOption).HistorySavePath

        # read and optionally reverse history using LINQ for efficiency
        if ($First) {
            $history = [System.IO.File]::ReadLines($historyPath)
        } else {
            $history = [System.Linq.Enumerable]::Reverse(
                [System.IO.File]::ReadLines($historyPath)
            )
        }
    }

    process {
        # filter matches
        $results = $history -match "(?<!^(Get-PSReadLineHistory|ghi|pshistory) )$Pattern" | Select-Object -First $limit
    }

    end {
        if ($PSBoundParameters.Unique) {
            $results | Sort-Object -Unique
        } else {
            $results
        }
    }
}

Set-Alias -Name pshistory -Value Get-PSReadLineHistory
Set-Alias -Name ghi -Value Get-PSReadLineHistory


<#
.SYNOPSIS
Print timespan in human readable format.

.PARAMETER TimeSpan
Timespan to be formatted as human redable duration.
#>
function Format-Duration {
    [CmdletBinding()]
    param (
        [timespan]$TimeSpan
    )

    switch ($TimeSpan) {
        { $_.TotalMilliseconds -gt 0 -and $_.TotalMilliseconds -lt 10 } { '{0:N2}ms' -f $_.TotalMilliseconds; continue }
        { $_.TotalMilliseconds -ge 10 -and $_.TotalMilliseconds -lt 100 } { '{0:N1}ms' -f $_.TotalMilliseconds; continue }
        { $_.TotalMilliseconds -ge 100 -and $_.TotalMilliseconds -lt 1000 } { '{0:N0}ms' -f $_.TotalMilliseconds; continue }
        { $_.TotalSeconds -ge 1 -and $_.TotalSeconds -lt 10 } { '{0:N3}s' -f $_.TotalSeconds; continue }
        { $_.TotalSeconds -ge 10 -and $_.TotalSeconds -lt 100 } { '{0:N2}s' -f $_.TotalSeconds; continue }
        { $_.TotalSeconds -ge 100 -and $_.TotalHours -le 1 } { $_.ToString('mm\:ss\.ff'); continue }
        { $_.TotalHours -ge 1 -and $_.TotalDays -le 1 } { $_.ToString('hh\:mm\:ss'); continue }
        { $_.TotalDays -ge 1 } { "$($_.Days * 24 + $_.Hours):$($_.ToString('mm\:ss'))"; continue }
        default { '0ms' }
    }
}


<#
.SYNOPSIS
Retry executing command if fails on HttpRequestException.
.PARAMETER Command
Script block of commands to execute.
.PARAMETER MaxRetries
Maximum number of retries to rerun the script block.
#>
function Invoke-CommandRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = 'The command to be invoked.')]
        [scriptblock]$Command,

        [Parameter(HelpMessage = 'The number of retries the command should be invoked.')]
        [int]$MaxRetries = 10
    )

    Set-Variable -Name retryCount -Value 0
    do {
        try {
            Invoke-Command -ScriptBlock $Command
            $exit = $true
        } catch [System.IO.IOException], [System.Net.Http.HttpRequestException] {
            if ($_.Exception.TargetSite.Name -eq 'MoveNext') {
                if ($_.ErrorDetails) {
                    Write-Verbose $_.ErrorDetails.Message
                } else {
                    Write-Verbose $_.Exception.Message
                }
                Write-Host "`nRetrying..."
            } else {
                Write-Verbose $_.Exception.GetType().FullName
                Write-Error $_
            }
        } catch [System.AggregateException] {
            if ($_.Exception.InnerException.GetType().Name -eq 'HttpRequestException') {
                Write-Verbose $_.Exception.InnerException.Message
                Write-Host "`nRetrying..."
            } else {
                Write-Verbose $_.Exception.InnerException.GetType().FullName
                Write-Error $_
            }
        } catch {
            Write-Verbose $_.Exception.GetType().FullName
            Write-Error $_
        }
        $retryCount++
        if ($retryCount -eq $MaxRetries) {
            $exit = $true
        }
    } until ($exit)
}


<#
.SYNOPSIS
Save examples from PowerShell, Python, shell scripts to the console folder.
Function ignores script_examples_save.ps1 script that can be used to invoke it
and lines containing ExampleScriptSave keyword.

.PARAMETER Path
Path to the file/folder to save the examples from.
.PARAMETER ExtensionFilter
Scripts extension filter.
.PARAMETER Exclude
List of file relative or full paths to be excluded from processing.
.PARAMETER FolderFromBase
Save example script in the folder of the base script.
.PARAMETER Force
Force ovewriting target file if exists.
.PARAMETER WriteOutput
Write output to the success [1] stream instead of the information [6] one.

.EXAMPLE
# :save example scripts from scripts in the current folder
Invoke-ExampleScriptSave
Invoke-ExampleScriptSave -Force
Invoke-ExampleScriptSave -FolderFromBase
# :save example script from scripts in the specified path
$Path = 'path_to_script_or_folder'
Invoke-ExampleScriptSave $Path
Invoke-ExampleScriptSave $Path -Force
Invoke-ExampleScriptSave $Path -WriteOutput
Invoke-ExampleScriptSave $Path -FolderFromBase
#>
function Invoke-ExampleScriptSave {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "'{0}' is not a valid path.")]
        [string]$Path = '.',

        [ValidateScript({ $_.ForEach({ $_ -in @('.ps1', '.py', '.sh') }) -notcontains $false },
            ErrorMessage = 'Wrong extensions provided. Valid values: .ps1, .py, .sh')]
        [string[]]$ExtensionFilter = @('.ps1', '.py', '.sh'),

        [ValidateNotNullOrEmpty()]
        [string[]]$Exclude = '.',

        [switch]$FolderFromBase,

        [switch]$Force,

        [switch]$WriteOutput
    )

    begin {
        # get list of scripts in the specified directory
        $scripts = Get-ChildItem $Path -File -Force | Where-Object {
            $_.Extension -in $ExtensionFilter -and $_.FullName -notin (Resolve-Path $Exclude -ErrorAction SilentlyContinue).Path
        }
        # instantiate generic list to store example script(s) name(s)
        $lst = [Collections.Generic.List[hashtable]]::new()
        if ($scripts) {
            # get git root
            $gitRoot = git rev-parse --show-toplevel
            # add the console folder to .gitignored if necessary
            if (-not (Select-String '\bconsole\b' "$gitRoot/.gitignore" -Quiet)) {
                [IO.File]::AppendAllLines("$gitRoot/.gitignore", [string[]]'/console/')
            }
            # determine and create example folder to put example scripts in
            $exampleDir = if ($PSBoundParameters.FolderFromBase) {
                [IO.Path]::Combine($gitRoot, 'console', $scripts[0].Directory.Name)
            } else {
                [IO.Path]::Combine($gitRoot, 'console')
            }
            # create example dir if not exists
            if (-not (Test-Path $exampleDir -PathType Container)) {
                New-Item $exampleDir -ItemType Directory | Out-Null
            }
            # script's initial comment regex pattern
            $pattern = @{
                '.ps1' = '(?s)(?<=\n\.EXAMPLE\n).*?(?=(\n#>|\n\.[A-Z]))'
                '.sh'  = "(?s)(?<=\n: '\n).*?(?=\n'\n)"
                '.py'  = '(?<=^(#.*?\n)?"""\n)((?!""")[\s\S])*?(?=\n("""|# \:save))'
            }
        } else {
            return
        }
    }

    process {
        foreach ($script in $scripts) {
            $content = [IO.File]::ReadAllText($script)
            # get script examples
            $example = [regex]::Matches($content, $pattern[$script.Extension]).Value
            if ($example) {
                # get PowerShell parameters descriptions
                if ($script.Extension -eq '.ps1') {
                    $synopsis = [regex]::Matches($content, '(?s)(?<=\n)\.SYNOPSIS\n(.*?)(?=(\n\.[A-Z]+( \w+)?\n|#>))').Value
                    $param = [regex]::Matches($content, '(?s)(?<=\n)\.PARAMETER \w+\n(.*?)(?=(\n\.[A-Z]+\n|#>))').Value
                } else {
                    # quote sentences and links
                    $example = $example `
                        -replace '(^|\n)([A-Z].*\.)(\n|$)', '$1# $2$3' `
                        -replace '(^|\n)(http.*)(\n|$)', '$1# $2$3'
                    # clean param variable
                    $synopsis = $null
                    $param = $null
                }
                # calculate example file path
                $fileName = $script.Extension -eq '.py' ? "$($script.BaseName)_py.ps1" : $script.Name
                # create hashtable that will store the example script path and information if it was saved
                $lstItem = @{ path = [IO.Path]::Combine($exampleDir, $fileName) }
                # build content string
                $builder = [System.Text.StringBuilder]::new()
                if ($synopsis -or $param) {
                    $builder.AppendLine('<#') | Out-Null
                    if ($synopsis) { $builder.AppendLine($synopsis.Trim()) | Out-Null }
                    if ($param) { $builder.AppendLine($synopsis ? "`n$($param.Trim())" : $param.Trim()) | Out-Null }
                    $builder.AppendLine('#>') | Out-Null
                    if ($example) { $builder.AppendLine('') | Out-Null }
                }
                if ($example) {
                    $example.Trim().Split("`n") | Select-String -NotMatch 'ExampleScriptSave' | ForEach-Object {
                        $builder.AppendLine($_) | Out-Null
                    }
                }
                if (-not $PSBoundParameters.Force -and (Test-Path $lstItem.path)) {
                    $lstItem.saved = $false
                } else {
                    # save the example script
                    [IO.File]::WriteAllText($lstItem.path, $builder.ToString())
                    $lstItem.saved = $true
                }
                # add item to the list
                $lst.Add($lstItem)
            }
        }
    }

    end {
        # print list of saved file paths
        foreach ($item in $lst) {
            if ($WriteOutput) {
                return $item.path
            } else {
                $relPath = ($item.path).Replace($HOME, '~')
                if ($item.saved) {
                    Write-Host "`e[4;94m$relPath`e[0m"
                } else {
                    Write-Host "`e[4;96m$relPath`e[0m"
                }
            }
        }
    }
}

Set-Alias -Name egsave -Value Invoke-ExampleScriptSave


<#
.SYNOPSIS
Generate a random string.

.PARAMETER Length
Length of the password to be generated.
.PARAMETER Complexity
Set of characters to use for generating password:
- U: upper case characters
- L: lower case characters
- N: numbers
- S: symbols
.PARAMETER Exclude
List of characters to be excluded.
#>
function New-Password {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Int]$Length = 8,

        [Char[]]$Complexity = 'ULNS',

        [Char[]]$Exclude
    )
    $AllTokens = @();
    $Chars = @();
    $TokenSets = @{
        UpperCase = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        LowerCase = [Char[]]'abcdefghijklmnopqrstuvwxyz'
        Numbers   = [Char[]]'0123456789'
        Symbols   = [Char[]]'!#%&*+-<>@^_|~'
    }
    $TokenSets.Keys | Where-Object { $Complexity -contains $_[0] } | ForEach-Object {
        $TokenSet = $TokenSets.$_ | Where-Object { $Exclude -cnotcontains $_ } | ForEach-Object { $_ }
        if ($_[0] -cle 'Z') {
            $Chars += $TokenSet | Get-Random
        }
        $AllTokens += $TokenSet
    }
    while ($Chars.Count -lt $Length) {
        $Chars += $AllTokens | Get-Random
    } -join ($Chars | Sort-Object { Get-Random })
}


<#
.SYNOPSIS
Show specified properties of the object.

.PARAMETER Object
Object to be showed.
.PARAMETER TypeName
Array of properties system types to be shown (System.String, System.Datetime, ...).
.PARAMETER MemberType
Array of properties member types to be shown (Property, AliasProperty, ...).
.PARAMETER Strip
Switch whether to strip properties without value.
#>
function Show-Object {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[object]])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [object]$Object,

        [string[]]$TypeName,

        [string[]]$MemberType,

        [switch]$Strip
    )

    process {
        [string[]]$prop = $Object.PSObject.Properties.Where({
                ($TypeName ? $_.TypeNameOfValue -in $TypeName : $true) -and
                ($MemberType ? $_.MemberType -in $MemberType : $true) -and
                ($Strip ? -not [string]::IsNullOrEmpty($_.Value) : $true)
            }
        ).Name
        $Object | Select-Object $prop
    }
}


<#
.SYNOPSIS
Check if PowerShell runs elevated.
#>
function Test-IsAdmin {
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    process {
        $isAdmin = if ($IsWindows) {
            ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
        } else {
            ((id -u) -eq 0) ? $true : $false
        }
    }

    end {
        return $isAdmin
    }
}
