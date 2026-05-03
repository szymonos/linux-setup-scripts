<#
.SYNOPSIS
Returns system information from /etc/os-release.
#>
function Get-SysInfo {
    # get os-release properties
    $osr = Get-DotEnv '/etc/os-release'
    # get cpu info
    $cpu = @{}
    (Select-String '^model name|^cpu cores|^siblings' '/proc/cpuinfo' -Raw | Select-Object -Unique).ForEach({
            $key, $value = $_.Split(':').Trim()
            $cpu[$key] = $value
        }
    )
    # calculate memory usage
    $mem = @{}
    (Select-String '^MemTotal|^MemAvailable' '/proc/meminfo' -Raw).ForEach({
            $key, $value = $_.Split(':')
            $mem[$key] = ($value -replace '[^0-9]') / 1MB
        }
    )
    $mem['MemUsed'] = $mem.MemTotal - $mem.MemAvailable

    # build system properties
    $sysProp = [ordered]@{
        UserHost = "`e[1;34m$(id -un)`e[0m@`e[1;34m$([System.IO.File]::ReadAllLines('/proc/sys/kernel/hostname'))`e[0m"
        OS       = "`e[1;37m$($osr.NAME) $($osr.BUILD_ID ?? $osr.VERSION ?? $osr.VERSION_ID) $(uname -m)`e[0m"
        Kernel   = uname -r
        Uptime   = "$(Get-Uptime)"
    }
    if ($env:WSL_DISTRO_NAME) { $sysProp['OS Host'] = 'Windows Subsystem for Linux' }
    if ($env:WSL_DISTRO_NAME) { $sysProp['WSL Distro'] = $env:WSL_DISTRO_NAME }
    if ($env:CONTAINER_ID) { $sysProp['DistroBox'] = $env:CONTAINER_ID }
    if ($env:TERM_PROGRAM) { $sysProp['Terminal'] = $env:TERM_PROGRAM }
    $sysProp['Shell'] = "PowerShell $($PSVersionTable.PSVersion)"
    $sysProp['CPU'] = "$($cpu['model name']) ($($cpu['cpu cores'])/$($cpu['siblings']))"
    $sysProp['Memory'] = '{0:n2} GiB / {1:n2} GiB ({2:p0})' -f $mem['MemUsed'], $mem['MemTotal'], ($mem['MemUsed'] / $mem['MemTotal'])
    if ($env:LANG) { $sysProp['Locale'] = $env:LANG }

    return [PSCustomObject]$sysProp
}

New-Alias -Name gsi -Value Get-SysInfo


<#
.SYNOPSIS
Run commands as root in PowerShell.
.DESCRIPTION
Wrapper for sudo command to handle defined aliases and one-liner functions.
#>
function Invoke-Sudo {
    for ($i = 0; $i -lt $args.Count; $i++) {
        # expand arguments alias/function definition
        if ($cmd = (Get-ChildItem Alias:/$($args[$i]) -ErrorAction SilentlyContinue || Get-ChildItem Function:/$($args[$i]) -ErrorAction SilentlyContinue).Definition.Where({ $_ -notmatch '\n' })) {
            $args[$i] = "$cmd".Trim().Replace('$input | ', '').Replace('& /usr/bin/env ', '').Replace(' @args', '')
        } elseif ($args[$i] -match ' ') {
            # quote arguments with spaces
            $args[$i] = "'$($args[$i])'"
        }
    }
    & /usr/bin/env bash -c "/usr/bin/env sudo $args"
}

Set-Alias -Name _ -Value Invoke-Sudo


<#
.SYNOPSIS
Run PowerShell cmdlets as root.
.DESCRIPTION
Wrapper for sudo command to execute PowerShell cmdlets and handle defined aliases and one-liner functions.
#>
function Invoke-SudoPS {
    for ($i = 0; $i -lt $args.Count; $i++) {
        # expand arguments alias/function definition
        if ($cmd = (Get-ChildItem Alias:/$($args[$i]) -ErrorAction SilentlyContinue || Get-ChildItem Function:/$($args[$i]) -ErrorAction SilentlyContinue).Definition.Where({ $_ -notmatch '\n' })) {
            $args[$i] = "$cmd".Trim().Replace('$input | ', '').Replace('& /usr/bin/env ', '').Replace(' @args', '')
        } elseif ($args[$i] -match ' ') {
            # quote arguments with spaces
            $args[$i] = "'$($args[$i])'"
        }
    }
    # run sudo command with resolved commands
    & /usr/bin/env sudo $params pwsh -NoProfile -NonInteractive -Command "$args"
}

Set-Alias -Name sps -Value Invoke-SudoPS


<#
.SYNOPSIS
Fix executable bit based on shebang presence.
.DESCRIPTION
Process specified directory, looking for bash and powershell scripts, and sets executable bit based on shebang presence.
#>
function Invoke-ExecutableBitFix {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Position = 0)]
        [ValidateNotNullorEmpty()]
        [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "`e[1;4m{0}`e[22;24m is not valid path")]
        [string]$Path = '.',

        [ValidateNotNullorEmpty()]
        [string[]]$ExtensionFilter = @('.ps1', '.py', '.sh')
    )

    # *adding executable bit in files with shebang
    (Get-ChildItem $Path -File -Recurse -Force).Where({
            $_.DirectoryName -notmatch '/\.(git|venv)\b' `
                -and ($_.Extension -in $ExtensionFilter -or -not $_.Extension) `
                -and $_.UnixMode -notmatch '^-rwx' `
                -and (Get-Content $_ -Head 1 | Select-String '^#!' -Quiet)
        }
    ).ForEach({
            Write-Host $_.FullName -ForegroundColor Green
            chmod +x $_.FullName
        }
    )

    # *removing executable bit from files without shebang
    (Get-ChildItem $Path -File -Recurse -Force).Where({
            $_.DirectoryName -notmatch '/\.(git|venv)\b' `
                -and ($_.Extension -in $ExtensionFilter -or -not $_.Extension) `
                -and $_.UnixMode -match '^-rwx' `
                -and (Get-Content $_ -Head 1 | Select-String '^#!' -NotMatch -Quiet)
        }
    ).ForEach({
            Write-Host $_.FullName
            chmod -x $_.FullName
        }
    )
}

Set-Alias -Name fixmod -Value Invoke-ExecutableBitFix
Set-Alias -Name fxmod -Value Invoke-ExecutableBitFix
