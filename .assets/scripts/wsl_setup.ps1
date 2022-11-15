<#
.SYNOPSIS
Setting up fresh WSL distro.
.DESCRIPTION
You can use the script for:
- installing SSL certificates from the certificate chain (e.g. when self-signed certificates are used),
- installing base packages and setting up bash and pwsh shells,
- cloning GH repositories and setting up VSCode workspace.
When GH repositories cloning is used, you need to generate and add an SSH key to your GH account.

.PARAMETER Distro
Name of the WSL distro.
.PARAMETER ThemeFont
Choose if oh-my-posh prompt theme should use base or powerline fonts.
.PARAMETER Scope
Installation scope - valid values, and packages installed:
- base: curl, git, jq, tree, vim, oh-my-posh, pwsh, bat, exa, ripgrep
- k8s_basic: kubectl, helm, minikube, k3d, k9s, yq
- k8s_full: flux, kubeseal, kustomize, argorolloutts-cli
Every following option expands the scope.
.PARAMETER Account
GH account with the repositories to clone.
.PARAMETER Repos
List of repositories to clone into the WSL.
.PARAMETER AddRootCert
Switch for installing root CA certificate. It should be used separately from other options.

.EXAMPLE
$Distro    = 'fedora'
$ThemeFont = 'powerline'
$Scope     = 'k8s_basic'
$Account   = 'szymonos'
$Repos = @(
    'devops-scripts'
    'ps-szymonos'
    'vagrant-scripts'
)
~install root certificate in specified distro
.assets/scripts/wsl_setup.ps1 $Distro -AddRootCert
~install packages and setup profile
.assets/scripts/wsl_setup.ps1 $Distro -t $ThemeFont -s $Scope
~install packages, setup profiles and clone repositories
.assets/scripts/wsl_setup.ps1 $Distro -a $Account -r $Repos -t $ThemeFont -s $Scope
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [Parameter(ParameterSetName = 'Default')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateSet('base', 'powerline')]
    [string]$ThemeFont = 'base',

    [Parameter(ParameterSetName = 'Default')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateSet('base', 'k8s_basic', 'k8s_full')]
    [string]$Scope = 'base',

    [Alias('a')]
    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [string]$Account,

    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [string[]]$Repos,

    [Alias('c')]
    [Parameter(Mandatory, ParameterSetName = 'AddCert')]
    [switch]$AddRootCert
)

# change temporarily encoding to utf-16 to match wsl output
[Console]::OutputEncoding = [System.Text.Encoding]::Unicode
$DistroExists = [bool](wsl.exe --list --quiet | Select-String -Pattern "\b$Distro\b")
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not $DistroExists) {
    Write-Warning "Specified distro doesn't exist!"
    break
}

