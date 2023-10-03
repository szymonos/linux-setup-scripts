#Requires -PSEdition Core
<#
.SYNOPSIS
Fix WSL network configuration for use with VPN interface.

.PARAMETER Distro
Name of the WSL distro to set up. If not specified, script will update all existing distros.
.PARAMETER InterfaceDescription
Description of the VPN interface.
.PARAMETER DisableSwap
Flag whether to disable swap in WSL.
.PARAMETER Shutdown
Flag whether to shutdown specified distro.
.PARAMETER Revert
Revert changes and set generateResolvConf to 'true'.
.PARAMETER ShowConf
Print current configuration after changes.

.EXAMPLE
$Distro = 'Ubuntu'
wsl/wsl_network_fix.ps1 $Distro
wsl/wsl_network_fix.ps1 $Distro -ShowConf
wsl/wsl_network_fix.ps1 $Distro -Shutdown
wsl/wsl_network_fix.ps1 $Distro -DisableSwap
wsl/wsl_network_fix.ps1 $Distro -Shutdown -DisableSwap
# :revert changes
wsl/wsl_network_fix.ps1 $Distro -Revert
wsl/wsl_network_fix.ps1 $Distro -Revert -ShowConf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [switch]$DisableSwap,

    [switch]$Shutdown,

    [switch]$Revert,

    [switch]$ShowConf
)

begin {
    $ErrorActionPreference = 'Stop'
    # check if the script is running on Windows
    if (-not $IsWindows) {
        Write-Warning 'Run the script on Windows!'
        exit 0
    }

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
    # check if the required functions are available, otherwise import SetupUtils module
    try {
        Get-Command ConvertFrom-Cfg -CommandType Function | Out-Null
        Get-Command ConvertTo-Cfg -CommandType Function | Out-Null
    } catch {
        Import-Module (Resolve-Path './modules/SetupUtils')
    }

    # check if distro exist
    $distros = wsl/wsl_distro_get.ps1 -FromRegistry
    if ($Distro -notin $distros.Name) {
        Write-Warning "The specified distro does not exist ($Distro)."
        exit 1
    }

    # determine if resolv.conf should be automatically generated
    if ($Revert) {
        $genResolv = 'true'
    } else {
        $genResolv = 'false'
    }

    # instantiate string builder
    $builder = [System.Text.StringBuilder]::new("# Generated by wsl_network_fix.ps1 on $((Get-Date).ToString('s'))")
}

