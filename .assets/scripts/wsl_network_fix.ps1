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

.EXAMPLE
$Distro = 'Debian'
$InterfaceDescription = 'NordLynx'
.assets/scripts/wsl_network_fix.ps1 $Distro
.assets/scripts/wsl_network_fix.ps1 $Distro -d $InterfaceDescription
.assets/scripts/wsl_network_fix.ps1 $Distro -DisableSwap -d $InterfaceDescription
.assets/scripts/wsl_network_fix.ps1 $Distro -Shutdown -DisableSwap -d $InterfaceDescription
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [Alias('d')]
    [string]$InterfaceDescription,

    [switch]$DisableSwap,

    [switch]$Shutdown
)

# *get list of distros
[string[]]$distros = (Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss).ForEach({ $_.GetValue('DistributionName') }).Where({ $_ -notmatch '^docker-desktop' })
if ($Distro -notin $distros) {
    Write-Warning "The specified distro does not exist ($Distro)."
    exit
}

# *replace wsl.conf
Write-Host 'replacing wsl.conf...' -ForegroundColor Magenta
$wslConf = @'
[network]
generateResolvConf = false
[automount]
enabled = true
options = "metadata"
mountFsTab = false
'@
# save wsl.conf file
wsl.exe -d $Distro --user root --exec bash -c "rm -f /etc/wsl.conf || true && echo '$wslConf' >/etc/wsl.conf"

# *recreate resolv.conf
Write-Host 'replacing resolv.conf...' -ForegroundColor Magenta
# get DNS servers for specified interface
if (-not $InterfaceDescription) {
    $netAdapters = Get-NetAdapter | Where-Object Status -eq 'Up'
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
} else {
    $dnsServers = (Get-NetAdapter | Where-Object InterfaceDescription -Like "$InterfaceDescription*" | Get-DnsClientServerAddress).ServerAddresses
}
# get DNS suffix search list
$searchSuffix = (Get-DnsClientGlobalSetting).SuffixSearchList -join ','
# get distro default gateway
$def_gtw = (wsl.exe -d $Distro -u root --exec ip route show default | Select-String '(?<=via )[\d\.]+(?= dev)').Matches.Value
# build resolv.conf
$resolvList = [Collections.Generic.List[string]]::new([string[]]"# Generated by wsl_network_fix.ps1 on $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))")
$dnsServers.ForEach({ $resolvList.Add("nameserver $_") })
$resolvList.Add("nameserver $def_gtw")
if ($searchSuffix) {
    $resolvList.Add("search $searchSuffix")
}
$resolvList.Add('options timeout:1 retries:1')
$resolvConf = [string]::Join("`n", $resolvList)
# save resolv.conf file
wsl.exe -d $Distro --user root --exec bash -c "rm -f /etc/resolv.conf || true && echo '$resolvConf' >/etc/resolv.conf"

# *disable wsl swap
if ($DisableSwap) {
    Write-Host 'disabling swap...' -ForegroundColor Magenta
    $wslCfgPath = [IO.Path]::Combine($HOME, '.wslconfig')
    if ($wslCfgContent = [IO.File]::ReadAllLines($wslCfgPath)) {
        if ($wslCfgContent | Select-String 'swap' -Quiet) {
            $wslCfgContent = $wslCfgContent -replace 'swap.+', 'swap=0'
        } else {
            $wslCfgContent += 'swap=0'
        }
        [IO.File]::WriteAllLines($wslCfgPath, $wslCfgContent)
    } else {
        [IO.File]::WriteAllText($wslCfgPath, "[wsl2]`nswap=0")
    }
}

# *shutdown specified distro
if ($Shutdown) {
    Write-Host "shutting down '$Distro' distro..." -ForegroundColor Magenta
    wsl.exe --shutdown $Distro
}
