#!/usr/bin/env -S pwsh -nop
<#
.SYNOPSIS
Clean up ssh config and remove entries from known_hosts on destroy.
.PARAMETER IpAddress
IP of the host in ssh config file.
.PARAMETER HostName
Name of the host in ssh config file.
.EXAMPLE
$IpAddress = '192.168.121.57'
$HostName = 'vg-fedora-hv'
.assets/trigger/delete_ssh_config.ps1 $IpAddress $HostName
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$IpAddress,

    [Parameter(Mandatory, Position = 1)]
    [string]$HostName
)

$sshConfig = [IO.Path]::Combine($HOME, '.ssh', 'config')
if (Test-Path $sshConfig -PathType Leaf) {
    $content = [IO.File]::ReadAllText($sshConfig)
    if ($content | Select-String -Pattern "Host $HostName") {
        Write-Host "Removing '$HostName' entry from ssh config..."
        $content = $content -replace "Host $HostName[\s\S]+?(?=(\nHost|\z))" -replace '[\r\n](?=[\r\n])'
        [IO.File]::WriteAllText($sshConfig, $content.TrimEnd())
    }
}

$knownHosts = [IO.Path]::Combine($HOME, '.ssh', 'known_hosts')
if (Test-Path $knownHosts -PathType Leaf) {
    $content = [IO.File]::ReadAllLines($knownHosts)
    if ($content | Select-String -Pattern "^$IpAddress") {
        Write-Host "Removing '$IpAddress' fingerprint from ssh known_hosts..."
        [IO.File]::WriteAllLines($knownHosts, ($content -notmatch "^$IpAddress"))
    }
}
