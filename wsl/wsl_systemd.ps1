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
    if ($env:OS -notmatch 'windows') {
        Write-Warning 'Run the script on Windows!'
        exit 0
    }

    # check if distro exist
    [string[]]$distros = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss `
    | ForEach-Object { $_.GetValue('DistributionName') } `
    | Where-Object { $_ -notmatch '^docker-desktop' }
    if ($Distro -notin $distros) {
        Write-Warning "The specified distro does not exist ($Distro)."
        exit
    }
}

process {
    if ($wslConf = wsl.exe -d $Distro --exec bash -c 'cat /etc/wsl.conf 2>/dev/null') {
        # fix $wslConf string
        $wslConf = [string]::Join("`n", $wslConf) -replace "`n{3,}", "`n`n"

        if ($wslConf | Select-String '[boot]' -SimpleMatch -Quiet) {
            if ($wslConf | Select-String 'systemd' -SimpleMatch -Quiet) {
                $wslConf = $wslConf -replace 'systemd.+', "systemd=$Systemd"
            } else {
                $wslConf = $wslConf -replace '\[boot\]', "[boot]`nsystemd=$Systemd"
            }
        } else {
            $wslConf = [string]::Join("`n",
                '[boot]',
                "systemd=$Systemd`n",
                $wslConf
            )
        }
    } else {
        $wslConf = [string]::Join("`n",
            '[boot]',
            "systemd=$Systemd"
        )
    }
    # save wsl.conf file
    $cmd = "rm -f /etc/wsl.conf || true && echo '$wslConf' >/etc/wsl.conf"
    wsl.exe -d $Distro --user root --exec bash -c $cmd
}

end {
    Write-Host "`nwsl.conf" -ForegroundColor Magenta
    wsl.exe -d $Distro --exec cat /etc/wsl.conf | Write-Host
}
