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
Split a Uri into its hostname and port components.

.DESCRIPTION
Accepts a bare hostname ('example.com'), a host:port pair ('example.com:8443')
or a full Uri ('https://example.com:8443/path') and returns the hostname and
port. A port embedded in the Uri takes precedence over the Port parameter.

.PARAMETER Uri
Uri, hostname or host:port string to parse.
.PARAMETER Port
Fallback port used when no port is embedded in the Uri.
#>
function Split-UriHostPort {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Uri,

        [Parameter(Position = 1)]
        [ValidateRange(1, 65535)]
        [int]$Port = 443
    )

    # strip scheme, then path/query/fragment, then userinfo to leave the authority component
    $authority = (($Uri -replace '^[a-zA-Z][\w+.-]*://') -split '[/?#]', 2)[0].Split('@')[-1]

    if ($authority -match '^\[(?<host>.+)\](?::(?<port>\d+))?$') {
        # bracketed IPv6 literal, optionally with a port
        $hostname = $Matches.host
        if ($Matches.port) { $Port = [int]$Matches.port }
    } elseif ($authority -match '^(?<host>[^:]+):(?<port>\d+)$') {
        # host:port
        $hostname = $Matches.host
        $Port = [int]$Matches.port
    } elseif ($authority -match '^[^:]+:[^:]*$') {
        # single colon but a non-numeric/empty port - fail fast instead of mis-parsing as a hostname
        throw "Invalid port in Uri '$Uri'. Expected 'host:<number>'."
    } else {
        # bare hostname or bare (unbracketed) IPv6 literal
        $hostname = $authority
    }

    return $hostname, $Port
}


<#
.SYNOPSIS
Build a concise ErrorRecord for certificate retrieval failures.

.DESCRIPTION
Unwraps nested .NET exceptions (e.g. the SocketException behind a
"Exception calling ..." wrapper) so the reported message states the actual
cause and prefixes it with the target host:port.

