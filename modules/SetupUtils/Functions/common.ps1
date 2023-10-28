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
                $content.ForEach({ $cfgList.Add( $_ ) })
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
        switch -Regex ($cfgList) {
            '^\s*\[(.+)\]' {
                # Section
                $section = $matches[1]
                $cfg[$section] = [ordered]@{}
                $CommentCount = 0
            }
            '^\s*([#;].*)' {
                # Comment
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = 'Comment' + $CommentCount
                $cfg[$section][$name] = $value
            }
            '^\s*(\w+)\s*=(.*)' {
                # Key
                $name, $value = $matches[1..2]
                $cfg[$section][$name] = $value.Trim()
            }
        }
        # return configuration dictionary
        return $cfg
    }
}

function ConvertTo-Cfg {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [System.Collections.Specialized.OrderedDictionary]$OrderedDict,

        [string]$Path,

        [switch]$LineFeed,

        [switch]$Force
    )

    $ErrorActionPreference = 'Stop'

    if (-not $Force -and (Test-Path $Path)) {
        Write-Error "$Path destination already exists."
    }

    $builder = [System.Text.StringBuilder]::new()
    foreach ($enum in $OrderedDict.GetEnumerator()) {
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

        [switch]$FolderFromBase
    )

    begin {
        # get list of scripts in the specified directory
        $scripts = Get-ChildItem $Path -File -Force | Where-Object {
            $_.Extension -in $ExtensionFilter -and $_.FullName -notin (Resolve-Path $Exclude -ErrorAction SilentlyContinue).Path
        }
        # instantiate generic list to store example script(s) name(s)
        $lst = [Collections.Generic.List[string]]::new()
        if ($scripts) {
            # get git root
            $gitRoot = git rev-parse --show-toplevel
            # add the console folder to .gitignored if necessary
            if (-not (Select-String '\bconsole\b' "$gitRoot/.gitignore" -Quiet)) {
                [IO.File]::AppendAllLines("$gitRoot/.gitignore", [string[]]'/console/')
            }
            # determine and create example folder to put example scripts in
            $exampleDir = if ($FolderFromBase) {
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
                '.py'  = '(?<=^(#.*?\n)?"""\n)((?!""")[\s\S])*(?=\n""")'
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
                $exampleFile = [IO.Path]::Combine($exampleDir, $fileName)
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
                # save the example script
                [IO.File]::WriteAllText($exampleFile, $builder.ToString())
                # add example script path to the list
                $lst.Add([IO.Path]::GetRelativePath($gitRoot, $exampleFile))
            }
        }
    }

    end {
        # print list of saved file paths
        foreach ($example in $lst) {
            Write-Host $example
        }
    }
}
