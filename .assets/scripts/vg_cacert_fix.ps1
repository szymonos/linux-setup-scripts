#Requires -RunAsAdministrator
#Requires -PSEdition Core
<#
.SYNOPSIS
Fix self signed certificate error in Vagrant by installing certificates from chain into Vagrant\embedded directory.
.EXAMPLE
.assets/scripts/vg_cacert_fix.ps1
#>

$ErrorActionPreference = 'Stop'

# get Vagrant\embedded folder
try {
    $vgRoot = Split-Path (Split-Path (Get-Command 'vagrant.exe').Source)
    $embeddedDir = Join-Path $vgRoot -ChildPath 'embedded'
} catch [System.Management.Automation.CommandNotFoundException] {
    $embeddedDir = 'C:\HashiCorp\Vagrant\embedded'
    if (-not (Test-Path $embeddedDir -PathType Containe)) {
        Write-Warning 'Vagrant path not found.'
        break
    }
} catch {
    Write-Verbose $_.Exception.GetType().FullName
    Write-Error $_
}

# intercept certificates from chain
$chain = .assets/tools/cert_chain_pem.ps1 -Uri 'gems.hashicorp.com'

# build cacert.pem with all intercepted certificates
$builder = [System.Text.StringBuilder]::new()
foreach ($cert in $chain) {
    $builder.AppendLine("# Issuer: $($cert.Issuer)") | Out-Null
    $builder.AppendLine("# Subject: $($cert.Subject)") | Out-Null
    $builder.AppendLine("# Label: $($cert.Label)") | Out-Null
    $builder.AppendLine("# Serial: $($cert.SerialNumber)") | Out-Null
    $builder.AppendLine("# SHA1 Fingerprint: $($cert.Thumbprint)") | Out-Null
    $builder.AppendLine($cert.PEM) | Out-Null
}

# save cacert.pem to the Vagrant\embedded folder
$cacertPath = [System.IO.Path]::Combine($embeddedDir, 'cacert.pem')
[System.IO.File]::WriteAllText($cacertPath, $builder.ToString().Trim())
