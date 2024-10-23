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
