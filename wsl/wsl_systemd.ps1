#Requires -PSEdition Core
<#
.SYNOPSIS
Enables systemd in specified WSL distro.
.LINK
https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/

.PARAMETER Distro
Name of the WSL distro to install the certificate to.
.PARAMETER Systemd
Specify the value to true or false to enable/disable systemd accordingly in the distro.

.EXAMPLE
$Distro = 'Ubuntu'
wsl/wsl_systemd.ps1 $Distro -Systemd 'true'
wsl/wsl_systemd.ps1 $Distro -Systemd 'false'

# :check systemd services
systemctl list-units --type=service --no-pager
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [ValidateSet('true', 'false')]
    [string]$Systemd
)

begin {
    $ErrorActionPreference = 'Stop'
    # check if the script is running on Windows
    if (-not $IsWindows) {
        Write-Warning 'Run the script on Windows!'
        exit 0
    }

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
    # check if the required functions are available, otherwise import SetupUtils module
    try {
        Get-Command ConvertFrom-Cfg -CommandType Function | Out-Null
        Get-Command ConvertTo-Cfg -CommandType Function | Out-Null
    } catch {
        Import-Module (Resolve-Path './modules/SetupUtils')
    }

    # check if distro exist
    $distros = wsl/wsl_distro_get.ps1 -FromRegistry
    if ($Distro -notin $distros.Name) {
        Write-Warning "The specified distro does not exist ($Distro)."
        exit 1
    }
}

process {
    $wslConf = wsl.exe -d $Distro --exec cat /etc/wsl.conf 2>$null | ConvertFrom-Cfg
    if ($wslConf) {
        $wslConf.boot = [ordered]@{ systemd = $Systemd }
    } else {
        $wslConf = [ordered]@{
            boot = [ordered]@{
                systemd = $Systemd
            }
        }
    }
    $wslConfStr = ConvertTo-Cfg -OrderedDict $wslConf -LineFeed
    # save wsl.conf file
    $cmd = "rm -f /etc/wsl.conf || true && echo '$wslConfStr' >/etc/wsl.conf"
    wsl.exe -d $Distro --user root --exec bash -c $cmd
}

end {
    Write-Host "wsl.conf" -ForegroundColor Magenta
    wsl.exe -d $Distro --exec cat /etc/wsl.conf | Write-Host
}
