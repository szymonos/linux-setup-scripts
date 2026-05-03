<#
.SYNOPSIS
Add CommonName, SubjectAlternativeName, SubjectKeyIdentifier and AuthorityKeyIdentifier properties to X509 certificate.

.PARAMETER Certificate
X509Certificate2 certificate.
#>
function Add-CertificateProperties {
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    begin {
        # instantiate list for storing X509 certificates
        $certs = [System.Collections.Generic.List[System.Security.Cryptography.X509Certificates.X509Certificate2]]::new()
    }

    process {
        # Common Name
        $cn = [regex]::Match($Certificate.Subject, '(?<=CN=)(.)+?(?=,|$)')
        if ($cn) {
            $cn = $cn.Value.Trim().Trim('"')
            $Certificate | Add-Member -MemberType NoteProperty -Name 'CommonName' -Value $cn -PassThru `
            | Add-Member -MemberType AliasProperty -Name 'CN' -Value CommonName
        }
        # Subject Alternative Name
        $san = $Certificate.Extensions.Where({ $_.Oid.FriendlyName -match 'Subject Alternative Name' })
        if ($san) {
            $san = $san.Format(1).Trim()
            $Certificate `
            | Add-Member -MemberType NoteProperty -Name 'SubjectAlternativeName' -Value $san -PassThru `
            | Add-Member -MemberType AliasProperty -Name 'SAN' -Value SubjectAlternativeName
        }
        # Subject Key Identifier
        $ski = $Certificate.Extensions.Where({ $_.Oid.FriendlyName -match 'Subject Key Identifier' })
        if ($ski) {
            $ski = $ski.Format(1).Trim().Replace(':', '').ToUpper()
            $Certificate `
            | Add-Member -MemberType NoteProperty -Name 'SubjectKeyIdentifier' -Value $ski -PassThru `
            | Add-Member -MemberType AliasProperty -Name 'SKI' -Value SubjectKeyIdentifier
        }
        # Authority Key Identifier
        $aki = $Certificate.Extensions.Where({ $_.Oid.FriendlyName -match 'Authority Key Identifier' })
        if ($aki) {
            $aki = $aki.Format(1).Trim().Replace(':', '').Replace('KeyID=', '').ToUpper()
            $Certificate `
            | Add-Member -MemberType NoteProperty -Name 'AuthorityKeyIdentifier' -Value $aki -PassThru `
            | Add-Member -MemberType AliasProperty -Name 'AKI' -Value AuthorityKeyIdentifier
        }
        $certs.Add($Certificate)
    }

    end {
        return $certs
    }
}


<#
.SYNOPSIS
Create X509Certificate2 object(s) from PEM encoded certificate(s).

.PARAMETER InputObject
String with PEM encoded certificate.
.PARAMETER Path
Path to PEM encoded certificate file.
#>
function ConvertFrom-PEM {
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromString')]
        [string]$InputObject,

        [Parameter(Mandatory, Position = 0, ParameterSetName = 'FromPath')]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' }, ErrorMessage = "'{0}' is not a valid file path.")]
        [string]$Path
    )

    begin {
        # list to store input certificate strings
        $pemTxt = [System.Collections.Generic.List[string]]::new()
        # hashset for storing parsed pem certificates
        $pemSplit = [System.Collections.Generic.HashSet[string]]::new()
        # list to store decoded certificates
        $x509Certs = [System.Collections.Generic.List[Security.Cryptography.X509Certificates.X509Certificate2]]::new()
    }

    process {
        switch ($PsCmdlet.ParameterSetName) {
            FromPath {
                # read certificate file
                Resolve-Path $Path | ForEach-Object {
                    $pemTxt.Add([IO.File]::ReadAllText($_))
                }
                continue
            }
            FromString {
                $InputObject.ForEach({ $pemTxt.Add($_) })
                continue
            }
        }
    }

    end {
        # parse certificate string
        [regex]::Matches(
            [string]::Join("`n", $pemTxt).Replace("`r`n", "`n"),
            '(?<=-{5}BEGIN[\w ]+CERTIFICATE-{5}\n)[\S\n]+(?=\n-{5}END[\w ]+CERTIFICATE-{5})'
        ).Value.ForEach({ $pemSplit.Add($_) | Out-Null })
        # convert PEM encoded certificates to X509 certificate objects
        foreach ($pem in $pemSplit) {
            $decCrt = [Security.Cryptography.X509Certificates.X509Certificate2]::new([Convert]::FromBase64String($pem))
            $x509Certs.Add($decCrt)
        }

        return $x509Certs
    }
}


<#
.SYNOPSIS
Create PEM encoded certificate from X509Certificate2 object.

.PARAMETER Certificate
X509Certificate2 certificate.
.PARAMETER AddHeader
Add certificate header with Issuer, Subject, Label, Serial and Fingerprint info.
#>
function ConvertTo-PEM {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[string]])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [switch]$AddHeader
    )

    begin {
        # instantiate list for storing PEM encoded certificates
        $pems = [System.Collections.Generic.List[string]]::new()
    }

    process {
        # convert certificate to base64
        $base64 = [System.Convert]::ToBase64String($Certificate.RawData)
        # build PEM encoded X.509 certificate
        $builder = [System.Text.StringBuilder]::new()
        if ($AddHeader) {
            $builder.AppendLine("# Issuer: $($Certificate.Issuer)") | Out-Null
            $builder.AppendLine("# Subject: $($Certificate.Subject)") | Out-Null
            $builder.AppendLine("# Label: $([regex]::Match($Certificate.Subject, '(?<=CN=)(.)+?(?=,|$)').Value)") | Out-Null
            $builder.AppendLine("# Serial: $($Certificate.SerialNumber)") | Out-Null
            $builder.AppendLine("# SHA1 Fingerprint: $($Certificate.Thumbprint)") | Out-Null
        }
        $builder.AppendLine('-----BEGIN CERTIFICATE-----') | Out-Null
        for ($i = 0; $i -lt $base64.Length; $i += 64) {
            $length = [System.Math]::Min(64, $base64.Length - $i)
            $builder.AppendLine($base64.Substring($i, $length)) | Out-Null
        }
        $builder.AppendLine('-----END CERTIFICATE-----') | Out-Null
        # create object with parsed common name and PEM encoded certificate
        $pems.Add($builder.ToString().Replace("`r`n", "`n"))
    }

    end {
        return $pems
    }
}


<#
.SYNOPSIS
Get certificate(s) from specified Uri.

.PARAMETER Uri
Uri used for intercepting certificate.
.PARAMETER BuildChain
Switch whether to build full certificate chain.
.PARAMETER IgnoreValidation
Ignore validation errors for getting certificate/building chain.
#>
function Get-Certificate {
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Uri,

        [switch]$BuildChain,

        [switch]$IgnoreValidation
    )

    begin {
        $tcpClient = [System.Net.Sockets.TcpClient]::new($Uri, 443)
        if ($BuildChain) {
            $chain = [System.Security.Cryptography.X509Certificates.X509Chain]::new()
        }
        if ($IgnoreValidation) {
            $sslStream = [System.Net.Security.SslStream]::new($tcpClient.GetStream(), $false, { $true })
            if ($BuildChain) {
                $chain.ChainPolicy.VerificationFlags = [System.Security.Cryptography.X509Certificates.X509VerificationFlags]::AllFlags
            }
        } else {
            $sslStream = [System.Net.Security.SslStream]::new($tcpClient.GetStream())
        }
    }

    process {
        try {
            $sslStream.AuthenticateAsClient($Uri)
            $certificate = $sslStream.RemoteCertificate
        } finally {
            $sslStream.Close()
        }

        if ($BuildChain) {
            $isChainValid = $chain.Build($certificate)
            if ($isChainValid) {
                $certificate = $chain.ChainElements.Certificate
            } else {
                Write-Warning 'SSL certificate chain validation failed.'
            }
        }
    }

    end {
        return $certificate
    }
}