.PARAMETER Exception
Exception thrown while connecting or performing the TLS handshake.
.PARAMETER Target
Target 'host:port' the certificate was requested from.
#>
function New-CertificateError {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [System.Exception]$Exception,

        [Parameter(Mandatory, Position = 1)]
        [string]$Target
    )

    # drill down to the innermost exception for the root-cause message
    $inner = $Exception
    while ($inner.InnerException) {
        $inner = $inner.InnerException
    }
    # pick the error category based on the underlying exception type
    $category = $inner -is [System.Net.Sockets.SocketException] `
        ? [System.Management.Automation.ErrorCategory]::ConnectionError
        : [System.Management.Automation.ErrorCategory]::NotSpecified

    return [System.Management.Automation.ErrorRecord]::new(
        [System.Exception]::new("Failed to get certificate from '$Target'. $($inner.Message)", $Exception),
        'CertificateRetrievalError',
        $category,
        $Target
    )
}


<#
.SYNOPSIS
Get certificate(s) from specified Uri.

.PARAMETER Uri
Uri used for intercepting certificate. The port can be appended to the host
(e.g. 'example.com:8443'), analogous to `openssl s_client -connect host:port`.
.PARAMETER Port
Port used for the TLS connection. Defaults to 443 and is overridden by a port
embedded in the Uri.
.PARAMETER PresentedChain
Return the full certificate chain presented by the endpoint during the TLS
handshake (leaf first), instead of just the leaf certificate. The chain is
captured from the handshake itself, so it works even for endpoints with a
broken/untrusted chain or behind an inspecting proxy.

.NOTES
The certificate presented during the handshake is always accepted, regardless of
its validity, so inspecting expired/self-signed/untrusted certificates never
throws. Only connection and transport failures raise an error.
#>
function Get-Certificate {
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Uri,

        [Parameter(Position = 1)]
        [ValidateRange(1, 65535)]
        [int]$Port = 443,

        [switch]$PresentedChain
    )

    begin {
        # parse hostname and port from the Uri ('host', 'host:port' or 'scheme://host:port/path')
        try {
            $hostname, $Port = Split-UriHostPort -Uri $Uri -Port $Port
        } catch {
            $PSCmdlet.ThrowTerminatingError((New-CertificateError -Exception $_.Exception -Target $Uri))
        }
    }

    process {
        # list to capture the presented chain from the handshake callback; the certs
        # are deep-copied (via RawData) so they survive disposal of the SslStream
        $presented = [System.Collections.Generic.List[System.Security.Cryptography.X509Certificates.X509Certificate2]]::new()
        $validationCallback = {
            param ($senderObj, $cert, $chain, $sslPolicyErrors)
            # reset so a repeated callback invocation replaces rather than duplicates
            $presented.Clear()
            # $chain can be null in some handshake edge cases; guard before enumerating
            if ($chain) {
                foreach ($element in $chain.ChainElements) {
                    $presented.Add([System.Security.Cryptography.X509Certificates.X509Certificate2]::new($element.Certificate.RawData))
                }
            }
            # always accept - this function inspects certificates, it does not validate trust
            return $true
        }

        $tcpClient = $sslStream = $null
        try {
            # open the TCP connection to the target host and port
            $tcpClient = [System.Net.Sockets.TcpClient]::new($hostname, $Port)

            # perform the TLS handshake, accepting any certificate so even invalid
            # certs can be inspected; the callback captures the full presented chain
            $sslStream = [System.Net.Security.SslStream]::new($tcpClient.GetStream(), $false, $validationCallback)
            $sslStream.AuthenticateAsClient($hostname)
            # RemoteCertificate is typed X509Certificate; use GetRawCertData() (base
            # method) and deep-copy so the leaf survives disposal of the SslStream
            $rawLeaf = $sslStream.RemoteCertificate.GetRawCertData()
            $leaf = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($rawLeaf)
        } catch {
            # surface a concise, categorized error instead of the raw .NET exception
            $PSCmdlet.ThrowTerminatingError((New-CertificateError -Exception $_.Exception -Target "${hostname}:${Port}"))
        } finally {
            if ($sslStream) { $sslStream.Dispose() }
            if ($tcpClient) { $tcpClient.Dispose() }
        }

        # return the presented chain (leaf first), or just the leaf certificate;
        # fall back to the leaf if the callback couldn't populate the chain
        $certificate = ($PresentedChain -and $presented.Count) ? $presented.ToArray() : $leaf
    }

    end {
        return $certificate
    }
}


<#
.SYNOPSIS
Get certificate(s) from specified Uri using OpenSSL application.

.PARAMETER Uri
Uri used for intercepting certificate. The port can be appended to the host
(e.g. 'example.com:8443'), analogous to `openssl s_client -connect host:port`.
.PARAMETER Port
Port used for the TLS connection. Defaults to 443 and is overridden by a port
embedded in the Uri.
.PARAMETER PresentedChain
Return the full certificate chain presented by the endpoint (leaf first), instead
of just the leaf certificate. Uses `openssl s_client -showcerts`, so the returned
certificates are the exact bytes the endpoint sent on the wire.
#>
function Get-CertificateOpenSSL {
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2[]])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Uri,

        [Parameter(Position = 1)]
        [ValidateRange(1, 65535)]
        [int]$Port = 443,

        [switch]$PresentedChain
    )

    begin {
        # check if OpenSSL is installed
        if (-not (Get-Command openssl -CommandType Application -ErrorAction SilentlyContinue)) {
            $er = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('OpenSSL not found. Install OpenSSL or omit the -OpenSSL switch.'),
                'OpenSSLNotFound',
                [System.Management.Automation.ErrorCategory]::NotInstalled,
                'openssl'
            )
            $PSCmdlet.ThrowTerminatingError($er)
        }

        # parse hostname and port from the Uri ('host', 'host:port' or 'scheme://host:port/path')
        try {
            $hostname, $Port = Split-UriHostPort -Uri $Uri -Port $Port
        } catch {
            $PSCmdlet.ThrowTerminatingError((New-CertificateError -Exception $_.Exception -Target $Uri))
        }

        # bracket IPv6 literals (a bare colon in the host) for OpenSSL's host:port syntax
        $connectHost = $hostname.Contains(':') ? "[$hostname]" : $hostname

        # build the OpenSSL argument list
        [System.Collections.Generic.List[string]]$cmdArgs = @('s_client')
        $cmdArgs.Add('-connect')
        $cmdArgs.Add("${connectHost}:${Port}")
        $cmdArgs.Add('-servername')
        $cmdArgs.Add($hostname)
        if ($PresentedChain) {
            $cmdArgs.Add('-showcerts')
        }
    }

    process {
        try {
            # Use the call operator (&) to execute OpenSSL with arguments
            $opensslOutput = Out-Null | & openssl @cmdArgs 2>$null
        } catch {
            $PSCmdlet.ThrowTerminatingError((New-CertificateError -Exception $_.Exception -Target "${hostname}:${Port}"))
        }

        if (-not $opensslOutput) {
            $er = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Failed to get certificate from '${hostname}:${Port}'. No output from OpenSSL, possibly an unknown host."),
                'CertificateRetrievalError',
                [System.Management.Automation.ErrorCategory]::ConnectionError,
                "${hostname}:${Port}"
            )
            $PSCmdlet.ThrowTerminatingError($er)
        }

        # Normalize the output: join array into one string and standardize line breaks
        $outputText = ($opensslOutput -join "`n") -replace "`r`n", "`n"

        # Define a regex pattern to match PEM encoded certificates
        $pemPattern = '(?<=-----BEGIN CERTIFICATE-----\n)[\S\n]+?(?=\n-----END CERTIFICATE-----)'
        $reMatches = [regex]::Matches($outputText, $pemPattern)

        if ($reMatches.Count -eq 0) {
            $er = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Failed to get certificate from '${hostname}:${Port}'. No certificates found in OpenSSL output."),
                'CertificateRetrievalError',
                [System.Management.Automation.ErrorCategory]::InvalidResult,
                "${hostname}:${Port}"
            )
            $PSCmdlet.ThrowTerminatingError($er)
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
    } elseif ($IsMacOS) {
        # read trusted roots from the system keychain (includes MDM-pushed roots)
        $pem = security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain /Library/Keychains/System.keychain 2>$null
        if ($pem) {
            ConvertFrom-PEM -InputObject ([string]::Join("`n", $pem))
        }
    }
}


