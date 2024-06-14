<#
.DESCRIPTION
Get list of WSL distros

.PARAMETER Online
Get list of available distros online.
.PARAMETER FromRegistry
Get list of installed distros from registry
#>
function Get-WslDistro {
    [CmdletBinding(DefaultParameterSetName = 'FromCommand')]
    param (
        [Parameter(ParameterSetName = 'Online')]
        [switch]$Online,

        [Parameter(ParameterSetName = 'FromRegistry')]
        [switch]$FromRegistry
    )

    begin {
        # check if the script is running on Windows
        if (-not $IsWindows) {
            Write-Warning 'Run the function on Windows!'
            break
        }

        if ($FromRegistry) {
            # specify list of properties to get from Windows registry lxss
            $prop = @(
                @{ Name = 'Name'; Expression = { $_.DistributionName } }
                'DefaultUid'
                @{ Name = 'Version'; Expression = { $_.Flags -lt 8 ? 1 : 2 } }
                'Flags'
                @{ Name = 'BasePath'; Expression = { $_.BasePath -replace '^\\\\\?\\' } }
                'PSPath'
            )
        } else {
            $distros = [Collections.Generic.List[PSCustomObject]]::new()
            $outputEncoding = [Console]::OutputEncoding
        }
    }

    process {
        if ($FromRegistry) {
            # get list of WSL distros from Windows Registry
            $distros = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss -ErrorAction SilentlyContinue `
            | ForEach-Object { $_ | Get-ItemProperty } `
            | Where-Object { $_.DistributionName -notmatch '^docker-desktop' } `
            | Select-Object $prop
        } else {
            # change console encoding to utf-16
            [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
            if ($Online) {
                # get list of online WSL distros
                [string[]]$result = wsl.exe --list --online | Where-Object { $_ }
                if (-not $?) {
                    Write-Error -Message 'Cannot get list of valid distributions.' -Category ConnectionError
                }
                # get distros header
                [string]$head = $result | Select-String 'NAME\s+FRIENDLY' -CaseSensitive | Select-Object -ExpandProperty Line
                # calculate header line index
                if ($head) {
                    $idx = $result.IndexOf($head)
                    $dataIdx = if ($idx -ge 0) {
                        $idx + 1
                    } else {
                        $result.Count - 1
                    }
                    # calculate header columns indexes
                    $nameIdx = $head.IndexOf('NAME')
                    $friendlyIdx = $head.IndexOf('FRIENDLY')
                    # add results to the distros list
                    for ($i = $dataIdx; $i -lt $result.Count; $i++) {
                        $distro = [PSCustomObject]@{
                            Name         = $result[$i].Substring($nameIdx, $friendlyIdx - $nameIdx).TrimEnd()
                            FriendlyName = $result[$i].Substring($friendlyIdx, $result[$i].Length - $friendlyIdx).TrimEnd()
                        }
                        $distros.Add($distro)
                    }
                }
            } else {
                # get list of installed locally WSL distros
                [string[]]$result = wsl.exe --list --verbose
                # get distros header
                [string]$head = $result | Select-String 'NAME\s+STATE\s+VERSION' -CaseSensitive | Select-Object -ExpandProperty Line
                # calculate header line index
                if ($head) {
                    $idx = $result.IndexOf($head)
                    $dataIdx = if ($idx -ge 0) {
                        $idx + 1
                    } else {
                        $result.Count - 1
                    }
                    # calculate header columns indexes
                    $nameIdx = $head.IndexOf('NAME')
                    $stateIdx = $head.IndexOf('STATE')
                    $versionIdx = $head.IndexOf('VERSION')
                    # add results to the distros list
                    for ($i = $dataIdx; $i -lt $result.Count; $i++) {
                        $distro = [PSCustomObject]@{
                            Name    = $result[$i].Substring($nameIdx, $stateIdx - $nameIdx).TrimEnd()
                            State   = $result[$i].Substring($stateIdx, $versionIdx - $stateIdx).TrimEnd()
                            Version = $result[$i].Substring($versionIdx, $result[$i].Length - $versionIdx).TrimEnd()
                        }
                        $distros.Add($distro)
                    }
                }
            }
            [Console]::OutputEncoding = $outputEncoding
        }
    }

    end {
        return $distros
    }
}

<#
.DESCRIPTION
Sets wsl.conf in specified WSL distro from provided ordered dictionary.
.LINK
https://learn.microsoft.com/en-us/windows/wsl/wsl-config#wslconf

.PARAMETER Distro
Name of the WSL distro to set wsl.conf.
.PARAMETER ConfDict
Input ordered dictionary consisting configuration to be saved into wsl.conf.
.PARAMETER ShowConf
Print current wsl.conf after setting the configuration.
#>
function Set-WslConf {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Distro,

        [System.Collections.Specialized.OrderedDictionary]$ConfDict,

        [switch]$ShowConf
    )

    begin {
        Write-Verbose 'setting wsl.conf'
        $wslConf = wsl.exe -d $Distro --exec cat /etc/wsl.conf 2>$null | ConvertFrom-Cfg
        if (-not ($? -or $ConfDict)) {
            break
        }
    }

    process {
        if ($wslConf) {
            foreach ($key in $ConfDict.Keys) {
                if ($wslConf.$key) {
                    foreach ($option in $ConfDict.$key.Keys) {
                        $wslConf.$key.$option = $ConfDict.$key.$option
                    }
                } else {
                    $wslConf.$key = $ConfDict.$key
                }
            }
        } else {
            $wslConf = $ConfDict
        }
        $wslConfStr = ConvertTo-Cfg -OrderedDict $wslConf -LineFeed
        if ($wslConfStr) {
            # save wsl.conf file
            $cmd = "rm -f /etc/wsl.conf || true && echo '$wslConfStr' >/etc/wsl.conf"
            wsl.exe -d $Distro --user root --exec sh -c $cmd
        }
    }

    end {
        if ($ShowConf) {
            Write-Host "wsl.conf`n" -ForegroundColor Magenta
            wsl.exe -d $Distro --exec cat /etc/wsl.conf | Write-Host
        } else {
            Write-Verbose 'Saved configuration in /etc/wsl.conf.'
        }
    }
}