<#
.SYNOPSIS
Get certificate(s) from specified Uri using OpenSSL application.

.PARAMETER Uri
Uri used for intercepting certificate.
.PARAMETER BuildChain
Switch whether to build full certificate chain.
#>
function Get-CertificateOpenSSL {
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Uri,

        [switch]$BuildChain
    )

    begin {
        # check if OpenSSL is installed
        if (-not (Get-Command openssl -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw 'OpenSSL not found. Script execution halted.'
        }

        # build the OpenSSL argument list
        [System.Collections.Generic.List[string]]$cmdArgs = @('s_client')
        $cmdArgs.Add('-connect')
        $cmdArgs.Add("${Uri}:443")
        if ($BuildChain) {
            $cmdArgs.Add('-showcerts')
        }
    }

    process {
        try {
            # Use the call operator (&) to execute OpenSSL with arguments
            $opensslOutput = Out-Null | & openssl @cmdArgs 2>$null
        } catch {
            Throw "Error executing OpenSSL: $_"
        }

        if (-not $opensslOutput) {
            Throw "No output from OpenSSL. Possibly an unknown host: `"$Uri`"."
        }

        # Normalize the output: join array into one string and standardize line breaks
        $outputText = ($opensslOutput -join "`n") -replace "`r`n", "`n"

        # Define a regex pattern to match PEM encoded certificates
        $pemPattern = '(?<=-----BEGIN CERTIFICATE-----\n)[\S\n]+?(?=\n-----END CERTIFICATE-----)'
        $reMatches = [regex]::Matches($outputText, $pemPattern)

        if ($reMatches.Count -eq 0) {
            Throw "No certificates found in OpenSSL output for `"$Uri`"."
        }

        # Convert each PEM block to an X509Certificate2 object
        foreach ($match in $reMatches) {
            try {
                $certBytes = [Convert]::FromBase64String($match.Value)
                [Security.Cryptography.X509Certificates.X509Certificate2]::new($certBytes)
            } catch {
                Write-Warning 'Failed to convert a certificate block to X509Certificate2.'
            }
        }
    }
}


