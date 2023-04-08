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
.assets/scripts/wsl_certs_add.ps1 $Distro
# ~specify custom Uri
$Uri = 'www.powershellgallery.com'
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
    $tmpFolder = New-Item -Path . -Name $tmpName -ItemType Directory
}

process {
    # get certificate chain
    $tcpClient = [Net.Sockets.TcpClient]::new($Uri, 443)
    $sslStream = [Net.Security.SslStream]::new($tcpClient.GetStream())

    try {
        $sslStream.AuthenticateAsClient($Uri)
        $certificate = $sslStream.RemoteCertificate
    } finally {
        $sslStream.Close()
    }

    $chain = [Security.Cryptography.X509Certificates.X509Chain]::new()
    $isChainValid = $chain.Build($certificate)

    if ($isChainValid) {
        $certs = $chain.ChainElements.Certificate
        Write-Host 'Intercepted certificates' -ForegroundColor Cyan
        for ($i = 1; $i -lt $certs.Count; $i++) {
            # convert certificate to base64
            $base64 = [Convert]::ToBase64String($certs[$i].RawData)
            # build PEM encoded X.509 certificate
            $builder = [Text.StringBuilder]::new()
            $builder.AppendLine('-----BEGIN CERTIFICATE-----') | Out-Null
            for ($j = 0; $j -lt $base64.Length; $j += 64) {
                $length = [Math]::Min(64, $base64.Length - $j)
                $builder.AppendLine($base64.Substring($j, $length)) | Out-Null
            }
            $builder.AppendLine('-----END CERTIFICATE-----') | Out-Null
            # parse common name from the subject
            $cn = [regex]::Match($certs[$i].Subject, '(?<=CN=)(.)+?(?=,|$)').Value.Replace(' ', '_').Trim('"')
            # save PEM certificate
            [IO.File]::WriteAllText([IO.Path]::Combine($tmpFolder, "${cn}.crt"), $builder.ToString().Replace("`r`n", "`n"))
            Write-Host "- ${cn}.crt"
        }
    } else {
        Write-Error 'SSL certificate chain validation failed.'
    }

    # copy certificates to specified distro and install them
    $cmd = "mkdir -p $($crt.path) && cp -f ${tmpName}/*.crt $($crt.path) && chmod 644 $($crt.path)/*.crt && $($crt.cmd)"
    wsl -d $Distro -u root --exec bash -c $cmd
}

end {
    Remove-Item $tmpFolder -Recurse
}
