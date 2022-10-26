#Requires -RunAsAdministrator
<#
.SYNOPSIS
Script synopsis.
.PARAMETER VMName
Name of the virtual machine.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$VMName
)

Get-VM $VMName | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName 'NATSwitch'
