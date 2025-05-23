#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Update ssh config and known_hosts files.

.PARAMETER IpAddress
IP of the host in ssh config file.
.PARAMETER HostName
Name of the host in ssh config file.
.PARAMETER Path
Path to file with ssh private key.

.EXAMPLE
$IpAddress = '192.168.121.57'
$HostName = 'vg-fedora-hv'
$Path = '~/.ssh/id_rsa'
.assets/trigger/set_ssh_config.ps1 $IpAddress $HostName $Path

.NOTES
# :save script example
./scripts_egsave.ps1 .assets/trigger/set_ssh_config.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 .assets/trigger/set_ssh_config.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 .assets/trigger/set_ssh_config.ps1 -WriteOutput)
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
$vagrantConfig = [string]::Join("`n",
    "Host $HostName",
    "  HostName $IpAddress",
    '  User vagrant',
    "  IdentityFile $identityFile"
)

# update ssh config file
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

# update known_hosts file
$knownHosts = [IO.Path]::Combine($HOME, '.ssh', 'known_hosts')
if (Test-Path $knownHosts -PathType Leaf) {
    $content = [IO.File]::ReadAllLines($knownHosts)
    if ($content | Select-String -Pattern "^$IpAddress") {
        Write-Host "Removing existing '$IpAddress' fingerprint from ssh known_hosts..."
        [IO.File]::WriteAllLines($knownHosts, ($content -notmatch "^$IpAddress"))
    }
}

# add fingerprint to known_hosts file
if (Get-Command ssh-keyscan -ErrorAction SilentlyContinue) {
    Write-Host "Adding '$IpAddress' fingerprint to ssh known_hosts file..."
    do {
        [string[]]$knownIP = ssh-keyscan $IpAddress 2>$null
        if ($knownIP) {
            [IO.File]::AppendAllLines($knownHosts, $knownIP)
        }
    } until ($knownIP)
}
