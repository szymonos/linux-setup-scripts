#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Clean up ssh config and remove entries from known_hosts on destroy.

.PARAMETER IpAddress
IP of the host in ssh config file.
.PARAMETER HostName
Name of the host in ssh config file.

.EXAMPLE
$IPAddress = '192.168.121.57'
$HostName = 'vg-fedora-hv'
.assets/trigger/delete_ssh_config.ps1 -a $IPAddress -n $HostName
#>
[CmdletBinding()]
param (
    [Alias('a')]
    [Parameter(Mandatory, Position = 0)]
    [string]$IPAddress,

    [Alias('n')]
    [Parameter(Mandatory, Position = 1)]
    [string]$HostName
)

# remove host entries from the .ssh/config file
$sshConfig = [IO.Path]::Combine($HOME, '.ssh', 'config')
if (Test-Path $sshConfig -PathType Leaf) {
    $content = [IO.File]::ReadAllText($sshConfig)
    if ($content | Select-String -Pattern "Host $HostName") {
        Write-Host "Removing '$HostName' entry from ssh config..."
        $content = $content -replace "Host $HostName[\s\S]+?(?=(\nHost|\z))" -replace '[\r\n](?=[\r\n])'
        [IO.File]::WriteAllText($sshConfig, $content.TrimEnd())
    }
}

# delete host dedicated ssh config file
$sshHost = [IO.Path]::Combine($HOME, '.ssh', $HostName)
if (Test-Path $sshHost -PathType Leaf) {
    Remove-Item $sshHost
}

# remove entries from known_hosts for the specified IP address
$knownHosts = [IO.Path]::Combine($HOME, '.ssh', 'known_hosts')
if (Test-Path $knownHosts -PathType Leaf) {
    $content = [IO.File]::ReadAllLines($knownHosts)
    if ($content | Select-String -Pattern "^$IPAddress") {
        Write-Host "Removing '$IPAddress' fingerprint from ssh known_hosts..."
        [IO.File]::WriteAllLines($knownHosts, ($content -notmatch "^$IPAddress"))
    }
}
