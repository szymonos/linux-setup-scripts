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
.PARAMETER ShowConf
Print current configuration after changes.

.EXAMPLE
$Distro = 'Ubuntu'
wsl/wsl_systemd.ps1 $Distro -Systemd 'true'
wsl/wsl_systemd.ps1 $Distro -Systemd 'true' -ShowConf
wsl/wsl_systemd.ps1 $Distro -Systemd 'false'
wsl/wsl_systemd.ps1 $Distro -Systemd 'false' -ShowConf

# :check systemd services
systemctl list-units --type=service --no-pager

.NOTES
# :save script example
./scripts_egsave.ps1 wsl/wsl_systemd.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 wsl/wsl_systemd.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 wsl/wsl_systemd.ps1 -WriteOutput)
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [ValidateSet('true', 'false')]
    [string]$Systemd,

    [switch]$ShowConf
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
    # import SetupUtils module
    Import-Module (Resolve-Path './modules/SetupUtils')

    # check if distro exist
    $distros = Get-WslDistro -FromRegistry
    if ($Distro -notin $distros.Name) {
        Write-Warning "The specified distro does not exist ($Distro)."
        exit 1
    }
}

process {
    # *set wsl.conf
    Write-Host 'replacing wsl.conf' -ForegroundColor DarkGreen
    $param = @{
        Distro   = $Distro
        ConfDict = [ordered]@{
            boot = [ordered]@{
                systemd = $Systemd
            }
        }
        ShowConf = $ShowConf ? $true : $false
    }
    Set-WslConf @param
}

end {
    if (-not $ShowConf) {
        Write-Host "systemd $($Systemd -eq 'true' ? 'enabled' : 'disabled')"
    }
}