<#
.SYNOPSIS
Get root TLS certificates in the system.
#>
function Get-RootCertificates {
    if ($IsWindows) {
        Get-ChildItem Cert:\LocalMachine\Root
    } elseif ($IsLinux) {
        $sysId = (Select-String '(?<=^ID.+)(alpine|arch|fedora|debian|ubuntu|opensuse)' -List /etc/os-release).Matches.Value
        $certPath = $sysId -eq 'opensuse' ? '/etc/ssl/ca-bundle.pem' : '/etc/ssl/certs/ca-certificates.crt'
        ConvertFrom-PEM -Path $certPath
    }
}


<#
.SYNOPSIS
Show certificate chain for a specified Uri.

.PARAMETER Uri
Uri used for intercepting certificate chain.
.PARAMETER InputObject
Object from pipeline to show certificate properties.
.PARAMETER BuildChain
Build chain for certificate obtained from Uri.
.PARAMETER Extended
Switch, whether to show extended certificate properties.
.PARAMETER Strip
Switch, whether to show non-null certificate properties.
.PARAMETER All
Switch, whether to show all certificate properties.
.PARAMETER OpenSSL
Use OpenSSL to retrieve certificate chain.
#>
function Show-Certificate {
    [CmdletBinding(DefaultParameterSetName = 'Compact')]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'FromUri')]
        [string]$Uri,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromPipeline')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2[]]$InputObject,

        [Parameter(ParameterSetName = 'FromUri')]
        [switch]$BuildChain,

        [switch]$Extended,

        [switch]$Strip,

        [switch]$All,

        [switch]$OpenSSL
    )

    begin {
        $WarningPreference = 'Stop'

        # build properties for Show-Object function
        $showCertProp = if ($All) {
            @{ }
        } elseif ($Strip) {
            @{ Strip = $true }
        } elseif ($Extended) {
            @{
                TypeName   = @('System.Boolean', 'System.DateTime', 'System.Int32', 'System.String')
                MemberType = @('AliasProperty', 'Property')
                Strip      = $true
            }
        } else {
            @{
                TypeName   = @('System.DateTime', 'System.String')
                MemberType = @('AliasProperty', 'Property')
                Strip      = $true
            }
        }

        # instantiate generic list for storing certificates, so all certs from pipeline are processed
        $cert = [System.Collections.Generic.List[System.Security.Cryptography.X509Certificates.X509Certificate2]]::new()

        # clean PSBoundParameters for Get-Certificate function
        @('Extended', 'Strip', 'All').ForEach({ $PSBoundParameters.Remove($_) | Out-Null })
    }

    process {
        switch ($PsCmdlet.ParameterSetName) {
            FromUri {
                $cert = if ($PSBoundParameters.OpenSSL) {
                    $PSBoundParameters.Remove('OpenSSL') | Out-Null
                    Get-CertificateOpenSSL @PSBoundParameters | Add-CertificateProperties
                } else {
                    Get-Certificate @PSBoundParameters | Add-CertificateProperties
                }
            }
            FromPipeline {
                $crt = $InputObject | Add-CertificateProperties
                $cert.Add($crt)
            }
        }
    }

    end {
        $cert | Show-Object @showCertProp
    }
}


