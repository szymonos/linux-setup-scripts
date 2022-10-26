<#
.SYNOPSIS
Script synopsis.
.EXAMPLE
$Path = 'hyperv/FedoraHV/Vagrantfile'
.assets/scripts/add_ssl_certificate.ps1 -p $Path
#>

[CmdletBinding()]
[OutputType([System.Void])]
param (
    [Parameter()]
    [string]$Path
)

function Get-SshInstallScript ([string]$crt) {
    return @"
#!/bin/bash
# determine system id
SYS_ID=`$(grep -oPm1 '^ID(_LIKE)?=.*\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release)
case `$SYS_ID in
arch)
  CERT_PATH='/etc/ca-certificates/trust-source/anchors';;
fedora)
  CERT_PATH='/etc/pki/ca-trust/source/anchors';;
debian | ubuntu)
  CERT_PATH='/usr/local/share/ca-certificates';;
opensuse)
  CERT_PATH='/usr/share/pki/trust/anchors/';;
esac
# write certificate in CERT_PATH
cat <<EOF >`$CERT_PATH/root_ca.crt
$crt
EOF
# update certificates
case `$SYS_ID in
arch)
  trust extract-compat;;
fedora)
  update-ca-trust;;
debian | ubuntu | opensuse)
  update-ca-certificates;;
esac
"@
}

$scriptInstallRootCA = '.tmp/script_install_root_ca.sh'
# *Content of specified Vagrantfile
$content = [IO.File]::ReadAllLines($Path)

# create installation script
if (-not (Test-Path $scriptInstallRootCA -PathType Leaf)) {
    New-Item (Split-Path $scriptInstallRootCA) -ItemType Directory -ErrorAction SilentlyContinue
    $chain = (Out-Null | openssl s_client -showcerts -connect www.google.com:443) -join "`n"
    $crt = ($chain | Select-String '-{5}BEGIN [\S\n]+ CERTIFICATE-{5}' -AllMatches).Matches.Value[-1]
    # save certificate installation file
    [IO.File]::WriteAllText($scriptInstallRootCA, (Get-SshInstallScript $crt))
}

# add cert installation shell command to Vagrantfile
if (-not ($content | Select-String $scriptInstallRootCA)) {
    $idx = "$($content -match '# node provision')".IndexOf('#')
    $content = $content -replace '(# node provision)', "`$1`n$(' ' * $idx)node.vm.provision 'shell', name: 'install Root CA...', path: '../../.tmp/script_install_root_ca.sh'"
    # save updated Vagrantfile
    [IO.File]::WriteAllLines($Path, $content)
}
