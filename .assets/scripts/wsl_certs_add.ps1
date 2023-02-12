#Requires -PSEdition Core
<#
.SYNOPSIS
Get certificates in chain and install them in the specified WSL distribution.
.DESCRIPTION
Script intercepts root and intermediate certificates in chain for specified sites
and installs them in the specified WSL distro.
It requires openssl application to be installed in Windows.

.PARAMETER Distro
Name of the WSL distro to install the certificate to.
.PARAMETER Site [Optional]
Site used for intercepting certificate chain.

.EXAMPLE
$Distro = 'Ubuntu'
$Uri = 'www.powershellgallery.com'
~install certificates in specified distro
.assets/scripts/wsl_certs_add.ps1 $Distro
.assets/scripts/wsl_certs_add.ps1 $Distro -u $Uri
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
    $sysId = wsl.exe -d $Distro --exec grep -oPm1 '^ID(_LIKE)?=.*?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release
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
    }

    # create temp folder for saving certificates
    $tmpName = "tmp.$( -join ((0..9 + 'a'..'z') * 10 | Get-Random -Count 10))"
    $tmp = New-Item -Path . -Name $tmpName -ItemType Directory
}

process {
    # get certificate chain
    $tcpClient = [Net.Sockets.TcpClient]::new($Uri, 443)
    $sslStream = [Net.Security.SslStream]::new($tcpClient.GetStream())

    $sslStream.AuthenticateAsClient($Uri)
    $certificate = $sslStream.RemoteCertificate

    $chain = [Security.Cryptography.X509Certificates.X509Chain]::new()
    $isChainValid = $chain.Build($certificate)

    if ($isChainValid) {
        $certs = $chain.ChainElements.Certificate
        Write-Host 'Intercepted certificates' -ForegroundColor Cyan
        for ($i = 1; $i -lt $certs.Count; $i++) {
            # build PEM encoded X.509 certificate
            $pem = [Text.StringBuilder]::new()
            $pem.AppendLine('-----BEGIN CERTIFICATE-----') | Out-Null
            $pem.AppendLine([System.Convert]::ToBase64String($certs[$i].RawData, 'InsertLineBreaks')) | Out-Null
            $pem.AppendLine('-----END CERTIFICATE-----') | Out-Null
            # parse CN from Subject
            $cn = [regex]::Match($certs[$i].Subject, '(?<=CN=)(.)+?(?=,|$)').Value.Replace(' ', '_')
            # save PEM certificate
            [IO.File]::WriteAllText([IO.Path]::Combine($tmp, "${cn}.crt"), $pem.ToString())
            Write-Host "- ${cn}.crt"
        }
    } else {
        Write-Error 'Error: SSL certificate chain validation failed'
    }

    # move certificates to specified distro and install them
    $cmd = "mkdir -p $($crt.path) && cp -f ${tmpName}/*.crt $($crt.path) && chmod 644 $($crt.path)/*.crt && $($crt.cmd)"
    wsl -d $Distro -u root --exec bash -c $cmd
}

end {
    # close SslStream and TcpClient
    $sslStream.Close()
    $tcpClient.Close()
    # remove temp folder
    Remove-Item $tmp -Recurse
}
