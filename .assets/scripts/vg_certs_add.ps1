#!/usr/bin/pwsh -nop
#Requires -PSEdition Core
<#
.SYNOPSIS
Script synopsis.

.PARAMETER Path
Path to the Vagrantfile.

.EXAMPLE
$Path = 'vagrant/hyperv/fedora/Vagrantfile'
.assets/scripts/vg_certs_add.ps1 -p $Path
#>

[CmdletBinding()]
[OutputType([System.Void])]
param (
    [Parameter()]
    [ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
    [string]$Path
)

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
        "# update certificates",
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

# create installation script
New-Item (Split-Path $scriptInstallRootCA) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
$chain = .assets/tools/cert_chain_pem.ps1

$builder = [System.Text.StringBuilder]::new()
foreach ($cert in $chain) {
    $builder.AppendLine("cat <<EOF >`"`$CERT_PATH/$($cert.Thumbprint).crt`"") | Out-Null
    $builder.AppendLine($cert.PEM.Trim()) | Out-Null
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
