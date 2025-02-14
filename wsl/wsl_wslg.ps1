#Requires -PSEdition Core
<#
.SYNOPSIS
Enable/disable WSLg.

.PARAMETER WSLg
Specify the value to true or false to enable/disable WSLg.

.EXAMPLE
wsl/wsl_wslg.ps1 -GuiApplications 'true'
wsl/wsl_wslg.ps1 -GuiApplications 'false'

.NOTES
# :save script example
./scripts_egsave.ps1 wsl/wsl_wslg.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 wsl/wsl_wslg.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 wsl/wsl_wslg.ps1 -WriteOutput)
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('true', 'false')]
    [string]$GuiApplications
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
}

process {
    # *set wsl.conf
    if (Test-Path "$HOME/.wslconfig") {
        $wslConfig = Get-Content -Path "$HOME/.wslconfig" | ConvertFrom-Cfg
        if ($wslConfig.wsl2) {
            $wslConfig.wsl2.guiApplications = $GuiApplications
        } else {
            $wslConfig.wsl2 = @{ guiApplications = $GuiApplications }
        }
    } else {
        $wslConfig = [ordered]@{
            wsl2 = @{
                guiApplications = $GuiApplications
            }
        }
    }
    $wslConfigStr = ConvertTo-Cfg $wslConfig
    if ($wslConfigStr) {
        Set-Content -Value $wslConfigStr -Path "$HOME/.wslconfig"
    }
}

end {
    Write-Host "WSLg $($GuiApplications -eq 'true' ? 'enabled': 'disabled')."
}
