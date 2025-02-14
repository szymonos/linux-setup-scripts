<#
.SYNOPSIS
Script synopsis.

.PARAMETER VMName
Name of the virtual machine.

.EXAMPLE
$VMName = 'VG-Fedora'
.assets/trigger/cleanup_vbox_vm.ps1 -v $VMName

.NOTES
# :save script example
./scripts_egsave.ps1 .assets/trigger/cleanup_vbox_vm.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 .assets/trigger/cleanup_vbox_vm.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 .assets/trigger/cleanup_vbox_vm.ps1 -WriteOutput)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$VMName
)

Remove-Item "$HOME\VirtualBox VMs\$VMName" -Force -Recurse -ErrorAction SilentlyContinue
