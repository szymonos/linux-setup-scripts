#!/usr/bin/pwsh -nop
#Requires -PSEdition Core
<#
.SYNOPSIS
Creates bash script to install certificates from chain in the vagrant box
and adds the script invocation into the specified Vagrantfile.

.PARAMETER Path
Path to the Vagrantfile.

.EXAMPLE
$Path = 'vagrant/hyperv/fedora/Vagrantfile'
.assets/scripts/vg_certs_add.ps1 -p $Path

.NOTES
# :save script example
./scripts_egsave.ps1 .assets/scripts/vg_certs_add.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 .assets/scripts/vg_certs_add.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 .assets/scripts/vg_certs_add.ps1 -WriteOutput)
#>
[CmdletBinding()]
[OutputType([System.Void])]
param (
    [Parameter()]
    [ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
    [string]$Path
)

$ErrorActionPreference = 'Stop'

# set location to workspace folder
Push-Location "$PSScriptRoot/../.."

# import SetupUtils for the Set-WslConf function
Import-Module (Convert-Path './modules/SetupUtils') -Force

function Get-SshInstallScript ([string]$CertSaveStr) {
    $script = [string]::Join("`n",
        "#!/usr/bin/env bash`n",
        '# determine system id',
        'SYS_ID="$(sed -En ''/^ID.*(alpine|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}'' /etc/os-release)"',
        'case $SYS_ID in',
        'arch)',
        "  CERT_PATH=/etc/ca-certificates/trust-source/anchors`n  ;;",
        'fedora)',
        "  CERT_PATH=/etc/pki/ca-trust/source/anchors`n  ;;",
        'debian | ubuntu)',
        "  CERT_PATH=/usr/local/share/ca-certificates`n  ;;",
        'opensuse)',
        "  CERT_PATH=/usr/share/pki/trust/anchors`n  ;;",
        '*)',
        "  exit 0`n  ;;",
        "esac`n",
        '# write certificate in CERT_PATH',
        "$CertSaveStr",
        '# update certificates',
        'case $SYS_ID in',
        'arch)',
        "  trust extract-compat`n  ;;",
        'fedora)',
        "  update-ca-trust`n  ;;",
        'debian | ubuntu | opensuse)',
        "  update-ca-certificates`n  ;;",
        'esac'
    )

    return $script
}

$scriptInstallRootCA = [IO.Path]::Combine($PWD, '.tmp', 'script_install_crt_chain.sh')
# *Content of specified Vagrantfile
$Path = Resolve-Path $Path
$content = [IO.File]::ReadAllLines($Path)

# intercept certificates from chain and filter out existing ones
$chain = Get-Certificate -Uri 'gems.hashicorp.com' -BuildChain | Select-Object -Skip 1

# create installation script
New-Item (Split-Path $scriptInstallRootCA) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
# instantiate string builder to store the certificates
$builder = [System.Text.StringBuilder]::new()
foreach ($cert in $chain) {
    $pem = $cert | ConvertTo-PEM
    $builder.AppendLine("cat <<EOF >`"`$CERT_PATH/$($cert.Thumbprint).crt`"") | Out-Null
    $builder.AppendLine($pem.Trim()) | Out-Null
    $builder.AppendLine('EOF') | Out-Null
}
# save certificate installation file
[IO.File]::WriteAllText($scriptInstallRootCA, (Get-SshInstallScript $builder.ToString()))

# add cert installation shell command to Vagrantfile
if (-not ($content | Select-String -SimpleMatch 'script_install_crt_chain.sh')) {
    $idx = "$($content -match '# node provision')".IndexOf('#')
    $content = $content -replace '(# node provision)', "`$1`n$(' ' * $idx)node.vm.provision `"shell`", name: `"install certificate chain...`", path: `"../../../.tmp/script_install_crt_chain.sh`""
    # save updated Vagrantfile
    [IO.File]::WriteAllLines($Path, $content)
}
