#Requires -RunAsAdministrator
<#
.SYNOPSIS
Script synopsis.

.PARAMETER NatNetwork
NAT network CIDR range.

.EXAMPLE
$NatNetwork = '192.168.121.0/24'
.assets/trigger/create_hyperv_natswitch.ps1 $NatNetwork

.NOTES
# :save script example
./scripts_egsave.ps1 .assets/trigger/create_hyperv_natswitch.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 .assets/trigger/create_hyperv_natswitch.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 .assets/trigger/create_hyperv_natswitch.ps1 -WriteOutput)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$NatNetwork
)

$SWITCH_NAME = 'NATSwitch'
# calculate IP address and prefix
$ipAddress, $prefix = $NatNetwork.Split('/') -replace '0$', '1'

if ($SWITCH_NAME -notin (Get-VMSwitch | Select-Object -ExpandProperty Name)) {
    Write-Host "Creating Internal-only switch named '$SWITCH_NAME' on Windows Hyper-V host..."
    New-VMSwitch -SwitchName $SWITCH_NAME -SwitchType Internal
    New-NetIPAddress -IPAddress $ipAddress -PrefixLength $prefix -InterfaceAlias "vEthernet ($SWITCH_NAME)"
    New-NetNat -Name 'NATNetwork' -InternalIPInterfaceAddressPrefix $NatNetwork
} else {
    Write-Host "'$SWITCH_NAME' for static IP configuration already exists; skipping"
}

if ($ipAddress -notin (Get-NetIPAddress -InterfaceAlias "vEthernet ($SWITCH_NAME)" | Select-Object -ExpandProperty IPAddress)) {
    Write-Host "Registering new IP address '$ipAddress' on Windows Hyper-V host..."
    New-NetIPAddress -IPAddress $ipAddress -PrefixLength $prefix -InterfaceAlias "vEthernet ($SWITCH_NAME)"
} else {
    Write-Host "'$ipAddress' for static IP configuration already registered; skipping"
}

if ($NatNetwork -notin (Get-NetNat | Select-Object -ExpandProperty InternalIPInterfaceAddressPrefix)) {
    Write-Host "Registering new NAT adapter for '$NatNetwork' on Windows Hyper-V host..."
    New-NetNat -Name 'NATNetwork' -InternalIPInterfaceAddressPrefix $NatNetwork
} else {
    Write-Host "'$NatNetwork' for static IP configuration already registered; skipping"
}
