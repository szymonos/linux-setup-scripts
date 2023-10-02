#Requires -PSEdition Core
<#
.SYNOPSIS
Script synopsis.
.EXAMPLE
wsl/wsl_distro_get.ps1
wsl/wsl_distro_get.ps1 -FromRegistry
wsl/wsl_distro_get.ps1 -Online
#>
[CmdletBinding()]
param (
    [switch]$Online,

    [switch]$FromRegistry
)

begin {
    $ErrorActionPreference = 'Stop'

    # check if the script is running on Windows
    if (-not $IsWindows) {
        Write-Warning 'Run the script on Windows!'
        exit 0
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
