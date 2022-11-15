<#
.SYNOPSIS
Update all existing WSL distros, except docker ones.
.PARAMETER ThemeFont
Choose if oh-my-posh prompt theme should use base or powerline fonts.

.EXAMPLE
$ThemeFont = 'powerline'
.assets/scripts/wsl_update.ps1
#>
[CmdletBinding()]
param (
    [ValidateSet('base', 'powerline')]
    [string]$ThemeFont = 'base'
)

# get list of available WSL distros
[Console]::OutputEncoding = [System.Text.Encoding]::Unicode
$distros = (wsl.exe -l -q) -match '\w+' -notmatch '^docker'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# iterate over all found distros to update packages
foreach ($distro in $distros) {
    $scope = wsl.exe -d $distro --exec bash -c "[ -f /usr/bin/kubectl ] && ([ -f /usr/local/bin/kubeseal ] && echo 'k8s_full' || echo 'k8s_basic' ) || echo 'base'"
    Write-Host "$distro - $scope" -ForegroundColor Magenta
    .assets/scripts/wsl_setup.ps1 $distro -t $ThemeFont -s $scope
}
