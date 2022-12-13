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
.assets/scripts/wsl_network_fix.ps1 $Distro -d $InterfaceDescription
.assets/scripts/wsl_network_fix.ps1 $Distro -d $InterfaceDescription -DisableSwap
.assets/scripts/wsl_network_fix.ps1 $Distro -d $InterfaceDescription -Shutdown -DisableSwap
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [Alias('d')]
    [Parameter(Mandatory)]
    [string[]]$InterfaceDescription,

    [switch]$DisableSwap,

    [switch]$Shutdown
)

# *replace wsl.conf
$wslConv = @'
[network]
generateResolvConf = false
[automount]
enabled = true
options = "metadata"
mountFsTab = false
'@
# save wsl.conf file
wsl.exe -d $Distro --user root --exec bash -c "echo '$wslConv' >/etc/wsl.conf"

# *recreate resolv.conf
# get DNS servers for specified interface
$dnsServers = (Get-NetAdapter | Where-Object InterfaceDescription -Like "$InterfaceDescription*" | Get-DnsClientServerAddress).ServerAddresses
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
wsl.exe -d $Distro --user root --exec bash -c "echo '$resolvConf' >/etc/resolv.conf"

# *disable wsl swap
if ($DisableSwap) {
    if ($wslconfig = [IO.File]::ReadAllLines([IO.Path]::Combine($HOME, '.wslconfig'))) {
        if ($wslconfig | Select-String 'swap' -Quiet) {
            $wslconfig = $wslconfig -replace 'swap.+', 'swap=0'
        } else {
            $wslconfig += 'swap=0'
        }
        [IO.File]::WriteAllLines([IO.Path]::Combine($HOME, '.wslconfig'), $wslconfig)
    } else {
        [IO.File]::WriteAllText([IO.Path]::Combine($HOME, '.wslconfig'), "[wsl2]`nswap=0")
    }
}

# *shutdown specified distro
if ($Shutdown) {
    wsl.exe --shutdown $Distro
}
