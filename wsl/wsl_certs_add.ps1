#Requires -PSEdition Core
<#
.SYNOPSIS
Get certificates in chain and install them in the specified WSL distribution.
.DESCRIPTION
Script intercepts root and intermediate certificates in chain for specified sites
and installs them in the specified WSL distro.

.PARAMETER Distro
Name of the WSL distro to install the certificate to.
.PARAMETER Uri [Optional]
Uri used for intercepting certificate chain.

.EXAMPLE
$Distro = 'Ubuntu'
# ~install certificates into specified distro
wsl/wsl_certs_add.ps1 $Distro
# ~specify custom Uri
$Uri = 'www.powershellgallery.com'
wsl/wsl_certs_add.ps1 $Distro -u $Uri
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [ValidateNotNullOrEmpty()]
    [string]$Uri = 'www.google.com'
)

begin {
    $ErrorActionPreference = 'Stop'

    # check if distro exist
    [string[]]$distros = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss `
    | ForEach-Object { $_.GetValue('DistributionName') } `
    | Where-Object { $_ -notmatch '^docker-desktop' }
    if ($Distro -notin $distros) {
        Write-Warning "The specified distro does not exist ($Distro)."
        exit
    }

    # determine update ca parameters depending on distro
    $sysId = wsl.exe -d $Distro --exec sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release
    switch -Regex ($sysId) {
        arch {
            $crt = @{ path = '/etc/ca-certificates/trust-source/anchors'; cmd = 'trust extract-compat' }
            continue
        }
        fedora {
            $crt = @{ path = '/etc/pki/ca-trust/source/anchors'; cmd = 'update-ca-trust' }
            continue
        }
        'debian|ubuntu' {
            $crt = @{ path = '/usr/local/share/ca-certificates'; cmd = 'update-ca-certificates' }
            $cmd = 'type update-ca-certificates &>/dev/null || (export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y ca-certificates)'
            wsl -d $Distro -u root --exec bash -c $cmd
            continue
        }
        opensuse {
            $crt = @{ path = '/usr/share/pki/trust/anchors'; cmd = 'update-ca-certificates' }
            continue
        }
        Default {
            exit
        }
    }

    # create temp folder for saving certificates
    $tmpName = "tmp.$( -join ((0..9 + 'a'..'z') * 10 | Get-Random -Count 10))"
    $tmpFolder = New-Item -Path . -Name $tmpName -ItemType Directory
}

process {
    $certs = .assets/tools/cert_chain_pem.ps1 $Uri
    Write-Host 'Intercepted certificates' -ForegroundColor DarkGreen
    foreach ($cert in $certs) {
        $crtFile = "$($cert.CN.Replace(' ', '_')).crt"
        Write-Host "- $crtFile"
        [IO.File]::WriteAllText([IO.Path]::Combine($tmpFolder, $crtFile), $cert.PEM)
    }

    # copy certificates to specified distro and install them
    $cmd = "mkdir -p $($crt.path) && install -m 0644 ${tmpName}/*.crt $($crt.path) && $($crt.cmd)"
    wsl -d $Distro -u root --exec bash -c $cmd
}

end {
    Remove-Item $tmpFolder -Recurse
}
