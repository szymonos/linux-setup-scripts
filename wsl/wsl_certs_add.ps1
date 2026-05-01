#Requires -PSEdition Core -Version 7.3
<#
.SYNOPSIS
Get certificates in chain and install them in the specified WSL distribution.
.DESCRIPTION
Script intercepts root and intermediate certificates in chain for specified sites
and installs them in the specified WSL distro.

.PARAMETER Distro
Name of the WSL distro to install the certificate to.
.PARAMETER Uris
List of uris used for intercepting certificate chain.

.EXAMPLE
$Distro = 'Ubuntu'
# :install certificates into specified distro
wsl/wsl_certs_add.ps1 $Distro
# :specify custom Uri
$Uris = @('pypi.org', 'login.microsoftonline.com')
wsl/wsl_certs_add.ps1 $Distro -u $Uris

.NOTES
# :save script example
./scripts_egsave.ps1 wsl/wsl_certs_add.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 wsl/wsl_certs_add.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 wsl/wsl_certs_add.ps1 -WriteOutput)
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [ValidateNotNullOrEmpty()]
    [string[]]$Uris = @('www.google.com', 'www.powershellgallery.com')
)

begin {
    $ErrorActionPreference = 'Stop'
    # check if the script is running on Windows
    if (-not $IsWindows) {
        Write-Warning 'Run the script on Windows!'
        exit 0
    }

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
    # check if the required functions are available, otherwise import SetupUtils module
    try {
        Get-Command Get-WslDistro -CommandType Function | Out-Null
    } catch {
        Import-Module (Resolve-Path './modules/SetupUtils')
    }

    # check if distro exist
    $distros = Get-WslDistro | Where-Object Name -NotMatch '^docker-desktop'
    if ($Distro -notin $distros.Name) {
        Write-Warning "The specified distro does not exist ($Distro)."
        exit
    }

    # determine update ca parameters depending on distro
    $sysId = wsl.exe -d $Distro --exec sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release
    switch -Regex ($sysId) {
        arch {
            $crt = @{
                path = '/etc/ca-certificates/trust-source/anchors'
                cmnd = 'trust extract-compat'
            }
            break
        }
        fedora {
            $crt = @{
                path = '/etc/pki/ca-trust/source/anchors'
                cmnd = 'update-ca-trust'
            }
            break
        }
        'debian|ubuntu' {
            $crt = @{
                path = '/usr/local/share/ca-certificates'
                cmnd = 'update-ca-certificates'
            }
            $cmnd = [string]::Join(' ',
                'type update-ca-certificates &>/dev/null',
                '|| (export DEBIAN_FRONTEND=noninteractive',
                '&& apt-get update',
                '&& apt-get install -y ca-certificates)'
            )
            wsl -d $Distro -u root --exec bash -c $cmnd
            break
        }
        opensuse {
            $crt = @{
                path = '/usr/share/pki/trust/anchors'
                cmnd = 'update-ca-certificates'
            }
            break
        }
        default {
            Write-Warning "The specified distro is not supported ($Distro)."
            exit
        }
    }

    # create temp folder for saving certificates
    $tmpFolder = New-Item -Name ([System.IO.Path]::GetRandomFileName()) -ItemType Directory

    # instantiate set for storing intercepted certificates
    $certSet = [System.Collections.Generic.HashSet[System.Security.Cryptography.X509Certificates.X509Certificate2]]::new()
}

process {
    # intercept certificates from all uris
    foreach ($uri in $Uris) {
        try {
            Get-Certificate -Uri $Uri -BuildChain | Select-Object -Skip 1 | ForEach-Object {
                $certSet.Add($_) | Out-Null
            }
        } catch [System.Management.Automation.MethodInvocationException] {
            if ($_.Exception.Message -match 'No such host is known') {
                Write-Warning "No such host is known ($uri)."
            } else {
                $_.Exception.Message
            }
        } catch {
            $_.Exception.GetType().FullName
            $_
        }
    }
    # check if root certificate from chain is in the cert store
    Write-Host "`e[1mIntercepted certificates from TLS chain`e[0m"
    foreach ($cert in $certSet) {
        # calculate certificate file name
        $crtFile = "$($cert.Thumbprint).crt"
        Write-Host "`e[32m$crtFile :`e[0m $([regex]::Match($cert.Subject, '(?<=CN=)(.)+?(?=,|$)').Value)"
        $pem = $cert | ConvertTo-PEM -AddHeader
        [IO.File]::WriteAllText([IO.Path]::Combine($tmpFolder, $crtFile), $pem)
    }

    # copy certificates to the distro specific cert directory and install them
    $cmnd = "mkdir -p $($crt.path) && install -m 0644 $($tmpFolder.Name)/*.crt $($crt.path) && $($crt.cmnd)"
    wsl -d $Distro -u root --exec bash -c $cmnd

    # write ca-custom.crt with MITM proxy certificates only
    $bundleBuilder = [System.Text.StringBuilder]::new()
    foreach ($cert in $certSet) {
        $bundleBuilder.Append(($cert | ConvertTo-PEM -AddHeader)) | Out-Null
    }
    $bundlePath = [IO.Path]::Combine($tmpFolder, 'ca-custom.crt')
    [IO.File]::WriteAllText($bundlePath, $bundleBuilder.ToString().Replace("`r`n", "`n"))
    $userCertDir = '~/.config/certs'
    $cmndCustom = "mkdir -p $userCertDir && install -m 0644 $($tmpFolder.Name)/ca-custom.crt $userCertDir/"
    wsl -d $Distro --exec bash -c $cmndCustom

    # create ca-bundle.crt - symlink to system CA bundle (which already includes custom certs)
    $cmndBundle = @(
        "cd $userCertDir"
        'for f in /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt'
        'do if [ -f "$f" ]; then ln -sf "$f" ca-bundle.crt; break; fi'
        'done'
    ) -join '; '
    wsl -d $Distro --exec bash -c $cmndBundle
}

clean {
    if (Test-Path $tmpFolder -PathType Container) {
        Remove-Item $tmpFolder -Recurse -Force
    }
    Pop-Location
}