<#
.SYNOPSIS
Show certificate chain for a specified Uri.

.PARAMETER Uri
Uri used for intercepting certificate chain. The port can be appended to the
host (e.g. 'example.com:8443'), analogous to `openssl s_client -connect host:port`.
.PARAMETER Port
Port used for the TLS connection. Defaults to 443 and is overridden by a port
embedded in the Uri.
.PARAMETER InputObject
Object from pipeline to show certificate properties.
.PARAMETER PresentedChain
Show the full certificate chain presented by the endpoint, instead of just the
leaf certificate.
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

        [Parameter(Position = 1, ParameterSetName = 'FromUri')]
        [ValidateRange(1, 65535)]
        [int]$Port = 443,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromPipeline')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2[]]$InputObject,

        [Parameter(ParameterSetName = 'FromUri')]
        [switch]$PresentedChain,

        [switch]$Extended,

        [switch]$Strip,

        [switch]$All,

        [switch]$OpenSSL
    )

    begin {
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
                try {
                    $cert = if ($PSBoundParameters.OpenSSL) {
                        $PSBoundParameters.Remove('OpenSSL') | Out-Null
                        Get-CertificateOpenSSL @PSBoundParameters | Add-CertificateProperties
                    } else {
                        Get-Certificate @PSBoundParameters | Add-CertificateProperties
                    }
                } catch {
                    # re-throw the concise error from Get-Certificate without the wrapper's call-site noise
                    $PSCmdlet.ThrowTerminatingError($_)
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
Uri used for intercepting certificate chain. The port can be appended to the
host (e.g. 'example.com:8443'), analogous to `openssl s_client -connect host:port`.
.PARAMETER Port
Port used for the TLS connection. Defaults to 443 and is overridden by a port
embedded in the Uri.
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

        [Parameter(Position = 1)]
        [ValidateRange(1, 65535)]
        [int]$Port = 443,

        [Parameter(Mandatory, ParameterSetName = 'Extended')]
        [switch]$Extended,

        [Parameter(Mandatory, ParameterSetName = 'Strip')]
        [switch]$Strip,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All,

        [switch]$OpenSSL
    )

    begin {
        $PSBoundParameters.Add('PresentedChain', $true)
    }

    process {
        try {
            Show-Certificate @PSBoundParameters
        } catch {
            # re-throw the concise error without the wrapper's call-site noise
            $PSCmdlet.ThrowTerminatingError($_)
        }
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