<#
.SYNOPSIS
Show certificate chain for a specified Uri.

.PARAMETER Uri
Uri used for intercepting certificate chain.
.PARAMETER Extended
Switch, whether to show extended certificate properties.
.PARAMETER Strip
Switch, whether to show non-null certificate properties.
.PARAMETER All
Switch, whether to show all certificate properties.
.PARAMETER OpenSSL
Use OpenSSL to retrieve certificate chain.
#>
function Show-CertificateChain {
    [CmdletBinding(DefaultParameterSetName = 'Compact')]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Uri,

        [Parameter(Mandatory, ParameterSetName = 'Extended')]
        [switch]$Extended,

        [Parameter(Mandatory, ParameterSetName = 'Strip')]
        [switch]$Strip,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All,

        [switch]$OpenSSL
    )

    begin {
        $PSBoundParameters.Add('BuildChain', $true)
    }

    process {
        Show-Certificate @PSBoundParameters
    }
}


<#
.SYNOPSIS
Decode PEM certificate(s) and show their properties.

.PARAMETER InputObject
String with PEM encoded certificate(s).
.PARAMETER Path
Path to PEM encoded certificate file(s).
.PARAMETER Extended
Switch, whether to show extended certificate properties.
.PARAMETER Strip
Switch, whether to show non-null certificate properties.
.PARAMETER All
Switch, whether to show all certificate properties.
.PARAMETER OpenSSL
Use OpenSSL to retrieve certificate chain.
#>
function Show-ConvertedPem {
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        # FromString sets
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromString')]
        [string]$InputObject,

        # FromPath sets
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'FromPath')]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' }, ErrorMessage = "'{0}' is not a valid file path.")]
        [string]$Path,

        # Extended switch for each set
        [switch]$Extended,

        # Strip switch for each set
        [switch]$Strip,

        # All switch for each set
        [switch]$All,

        [switch]$OpenSSL
    )

    begin {
        # check that at most one of -Extended, -Strip, -All is specified
        if ($PSBoundParameters.Keys.ForEach({ $_ -in @('Extended', 'Strip', 'All') }).Where(({ $_ })).Count -le 1) {
            $x509Certs = [System.Collections.Generic.List[Security.Cryptography.X509Certificates.X509Certificate2]]::new()
            $continue = $true
        } else {
            Write-Warning 'Only one of -Extended, -Strip, or -All parameters can be specified.'
            $continue = $false
            return
        }
    }

    process {
        if ($continue) {
            if ($PSBoundParameters.Path) {
                ConvertFrom-PEM -Path $PSBoundParameters.Path | ForEach-Object {
                    $x509Certs.Add($_)
                }
            } elseif ($PSBoundParameters.InputObject) {
                ConvertFrom-PEM -InputObject $PSBoundParameters.InputObject | ForEach-Object {
                    $x509Certs.Add($_)
                }
            } else {
                Throw 'Either InputObject or Path parameter must be specified.'
            }
        }
    }

    end {
        if ($continue) {
            # return the list of X509 certificates
            @('InputObject', 'Path').ForEach({ $PSBoundParameters.Remove($_) | Out-Null })
            $x509Certs | Show-Certificate @PSBoundParameters
        }
    }
}

Set-Alias -Name pemdec -Value Show-ConvertedPem
