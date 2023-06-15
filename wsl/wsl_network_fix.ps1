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

.EXAMPLE
$Distro = 'Ubuntu'
wsl/wsl_network_fix.ps1 $Distro
wsl/wsl_network_fix.ps1 $Distro -Shutdown
wsl/wsl_network_fix.ps1 $Distro -DisableSwap
wsl/wsl_network_fix.ps1 $Distro -Shutdown -DisableSwap
# :revert changes
wsl/wsl_network_fix.ps1 $Distro -Revert -Shutdown
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [switch]$DisableSwap,

    [switch]$Shutdown,

    [switch]$Revert
)

begin {
    $ErrorActionPreference = 'Stop'

    # *get list of distros
    [string[]]$distros = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss `
    | ForEach-Object { $_.GetValue('DistributionName') } `
    | Where-Object { $_ -notmatch '^docker-desktop' }
    if ($Distro -notin $distros) {
        Write-Warning "The specified distro does not exist ($Distro)."
        exit
    }

    # determine if resolv.conf should be automatically generated
    if ($Revert) {
        $genResolv = 'true'
    } else {
        $genResolv = 'false'
    }

    # instantiate string builder
    $builder = [System.Text.StringBuilder]::new()
}

process {
    # *replace wsl.conf
    Write-Host 'replacing wsl.conf' -ForegroundColor DarkGreen
    if ($wslConf = wsl.exe -d $Distro --exec sh -c 'cat /etc/wsl.conf 2>/dev/null') {
        # fix $wslConf string
        $wslConf = [string]::Join("`n", $wslConf).Trim() -replace "`n{3,}", "`n`n"

        if ($wslConf | Select-String '[network]' -SimpleMatch -Quiet) {
            if ($wslConf | Select-String 'generateResolvConf' -SimpleMatch -Quiet) {
                $wslConf = $wslConf -replace 'generateResolvConf.+', "generateResolvConf = $genResolv"
            } else {
                $wslConf = $wslConf -replace '\[network\]', "[network]`ngenerateResolvConf = $genResolv"
            }
        } else {
            $wslConf = [string]::Join("`n",
                $wslConf,
                "`n[network]",
                "generateResolvConf = $genResolv"
            )
        }
    } else {
        $wslConf = [string]::Join("`n",
            '[automount]',
            'enabled = true',
            'options = "metadata"',
            'mountFsTab = true',
            "`n[network]",
            "generateResolvConf = $genResolv"
        )
    }
    # save wsl.conf file
    $cmd = "rm -f /etc/wsl.conf || true && echo '$wslConf' >/etc/wsl.conf"
    wsl.exe -d $Distro --user root --exec bash -c $cmd

    # *recreate resolv.conf
    Write-Host 'replacing resolv.conf' -ForegroundColor DarkGreen
    # get DNS servers for specified interface
    $netAdapters = Get-NetAdapter | Where-Object Status -EQ 'Up'
    $list = for ($i = 0; $i -lt $netAdapters.Count; $i++) {
        [PSCustomObject]@{
            No                   = "[$i]"
            Name                 = $netAdapters[$i].Name
            InterfaceDescription = $netAdapters[$i].InterfaceDescription
        }
    }
    do {
        $idx = -1
        $selection = Read-Host -Prompt "Please select the interface for propagating DNS Servers:`n$($list | Out-String)"
        [bool]$returnedInt = [int]::TryParse($selection, [ref]$idx)
    } until ($returnedInt -and $idx -ge 0 -and $idx -lt $netAdapters.Count)
    $dnsServers = ($netAdapters[$idx] | Get-DnsClientServerAddress).ServerAddresses
    # get DNS suffix search list
    $searchSuffix = (Get-DnsClientGlobalSetting).SuffixSearchList -join ','
    # get distro default gateway
    $def_gtw = (wsl.exe -d $Distro -u root --exec sh -c 'ip route show default' | Select-String '(?<=via )[\d\.]+(?= dev)').Matches.Value
    # build resolv.conf
    $builder.AppendLine("# Generated by wsl_network_fix.ps1 on $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))") | Out-Null
    $dnsServers.ForEach({ $builder.AppendLine("nameserver $_") | Out-Null })
    if ($def_gtw) {
        $builder.AppendLine("nameserver $def_gtw") | Out-Null
    }
    if ($searchSuffix) {
        $builder.AppendLine("search $searchSuffix") | Out-Null
    }
    $builder.AppendLine('options timeout:1 retries:1') | Out-Null
    $resolvConf = $builder.ToString().Replace("`r`n", "`n")
    # save resolv.conf file
    wsl.exe -d $Distro --user root --exec bash -c "rm -f /etc/resolv.conf || true && echo '$resolvConf' >/etc/resolv.conf"

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
    if ($Shutdown) {
        Write-Host "shutting down '$Distro' distro" -ForegroundColor DarkGreen
        wsl.exe --shutdown $Distro
    }
}

end {
    Write-Host "`nwsl.conf" -ForegroundColor Magenta
    wsl.exe -d $Distro --exec cat /etc/wsl.conf | Write-Host
    Write-Host "`nresolv.conf" -ForegroundColor Magenta
    wsl.exe -d $Distro --exec cat /etc/resolv.conf | Write-Host
}
