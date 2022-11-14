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

# set WSL output to UTF8
$env:WSL_UTF8 = 1
# get list of available WSL distros
$distros = (wsl.exe -l -q) -notmatch '^docker'

# iterate over all found distros to update packages
foreach ($distro in $distros) {
    $scope = wsl.exe -d $distro --exec bash -c "[ -f /usr/bin/kubectl ] && ([ -f /usr/local/bin/kubeseal ] && echo 'k8s_full' || echo 'k8s_basic' ) || echo 'base'"
    Write-Host "$distro - $scope" -ForegroundColor Magenta
    .assets/scripts/wsl_setup.ps1 $distro -t $ThemeFont -s $scope
}
