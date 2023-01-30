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
$Site = 'www.powershellgallery.com'
~install certificates in specified distro
.assets/scripts/wsl_certs_add.ps1 $Distro
.assets/scripts/wsl_certs_add.ps1 $Distro -s $Site
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [Alias('s')]
    [ValidateNotNullOrEmpty()]
    [string]$Site = 'www.google.com'
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

    # instantiate generic list to store intercepted certificate details
    $certs = [Collections.Generic.List[PSCustomObject]]::new()
}

process {
    # get certificate chain
    do {
        $chain = ((Out-Null | openssl s_client -showcerts -connect ${Site}:443) -join "`n" 2>$null `
            | Select-String '-{5}BEGIN [\S\n]+ CERTIFICATE-{5}' -AllMatches).Matches.Value
    } until ($chain)
    # decode and save certificates from chain
    for ($i = 1; $i -lt $chain.Count; $i++) {
        $certByteData = [Convert]::FromBase64String(($chain[$i] -replace ('-.*-')).Trim())
        $x509Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certByteData)
        $certs.Add([PSCustomObject]@{
                Name    = [regex]::Match($x509Cert.Subject, '(?<=CN=)(.)+?(?=,)').Value.Replace(' ', '_').Trim('"') + '.crt'
                Subject = $x509Cert.Subject
                Issuer  = $x509Cert.Issuer
            }
        )
        [IO.File]::WriteAllText([IO.Path]::Combine($PWD, '.tmp', $certs[-1].Name), $chain[$i])
    }
    # get root certificate from the local machine trusted root certificate store if not in chain
    if ($x509Cert.Issuer -notin $certs.Subject) {
        if ($akiExt = $x509Cert.Extensions.Where({ $_.Oid.FriendlyName -eq 'Authority Key Identifier' })) {
            # find root certificate by AKI
            $aki = $akiExt.Format(0).Split('=')[1]
            $rootCert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {
                    ($_.Extensions.Where({ $_.Oid.FriendlyName -eq 'Subject Key Identifier' })).SubjectKeyIdentifier -EQ $aki
            }
        } else {
            # find root certificate by Issuer
            $rootCert = Get-ChildItem -Path Cert:\LocalMachine\Root `
            | Where-Object { $_.Subject -eq $x509Cert.Issuer } `
            | Sort-Object NotAfter `
            | Select-Object -Last 1
        }
        if ($rootCert) {
            # save root certificate found in the local store
            $certs.Add([PSCustomObject]@{
                    Name = [regex]::Match($rootCert.Subject, '(?<=CN=)(.)+?(?=,)').Value.Replace(' ', '_').Trim('"') + '.crt'
                }
            )
            $oPem = [Text.StringBuilder]::new()
            $oPem.AppendLine('-----BEGIN CERTIFICATE-----') | Out-Null
            $oPem.AppendLine([System.Convert]::ToBase64String($rootCert.RawData, 'InsertLineBreaks')) | Out-Null
            $oPem.AppendLine('-----END CERTIFICATE-----') | Out-Null
            [IO.File]::WriteAllText([IO.Path]::Combine($PWD, '.tmp', $certs[-1].Name), $oPem.ToString())
        }
    }
    # move certificates to specified distro and install them
    wsl -d $Distro -u root --exec bash -c "mkdir -p $($crt.path) && mv -f .tmp/*.crt $($crt.path) 2>/dev/null && chmod 644 $($crt.path)/*.crt && $($crt.cmd)"
}

end {
    # print list of intercepted certificates
    Write-Host 'Intercepted certificates' -ForegroundColor Cyan
    $certs.Name | Select-Object -Unique | Write-Host
}
