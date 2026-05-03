#Requires -Modules Pester
# Unit tests for ConvertFrom-PEM and ConvertTo-PEM in do-common module

BeforeAll {
    . $PSScriptRoot/../../modules/do-common/Functions/certs.ps1
}

Describe 'ConvertFrom-PEM' {
    BeforeAll {
        # generate a self-signed test certificate
        $cert = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
            'CN=Pester Test Cert',
            [System.Security.Cryptography.RSA]::Create(2048),
            [System.Security.Cryptography.HashAlgorithmName]::SHA256,
            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
        ).CreateSelfSigned(
            [DateTimeOffset]::UtcNow,
            [DateTimeOffset]::UtcNow.AddDays(1)
        )
        $base64 = [Convert]::ToBase64String($cert.RawData)
        # build PEM string with 64-char line wrapping
        $pemLines = @('-----BEGIN CERTIFICATE-----')
        for ($i = 0; $i -lt $base64.Length; $i += 64) {
            $length = [Math]::Min(64, $base64.Length - $i)
            $pemLines += $base64.Substring($i, $length)
        }
        $pemLines += '-----END CERTIFICATE-----'
        $Script:testPem = $pemLines -join "`n"
        $Script:testCert = $cert
    }

    It 'parses a single PEM certificate from string' {
        $result = @($Script:testPem | ConvertFrom-PEM)
        $result | Should -HaveCount 1
        $result[0].Subject | Should -BeLike '*Pester Test Cert*'
    }

    It 'parses multiple PEM certificates from string' {
        $multiPem = "$($Script:testPem)`n$($Script:testPem)"
        # ConvertFrom-PEM deduplicates via HashSet, so two identical certs yield one
        $result = @($multiPem | ConvertFrom-PEM)
        $result | Should -HaveCount 1
    }

    It 'handles empty string input gracefully' {
        # Empty string triggers a non-terminating parameter binding error.
        # The function still returns no results.
        $result = @('' | ConvertFrom-PEM -ErrorAction SilentlyContinue)
        $result | Should -HaveCount 0
    }

    It 'handles string with no PEM markers' {
        $result = @('not a certificate' | ConvertFrom-PEM)
        $result | Should -HaveCount 0
    }
}

Describe 'ConvertTo-PEM' {
    BeforeAll {
        # generate a self-signed test certificate
        $Script:testCert = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
            'CN=Pester PEM Test',
            [System.Security.Cryptography.RSA]::Create(2048),
            [System.Security.Cryptography.HashAlgorithmName]::SHA256,
            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
        ).CreateSelfSigned(
            [DateTimeOffset]::UtcNow,
            [DateTimeOffset]::UtcNow.AddDays(1)
        )
    }

    It 'converts certificate to PEM string' {
        $result = @($Script:testCert | ConvertTo-PEM)
        $result | Should -HaveCount 1
        $result[0] | Should -Match 'BEGIN CERTIFICATE'
        $result[0] | Should -Match 'END CERTIFICATE'
    }

    It 'adds header with -AddHeader' {
        $result = @($Script:testCert | ConvertTo-PEM -AddHeader)
        $result[0] | Should -Match '# Subject:.*Pester PEM Test'
        $result[0] | Should -Match '# Serial:'
        $result[0] | Should -Match '# Issuer:'
    }

    It 'wraps base64 at 64 chars' {
        $result = @($Script:testCert | ConvertTo-PEM)
        $pemContent = $result[0]
        $lines = $pemContent.Split("`n") | Where-Object { $_ -and $_ -notmatch '^-' -and $_ -notmatch '^#' }
        # all lines except the last should be exactly 64 chars
        foreach ($line in $lines[0..($lines.Count - 2)]) {
            $line.Length | Should -Be 64
        }
        # last line should be <= 64 chars
        $lines[-1].Length | Should -BeLessOrEqual 64
    }
}

Describe 'ConvertFrom-PEM / ConvertTo-PEM roundtrip' {
    BeforeAll {
        $Script:testCert = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
            'CN=Pester Roundtrip',
            [System.Security.Cryptography.RSA]::Create(2048),
            [System.Security.Cryptography.HashAlgorithmName]::SHA256,
            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
        ).CreateSelfSigned(
            [DateTimeOffset]::UtcNow,
            [DateTimeOffset]::UtcNow.AddDays(1)
        )
    }

    It 'preserves certificate through roundtrip' {
        $pem = @($Script:testCert | ConvertTo-PEM)[0]
        $restored = @($pem | ConvertFrom-PEM)
        $restored | Should -HaveCount 1
        $restored[0].Subject | Should -BeLike '*Pester Roundtrip*'
        $restored[0].Thumbprint | Should -Be $Script:testCert.Thumbprint
    }
}