if ($AddRootCert) {
    # determine update ca parameters depending on distro
    $sysId = wsl.exe -d $Distro --exec grep -oPm1 '^ID(_LIKE)?=\"?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release
    switch -Regex ($sysId) {
        arch {
            $crt = @{ path = '/etc/ca-certificates/trust-source/anchors'; cmd = 'trust extract-compat' }
            continue
        }
        fedora {
            $crt = @{ path = '/etc/pki/ca-trust/source/anchors'; cmd = 'update-ca-trust' }
            continue
        }
        'debian|ubuntu' {
            $crt = @{ path = '/usr/local/share/ca-certificates'; cmd = 'update-ca-certificates' }
            wsl -d $Distro -u root --exec bash -c 'type update-ca-certificates &>/dev/null || (export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y ca-certificates)'
            continue
        }
        opensuse {
            $crt = @{ path = '/usr/share/pki/trust/anchors'; cmd = 'update-ca-certificates' }
            continue
        }
    }
    # get certificate chain
    $chain = ((Out-Null | openssl s_client -showcerts -connect www.google.com:443) -join "`n" 2>$null | Select-String '-{5}BEGIN [\S\n]+ CERTIFICATE-{5}' -AllMatches).Matches.Value
    # save root certificate run command to update certificates
    New-Item '.tmp' -ItemType Directory -ErrorAction SilentlyContinue
    for ($i = 1; $i -lt $chain.Count; $i++) {
        $certRawData = [Convert]::FromBase64String(($chain[$i] -replace ('-.*-')).Trim())
        $subject = [Security.Cryptography.X509Certificates.X509Certificate]::new($certRawData).Subject
        $cn = ($subject | Select-String '(?<=CN=)(.)+?(?=,)').Matches.Value.Replace(' ', '_').Trim('"')
        [IO.File]::WriteAllText(".tmp/$cn.crt", $chain[$i])
    }
    wsl -d $Distro -u root --exec bash -c "mkdir -p $($crt.path) && mv -f .tmp/*.crt $($crt.path) 2>/dev/null && chmod 644 $($crt.path)/*.crt && $($crt.cmd)"
} else {
    # *install packages
    switch -Regex ($Scope) {
        'base|k8s_basic|k8s_full' {
            Write-Host 'installing base packages...' -ForegroundColor Green
            wsl.exe --distribution $Distro --user root --exec .assets/provision/upgrade_system.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_base.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_omp.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_pwsh.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_bat.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_exa.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_ripgrep.sh
        }
        'k8s_basic|k8s_full' {
            Write-Host 'installing kubernetes base packages...' -ForegroundColor Green
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubectl.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_helm.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_minikube.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k3d.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k9s.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_yq.sh
        }
        k8s_full {
            Write-Host 'installing kubernetes additional packages...' -ForegroundColor Green
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_flux.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubeseal.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kustomize.sh
            wsl.exe --distribution $Distro --user root --exec .assets/provision/install_argorolloutscli.sh
        }
    }

    # *copy files
    # calculate variables
    Write-Host 'copying files...' -ForegroundColor Green
    $OMP_THEME = switch ($ThemeFont) {
        base {
            '.assets/config/omp_cfg/theme.omp.json'
            continue
        }
        powerline {
            '.assets/config/omp_cfg/theme-pl.omp.json'
            continue
        }
    }
    $SH_PROFILE_PATH = '/etc/profile.d'
    $PS_SCRIPTS_PATH = '/usr/local/share/powershell/Scripts'
    $OH_MY_POSH_PATH = '/usr/local/share/oh-my-posh'

    # bash aliases
    wsl.exe --distribution $Distro --user root --exec bash -c "cp -f .assets/config/bash_cfg/bash_aliases* $SH_PROFILE_PATH && chmod 644 $SH_PROFILE_PATH/bash_aliases*"
    # oh-my-posh theme
    wsl.exe --distribution $Distro --user root --exec bash -c "mkdir -p $OH_MY_POSH_PATH && cp -f $OMP_THEME $OH_MY_POSH_PATH/theme.omp.json && chmod 644 $OH_MY_POSH_PATH/theme.omp.json"
    # PowerShell profile
    wsl.exe --distribution $Distro --user root --exec pwsh -nop -c 'cp -f .assets/config/pwsh_cfg/profile.ps1 $PROFILE.AllUsersAllHosts && chmod 644 $PROFILE.AllUsersAllHosts'
    # PowerShell functions
    wsl.exe --distribution $Distro --user root --exec bash -c "mkdir -p $PS_SCRIPTS_PATH && cp -f .assets/config/pwsh_cfg/ps_aliases* $PS_SCRIPTS_PATH && chmod 644 $PS_SCRIPTS_PATH/ps_aliases*"
    # remove kubectl aliases
    if ($Scope -notin @('k8s_basic', 'k8s_full')) {
        wsl.exe --distribution $Distro --user root --exec rm -f $SH_PROFILE_PATH/bash_aliases_kubectl $PS_SCRIPTS_PATH/ps_aliases_kubectl.ps1
    }

    # *setup profiles
    Write-Host 'setting up profile for all users...' -ForegroundColor Green
    wsl.exe --distribution $Distro --user root --exec pwsh -nop -f .assets/provision/setup_profiles_allusers.ps1
    wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profiles_allusers.sh
    wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_omp.sh
    Write-Host 'setting up profile for current user...' -ForegroundColor Green
    wsl.exe --distribution $Distro --exec pwsh -nop -f .assets/provision/setup_profiles_user.ps1
    wsl.exe --distribution $Distro --exec .assets/provision/setup_profiles_user.sh

    # *setup GitHub repositories
    if ($Repos) {
        Write-Host 'setting up GitHub repositories...' -ForegroundColor Green
        wsl.exe --distribution $Distro --exec pwsh -nop -f .assets/provision/setup_gh_repos.ps1 -d $Distro -r "$Repos" -g $Account -w $env:USERNAME
    }
}
