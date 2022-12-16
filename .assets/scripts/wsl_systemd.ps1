<#
.SYNOPSIS
Enables systemd in specified WSL distro.
.PARAMETER Distro
Name of the WSL distro to install the certificate to.

.EXAMPLE
$Distro = 'Ubuntu'
$Systemd = 'false'
~install certificates in specified distro
.assets/scripts/wsl_systemd.ps1 $Distro
.assets/scripts/wsl_systemd.ps1 $Distro -s $Systemd
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [ValidateSet('true', 'false')]
    [string]$Systemd = 'true'
)

begin {
    # check if distro exist
    [string[]]$distros = (Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss).ForEach({ $_.GetValue('DistributionName') }).Where({ $_ -notmatch '^docker-desktop' })
    if ($Distro -notin $distros) {
        Write-Warning "The specified distro does not exist ($Distro)."
        exit
    }
}

process {
    if ($wslConf = wsl.exe -d $Distro --exec bash -c 'cat /etc/wsl.conf 2>/dev/null') {
        if ($wslConf | Select-String 'systemd' -Quiet) {
            $wslConf = ($wslConf -replace 'systemd.+', "systemd=$Systemd") -join "`n"
        } else {
            $wslConf = "[boot]`nsystemd=$Systemd`n`n" + ($wslConf -join "`n")
        }
        wsl.exe -d $Distro --user root --exec bash -c "rm -f /etc/wsl.conf || true && echo '$wslConf' >/etc/wsl.conf"
    } else {
        $wslConf = "[boot]`nsystemd=$Systemd"
        wsl.exe -d $Distro --user root --exec bash -c "rm -f /etc/wsl.conf || true && echo '$wslConf' >/etc/wsl.conf"
    }
}

end {
    wsl.exe -d $Distro --exec cat /etc/wsl.conf | Write-Host
}
