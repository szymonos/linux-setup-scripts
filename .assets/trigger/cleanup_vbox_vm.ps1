<#
.SYNOPSIS
Script synopsis.
.PARAMETER VMName
Name of the virtual machine.
.EXAMPLE
$VMName = 'FedoraVB'
.assets/trigger/cleanup_vbox_vm.ps1 -v $VMName
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$VMName
)

Remove-Item "$HOME\VirtualBox VMs\$VMName" -Force -Recurse -ErrorAction SilentlyContinue
