<#
.SYNOPSIS
Get certificates in chain and install them in the specified WSL distribution.
.DESCRIPTION
Script intercepts root and intermediate certificates in chain for specified sites
and installs them in the specified WSL distro.
It requires openssl application to be installed in Windows.

.PARAMETER Distro
Name of the WSL distro to install the certificate to.
.PARAMETER SiteList
List of sites to check certificates in chain.

.EXAMPLE
$Distro   = 'Ubuntu'
$SiteList = @(
    'galaxy.ansible.com'
    'www.powershellgallery.com'
)
~install certificates in specified distro
.assets/scripts/wsl_add_certificate.ps1 $Distro
.assets/scripts/wsl_add_certificate.ps1 $Distro -l $SiteList
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [Alias('l')]
    [ValidateNotNullOrEmpty()]
    [string[]]$SiteList = @('www.google.com')
)

begin {
    # check if openssl is installed
    if (-not (Get-Command openssl -CommandType Application)) {
        Write-Warning 'Openssl not found. Script execution halted.'
        exit
    }

    # check if distro exist
    [string[]]$distros = (Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss).ForEach({ $_.GetValue('DistributionName') }).Where({ $_ -notmatch '^docker-desktop' })
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
            wsl -d $Distro -u root --exec bash -c 'type update-ca-certificates &>/dev/null || (export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y ca-certificates)'
            continue
        }
        opensuse {
            $crt = @{ path = '/usr/share/pki/trust/anchors'; cmd = 'update-ca-certificates' }
            continue
        }
    }

    # create .tmp folder for storing certificates if not exist
    if (-not (Test-Path '.tmp' -PathType Container)) {
        New-Item '.tmp' -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    }

    # instantiate generic list to store intercepted certificate names
    $certs = [Collections.Generic.List[pscustomobject]]::new()
}

process {
    foreach ($site in $SiteList) {
        # get certificate chain
        do {
            $chain = ((Out-Null | openssl s_client -showcerts -connect ${site}:443) -join "`n" 2>$null `
                | Select-String '-{5}BEGIN [\S\n]+ CERTIFICATE-{5}' -AllMatches).Matches.Value
        } until ($chain)
        # save root certificate run command to update certificates
        for ($i = 1; $i -lt $chain.Count; $i++) {
            $certByteData = [Convert]::FromBase64String(($chain[$i] -replace ('-.*-')).Trim())
            $x509Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certByteData)
            $certs.Add([PSCustomObject]@{
                    Name   = ($x509Cert.Subject | Select-String '(?<=CN=)(.)+?(?=,)').Matches.Value.Replace(' ', '_').Trim('"') + '.crt'
                    Issuer = $x509Cert.Issuer
                }
            )
            [IO.File]::WriteAllText([IO.Path]::Combine($PWD, '.tmp', $certs[-1].Name), $chain[$i])
        }
        # get root certificate from the local machine trusted root certificate store if not in chain.
        if ($x509Cert.Subject -notin $certs.Issuer) {
            $AKI = $x509Cert.Extensions.Where({ $_.Oid.FriendlyName -eq 'Authority Key Identifier' }).Format(1).Split('=')[1].Trim()
            $rootCert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {
                ($_.Extensions | Where-Object { $_.Oid.FriendlyName -eq 'Subject Key Identifier' }).SubjectKeyIdentifier -EQ $AKI
            }
            $certs.Add([PSCustomObject]@{ Name = ($rootCert.Subject | Select-String '(?<=CN=)(.)+?(?=,)').Matches.Value.Replace(' ', '_').Trim('"') + '.crt' })
            $oPem = [Text.StringBuilder]::new()
            $oPem.AppendLine('-----BEGIN CERTIFICATE-----') | Out-Null
            $oPem.AppendLine([System.Convert]::ToBase64String($rootCert.RawData, 'InsertLineBreaks')) | Out-Null
            $oPem.AppendLine('-----END CERTIFICATE-----') | Out-Null
            [IO.File]::WriteAllText([IO.Path]::Combine($PWD, '.tmp', $certs[-1].Name), $oPem.ToString())
        }
    }
    # copy and install certificates
    wsl -d $Distro -u root --exec bash -c "mkdir -p $($crt.path) && mv -f .tmp/*.crt $($crt.path) 2>/dev/null && chmod 644 $($crt.path)/*.crt && $($crt.cmd)"
}

end {
    # print list of intercepted certificates
    Write-Host 'Intercepted certificates' -ForegroundColor Magenta
    $certs.Name | Select-Object -Unique | Write-Host
}
