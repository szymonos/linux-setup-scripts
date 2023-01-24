#!/usr/bin/env -S pwsh -nop
<#
.SYNOPSIS
Update ssh config and known_hosts files.
.PARAMETER IpAddress
IP of the host in ssh config file.
.PARAMETER HostName
Name of the host in ssh config file.
.EXAMPLE
$IpAddress = '192.168.121.57'
$HostName = 'vg-fedora-hv'
$Path = '~/.ssh/id_rsa'
.assets/trigger/set_ssh_config.ps1 $IpAddress $HostName $Path
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$IpAddress,

    [Parameter(Mandatory, Position = 1)]
    [string]$HostName,

    [Parameter(Mandatory, Position = 2)]
    [string]$Path
)

# calculate variables
$identityFile = [IO.Path]::Combine($HOME, '.ssh', $HostName)
$vagrantConfig = @"
Host $HostName
  HostName $IpAddress
  User vagrant
  IdentityFile $identityFile
"@

$sshConfig = [IO.Path]::Combine($HOME, '.ssh', 'config')
if (Test-Path $sshConfig -PathType Leaf) {
    $content = [IO.File]::ReadAllText($sshConfig).TrimEnd()
    if ($content | Select-String -Pattern "Host $HostName") {
        Write-Host "Updating '$HostName' entry in ssh config..."
        $content = $content -replace "Host $HostName[\s\S]+?(?=(\nHost|\z))", $vagrantConfig
    } elseif ($content | Select-String -Pattern "HostName $IpAddress") {
        Write-Host "Updating entry with '$IpAddress' IP in ssh config..."
        $content = $content -replace "Host[^\n]+\n[^\n]+$IpAddress\n[\s\S]+?(?=(\nHost|\z))", $vagrantConfig
    } else {
        Write-Host "Adding '$HostName' entry to ssh config..."
        $content = "$content`n$vagrantConfig"
    }
} else {
    Write-Host "Creating ssh config with '$HostName' entry..."
    New-Item $sshConfig -ItemType File -Force
    $content = $vagrantConfig
}
[IO.File]::WriteAllText($sshConfig, $content)
Copy-Item $Path -Destination $identityFile

$knownHosts = [IO.Path]::Combine($HOME, '.ssh', 'known_hosts')
if (Test-Path $knownHosts -PathType Leaf) {
    $content = [IO.File]::ReadAllLines($knownHosts)
    if ($content | Select-String -Pattern "^$IpAddress") {
        Write-Host "Removing existing '$IpAddress' fingerprint from ssh known_hosts..."
        [IO.File]::WriteAllLines($knownHosts, ($content -notmatch "^$IpAddress"))
    }
}
if (Get-Command ssh-keyscan -ErrorAction SilentlyContinue) {
    Write-Host "Adding '$IpAddress' fingerprint to ssh known_hosts file..."
    do {
        [string[]]$knownIP = ssh-keyscan $IpAddress 2>$null
        if ($knownIP) {
            [IO.File]::AppendAllLines($knownHosts, $knownIP)
        }
    } until ($knownIP)
}