process {
    # *replace wsl.conf
    Write-Host 'replacing wsl.conf' -ForegroundColor DarkGreen
    $wslConf = wsl.exe -d $Distro --exec cat /etc/wsl.conf 2>$null | ConvertFrom-Cfg
    if ($wslConf) {
        $wslConf.network = [ordered]@{ generateResolvConf = $genResolv }
    } else {
        $wslConf = [ordered]@{
            automount = [ordered]@{
                enabled    = 'true'
                options    = '"metadata"'
                mountFsTab = 'true'
            }
            network   = [ordered]@{
                generateResolvConf = $genResolv
            }
        }
    }
    $wslConfStr = ConvertTo-Cfg -OrderedDict $wslConf -LineFeed
    # save wsl.conf file
    $cmd = "rm -f /etc/wsl.conf || true && echo '$wslConfStr' >/etc/wsl.conf"
    wsl.exe -d $Distro --user root --exec bash -c $cmd

    # *recreate resolv.conf
    if (-not $Revert) {
        Write-Host 'replacing resolv.conf' -ForegroundColor DarkGreen
        # get DNS servers for specified interface
        $props = @(
            @{ Name = 'Name'; Expression = { $_.InterfaceAlias } }
            @{ Name = 'InterfaceDescription'; Expression = { $_.InterfaceDescription } }
            @{ Name = 'IPv4Address'; Expression = { $_.IPv4Address.IPAddress } }
            @{ Name = 'DNSServer'; Expression = { $_.DNSServer.Where({ $_.AddressFamily -eq 2 }).Address } }
        )
        $ipConfig = Get-NetIPConfiguration `
        | Where-Object { $_.NetAdapter.Status -eq 'Up' } `
        | Select-Object $props
        if ($ipConfig) {
            $list = for ($i = 0; $i -lt $ipConfig.Count; $i++) {
                [PSCustomObject]@{
                    No                   = "[$i]"
                    Name                 = $ipConfig[$i].Name
                    InterfaceDescription = $ipConfig[$i].InterfaceDescription
                    IPv4Address          = $ipConfig[$i].IPv4Address
                    DNSServer            = $ipConfig[$i].DNSServer
                }
            }
            do {
                $idx = -1
                $selection = Read-Host -Prompt "Please select the interface for propagating DNS Servers:`n$($list | Format-Table | Out-String)"
                [bool]$returnedInt = [int]::TryParse($selection, [ref]$idx)
            } until ($returnedInt -and $idx -ge 0 -and $idx -lt $netAdapters.Count)
            $dnsServers = $ipConfig[$idx].DNSServer
            $dnsServers.ForEach({ $builder.AppendLine("nameserver $_") | Out-Null })
        }
        # get DNS suffix search list
        $searchSuffix = (Get-DnsClientGlobalSetting).SuffixSearchList -join ','
        if ($searchSuffix) {
            $builder.AppendLine("search $searchSuffix") | Out-Null
        }
        # get distro default gateway
        $def_gtw = (wsl.exe -d $Distro -u root --exec sh -c 'ip route show default' | Select-String '(?<=via )[\d\.]+(?= dev)').Matches.Value
        if ($def_gtw) {
            $builder.AppendLine("nameserver $def_gtw") | Out-Null
        }
        $builder.AppendLine('options timeout:1 retries:1') | Out-Null
        $resolvConf = $builder.ToString().Replace("`r`n", "`n")
        # save resolv.conf file
        $cmd = [string]::Join("`n",
            'chattr -fi /etc/resolv.conf 2>/dev/null || true',
            'rm -f /etc/resolv.conf 2>/dev/null || true',
            "echo '$resolvConf' >/etc/resolv.conf",
            'chattr -f +i /etc/resolv.conf 2>/dev/null || true'
        )
        wsl.exe -d $Distro --user root --exec bash -c $cmd
    }

    # *disable wsl swap
    if ($DisableSwap) {
        Write-Host 'disabling swap' -ForegroundColor DarkGreen
        $wslCfgPath = [IO.Path]::Combine($HOME, '.wslconfig')
        try {
            $wslCfgContent = [IO.File]::ReadAllLines($wslCfgPath)
            if ($wslCfgContent | Select-String 'swap' -Quiet) {
                $wslCfgContent = $wslCfgContent -replace 'swap.+', 'swap=0'
            } else {
                $wslCfgContent += 'swap=0'
            }
            [IO.File]::WriteAllLines($wslCfgPath, $wslCfgContent)
        } catch {
            [IO.File]::WriteAllText($wslCfgPath, "[wsl2]`nswap=0")
        }
    }

    # *shutdown specified distro
    if ($Shutdown -or $Revert) {
        wsl.exe -d $Distro --user root --exec bash -c 'chattr -fi /etc/resolv.conf 2>/dev/null || true'
        Write-Host "shutting down '$Distro' distro" -ForegroundColor DarkGreen
        wsl.exe --shutdown $Distro
    }
}

end {
    if ($ShowConf) {
        Write-Host "`nwsl.conf" -ForegroundColor Magenta
        wsl.exe -d $Distro --exec cat /etc/wsl.conf | Write-Host
        Write-Host "`nresolv.conf" -ForegroundColor Magenta
        wsl.exe -d $Distro --exec cat /etc/resolv.conf | Write-Host
    } else {
        $Revert ? 'resolv.conf configuration reverted' : 'resolv.conf configuration updated'
    }
}
