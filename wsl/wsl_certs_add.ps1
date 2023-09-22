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
# :install certificates into specified distro
wsl/wsl_certs_add.ps1 $Distro
# :specify custom Uri
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
    # check if the script is running on Windows
    if (-not $IsWindows) {
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

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
    # clone/refresh szymonos/ps-modules repository
    if (.assets/tools/gh_repo_clone.ps1 -OrgRepo 'szymonos/ps-modules') {
        # import the do-common module for certificate functions
        Import-Module '../ps-modules/modules/do-common'
    } else {
        Write-Error 'Cloning ps-modules repository failed.'
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
    $chain = Get-Certificate -Uri 'www.google.com' -BuildChain
    # check if root certificate from chain is in the cert store
    $rootCrts = Get-ChildItem Cert:\LocalMachine\Root
    if ($chain[-1].Thumbprint -in $rootCrts.Thumbprint) {
        Write-Host 'Intercepted certificates' -ForegroundColor DarkGreen
        for ($i = $chain.Count - 1; $i -gt 0; $i--) {
            $cert = $chain[$i]

            # calculate destination certificate file name
            $crtFile = "$($cert.Thumbprint).crt"
            Write-Host "- $crtFile : $([regex]::Match($cert.Subject, '(?<=CN=)(.)+?(?=,|$)').Value)"
            # calculate certificate Common Name
            $pem = $cert | ConvertTo-PEM -AddHeader
            [IO.File]::WriteAllText([IO.Path]::Combine($tmpFolder, $crtFile), $pem)
        }

        # copy certificates to specified distro and install them
        $cmd = "mkdir -p $($crt.path) && install -m 0644 ${tmpName}/*.crt $($crt.path) && $($crt.cmd)"
        wsl -d $Distro -u root --exec bash -c $cmd
    } else {
        Write-Error "Root certificate from TLS chain is not trusted ($($certificate.Subject))."
    }
}

end {
    Remove-Item $tmpFolder -Recurse
    Pop-Location
}
