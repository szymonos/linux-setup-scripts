#!/usr/bin/pwsh -nop
#Requires -PSEdition Core
<#
.SYNOPSIS
Get root and intermediate certificates in PEM format from the certificate chain.

.PARAMETER Uri
Uri to get the certificate chain from.

.EXAMPLE
.assets/tools/cert_chain_pem.ps1
# :specify custom Uri
$Uri = 'www.powershellgallery.com'
.assets/tools/cert_chain_pem.ps1 $Uri
#>
[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Uri = 'www.google.com'
)

begin {
    $ErrorActionPreference = 'Stop'

    $tcpClient = [System.Net.Sockets.TcpClient]::new($Uri, 443)
    $chain = [System.Security.Cryptography.X509Certificates.X509Chain]::new()
    $sslStream = [System.Net.Security.SslStream]::new($tcpClient.GetStream())

    # instantiate list for storing PEM encoded certificates
    $pems = [System.Collections.Generic.List[PSCustomObject]]::new()
}

process {
    try {
        $sslStream.AuthenticateAsClient($Uri)
        $certificate = $sslStream.RemoteCertificate
    } finally {
        $sslStream.Close()
    }
    # check certificate chain
    $isChainValid = $chain.Build($certificate)
    if ($isChainValid) {
        # build certificate chain
        $certificate = $chain.ChainElements.Certificate
        for ($i = 1; $i -lt $certificate.Count; $i++) {
            # convert certificate to base64
            $base64 = [System.Convert]::ToBase64String($certificate[$i].RawData)
            # build PEM encoded X.509 certificate
            $builder = [System.Text.StringBuilder]::new()
            $builder.AppendLine('-----BEGIN CERTIFICATE-----') | Out-Null
            for ($j = 0; $j -lt $base64.Length; $j += 64) {
                $length = [System.Math]::Min(64, $base64.Length - $j)
                $builder.AppendLine($base64.Substring($j, $length)) | Out-Null
            }
            $builder.AppendLine('-----END CERTIFICATE-----') | Out-Null
            # create pem object with parsed common information and PEM encoded certificate
            $pem = @{
                Issuer       = $certificate[$i].Issuer
                Subject      = $certificate[$i].Subject
                SerialNumber = $certificate[$i].SerialNumber
                Thumbprint   = $certificate[$i].Thumbprint
                PEM          = $builder.ToString().Replace("`r`n", "`n")
            }
            # check if CN available, otherwise add OU as label
            $cn = [regex]::Match($pem.Subject, '(?<=CN=)(.)+?(?=,|$)').Value.Trim().Trim('"')
            if ($cn) {
                $pem.Label = $cn
            } else {
                $pem.Label = [regex]::Match($pem.Subject, '(?<=OU=)(.)+?(?=,|$)').Value.Trim().Trim('"')
            }
            $pems.Add([PSCustomObject]$pem)
        }
    } else {
        Write-Warning 'SSL certificate chain validation failed.'
    }
}

end {
    return $pems
}