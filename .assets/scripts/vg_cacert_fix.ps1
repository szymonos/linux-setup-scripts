#Requires -RunAsAdministrator
#Requires -PSEdition Core -Version 7.3
<#
.SYNOPSIS
Fix self signed certificate error in Vagrant by installing certificates from chain into Vagrant\embedded directory.
.EXAMPLE
.assets/scripts/vg_cacert_fix.ps1
#>

begin {
    $ErrorActionPreference = 'Stop'

    # set location to workspace folder
    Push-Location "$PSScriptRoot/../.."

    # import SetupUtils for the Set-WslConf function
    Import-Module (Convert-Path './modules/SetupUtils') -Force
}

process {
    # determine the Vagrant\embedded folder
    try {
        $vgRoot = Split-Path (Split-Path (Get-Command 'vagrant.exe').Source)
        $embeddedDir = Join-Path $vgRoot -ChildPath 'embedded'
    } catch [System.Management.Automation.CommandNotFoundException] {
        $embeddedDir = 'C:\HashiCorp\Vagrant\embedded'
        if (-not (Test-Path $embeddedDir -PathType Container)) {
            Write-Warning 'Vagrant path not found.'
            break
        }
    } catch {
        Write-Verbose $_.Exception.GetType().FullName
        Write-Error $_
    }

    # get existing certificates in the vagrant cacert.pem file
    $cacertPath = [System.IO.Path]::Combine($embeddedDir, 'cacert.pem')
    if (Test-Path $cacertPath) {
        $cacert = ConvertFrom-PEM -Path $cacertPath
    } else {
        New-Item -Path $cacertPath -ItemType File -Force | Out-Null
        $cacert = [System.Collections.Generic.List[System.Security.Cryptography.X509Certificates.X509Certificate2]]::new()
    }

    # intercept certificates from chain and filter out existing ones
    $chain = Get-Certificate -Uri 'gems.hashicorp.com' -BuildChain | Select-Object -Skip 1 | Where-Object {
        $_.Thumbprint -notin $cacert.Thumbprint
    }

    # build cacert.pem with all intercepted certificates
    if ($chain) {
        $builder = [System.Text.StringBuilder]::new()
        foreach ($cert in $chain) {
            $pem = $cert | ConvertTo-PEM -AddHeader
            $builder.AppendLine($pem) | Out-Null
        }
        # add intercepted certificates to the cacert.pem file
        [System.IO.File]::AppendAllText($cacertPath, $builder.ToString().Trim())

        # display added certificates
        $cnList = $chain.ForEach({ $([regex]::Match($_.Subject, '(?<=CN=)(.)+?(?=,|$)').Value) }) | Join-String -Separator ', ' -DoubleQuote
        Write-Host "Added certificates for $cnList to $cacertPath"
    } else {
        Write-Host 'No new certificates to add.'
    }
}

clean {
    # return to the original location
    Pop-Location
}
