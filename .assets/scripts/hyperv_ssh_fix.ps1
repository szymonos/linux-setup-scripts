#Requires -RunAsAdministrator
<#
.SYNOPSIS
Correct the ssh/config with new VM IP address and fingerprint in known_hosts
.EXAMPLE
$VMName = 'Vg-Fedora'
.assets/scripts/hyperv_ssh_fix.ps1 -v $VMName
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$VMName
)

# start virtual machine
Start-VM $VMName -WarningAction SilentlyContinue
# calculate MAC of the VM
$macAddress = (Get-VM -Name $VMName).NetworkAdapters.MacAddress -split '(.{2})' -ne '' -join '-'

# determine VM IP address
[Console]::Write('waiting for ip address')
do {
    [Console]::Write('.')
    Start-Sleep 2
    $ip = Get-NetNeighbor -LinkLayerAddress $macAddress -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress -First 1
} until ($ip)
Write-Host "`n$VMName : $ip"

# fix .ssh/config entry
if (Select-String -Pattern "^Host\s+$($VMname.ToLower())" -Path "$HOME\.ssh\config") {
    [System.IO.File]::ReadAllText("$HOME\.ssh\config") -replace "(?s)(Host $($VMname.ToLower())\n(\s+?)HostName)\s+[\d\.]+", "`$1 $ip" | Out-File "$HOME\.ssh\config" -Encoding utf8 -NoNewline
} else {
    Add-Content -Path "$HOME\.ssh\config" -Value "Host $($VMname.ToLower())`n  HostName $ip`n  User vagrant"
}

# clean up .ssh/known_hosts entries
[System.IO.File]::ReadAllLines("$HOME\.ssh\known_hosts") -notmatch '^172' | Out-File "$HOME\.ssh\known_hosts" -Encoding utf8

# add fingerprint to .ssh/known_hosts
[Console]::Write('waiting for machine fingerprint')
while ($true) {
    [Console]::Write('.')
    $fingerprint = (ssh-keyscan $ip 2>$null) -match '^172.*ecdsa-sha2-nistp256'
    if ($fingerprint) {
        $fingerprint | Add-Content -Path "$HOME\.ssh\known_hosts"
        break
    }
    Start-Sleep 2
}
