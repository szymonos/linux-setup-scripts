#Requires -RunAsAdministrator
<#
.SYNOPSIS
Script synopsis.

.PARAMETER VMName
Name of the virtual machine.

.EXAMPLE
$VMName = 'Vg-Fedora'
.assets/trigger/set_hyperv_switch.ps1 $VMName
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$VMName
)

Get-VM $VMName | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName 'NATSwitch'
