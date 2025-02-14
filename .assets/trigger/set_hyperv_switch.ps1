#Requires -RunAsAdministrator
<#
.SYNOPSIS
Script synopsis.

.PARAMETER VMName
Name of the virtual machine.

.EXAMPLE
$VMName = 'Vg-Fedora'
.assets/trigger/set_hyperv_switch.ps1 $VMName

.NOTES
# :save script example
./scripts_egsave.ps1 .assets/trigger/set_hyperv_switch.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 .assets/trigger/set_hyperv_switch.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 .assets/trigger/set_hyperv_switch.ps1 -WriteOutput)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$VMName
)

Get-VM $VMName | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName 'NATSwitch'
