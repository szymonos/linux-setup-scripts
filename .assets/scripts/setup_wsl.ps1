<#
.SYNOPSIS
Setting up fresh WSL distro.
.EXAMPLE
$distro     = 'fedoraremix'
$theme_font = 'powerline'
$scope      = 'k8s_basic'
$gh_user    = 'szymonos'
$repos = @(
    'devops-scripts'
    'ps-szymonos'
    'vagrant-scripts'
)
~install packages and setup profile
.assets/scripts/setup_wsl.ps1 $distro -t $theme_font
.assets/scripts/setup_wsl.ps1 $distro -t $theme_font -s $scope
~install packages, setup profiles and clone repositories
.assets/scripts/setup_wsl.ps1 $distro -t $theme_font -g $gh_user -r $repos
~install root certificate and install packages
.assets/scripts/setup_wsl.ps1 $distro -t $theme_font -AddRootCert
.assets/scripts/setup_wsl.ps1 $distro -t $theme_font -s $scope -AddRootCert
.assets/scripts/setup_wsl.ps1 $distro -t $theme_font -g $gh_user -r $repos -AddRootCert
.assets/scripts/setup_wsl.ps1 $distro -t $theme_font -g $gh_user -r $repos -s $scope -AddRootCert
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
param (
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Default')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'GitHub')]
    [string]$distro,

    [ValidateSet('base', 'powerline')]
    [string]$theme_font = 'base',

    [ValidateSet('base', 'k8s_basic', 'k8s_full')]
    [string]$scope = 'base',

    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [string]$gh_user,

    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [string[]]$repos,

    [switch]$AddRootCert
)

# change temporarily encoding to utf-16 to match wsl output
[Console]::OutputEncoding = [System.Text.Encoding]::Unicode
$distroExists = [bool](wsl.exe -l | Select-String -Pattern "\b$distro\b")
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not $distroExists) {
    Write-Warning "Specified distro doesn't exist!"
    break
}

if ($AddRootCert) {
    $sysId = wsl.exe -d $distro --exec grep -oPm1 '^ID(_LIKE)?=\"?\K(arch|fedora|debian|ubuntu|opensuse)' /etc/os-release
    if ($sysId -in @('debian', 'ubuntu')) {
        wsl -d $distro -u root --exec bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y ca-certificates"
    }
    # determine update ca parameters
    $sysCmd = switch -Regex ($sysId) {
        arch {
            @{
                CertPath    = '/etc/ca-certificates/trust-source/anchors'
                UpdateCaCmd = 'trust extract-compat'
            }
            continue
        }
        fedora {
            @{
                CertPath    = '/etc/pki/ca-trust/source/anchors'
                UpdateCaCmd = 'update-ca-trust'
            }
            continue
        }
        'debian|ubuntu' {
            @{
                CertPath    = '/usr/local/share/ca-certificates'
                UpdateCaCmd = 'update-ca-certificates'
            }
            continue
        }
        opensuse {
            @{
                CertPath    = '/usr/share/pki/trust/anchors'
                UpdateCaCmd = 'update-ca-certificates'
            }
            continue
        }
    }
    # get root certificate
    $chain = (Out-Null | openssl s_client -showcerts -connect www.google.com:443) -join "`n" 2>$null
    $root_cert = ($chain | Select-String '-{5}BEGIN [\S\n]+ CERTIFICATE-{5}' -AllMatches).Matches.Value[-1]
    # move cert to distro destination folder and update ca certificates
    wsl -d $distro -u root --exec bash -c "mkdir -p $($sysCmd.CertPath) && echo '$root_cert' >$($sysCmd.CertPath)/root_ca.crt && $($sysCmd.UpdateCaCmd)"
}

# *install packages
Write-Host 'installing base packages...' -ForegroundColor Green
wsl.exe --distribution $distro --user root --exec .assets/provision/install_base.sh
wsl.exe --distribution $distro --user root --exec .assets/provision/install_omp.sh
wsl.exe --distribution $distro --user root --exec .assets/provision/install_pwsh.sh
wsl.exe --distribution $distro --user root --exec .assets/provision/install_bat.sh
wsl.exe --distribution $distro --user root --exec .assets/provision/install_exa.sh
wsl.exe --distribution $distro --user root --exec .assets/provision/install_ripgrep.sh
if ($scope -in @('k8s_basic', 'k8s_full')) {
    Write-Host 'installing kubernetes base packages...' -ForegroundColor Green
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_kubectl.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_helm.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_minikube.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_k3d.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_k9s.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_yq.sh
}
if ($scope -eq 'k8s_full') {
    Write-Host 'installing kubernetes additional packages...' -ForegroundColor Green
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_flux.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_kubeseal.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_kustomize.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_argorolloutscli.sh
}

# *copy files
# calculate variables
Write-Host 'copying files...' -ForegroundColor Green
$OMP_THEME = switch ($theme_font) {
    'base' {
        '.assets/config/omp_cfg/theme.omp.json'
    }
    'powerline' {
        '.assets/config/omp_cfg/theme-pl.omp.json'
    }
}
$SH_PROFILE_PATH = '/etc/profile.d'
$PS_SCRIPTS_PATH = '/usr/local/share/powershell/Scripts'
$OH_MY_POSH_PATH = '/usr/local/share/oh-my-posh'

# bash aliases
wsl.exe --distribution $distro --user root --exec bash -c "cp -f .assets/config/bash_cfg/bash_aliases* $SH_PROFILE_PATH && chmod 644 $SH_PROFILE_PATH/bash_aliases*"
# oh-my-posh theme
wsl.exe --distribution $distro --user root --exec bash -c "mkdir -p $OH_MY_POSH_PATH && cp -f $OMP_THEME $OH_MY_POSH_PATH/theme.omp.json && chmod 644 $OH_MY_POSH_PATH/theme.omp.json"
# PowerShell profile
wsl.exe --distribution $distro --user root --exec pwsh -nop -c 'cp -f .assets/config/pwsh_cfg/profile.ps1 $PROFILE.AllUsersAllHosts && chmod 644 $PROFILE.AllUsersAllHosts'
# PowerShell functions
wsl.exe --distribution $distro --user root --exec bash -c "mkdir -p $PS_SCRIPTS_PATH && cp -f .assets/config/pwsh_cfg/ps_aliases* $PS_SCRIPTS_PATH && chmod 644 $PS_SCRIPTS_PATH/ps_aliases*"
# remove kubectl aliases
if ($scope -notin @('k8s_basic', 'k8s_full')) {
    wsl.exe --distribution $distro --user root --exec rm -f $SH_PROFILE_PATH/bash_aliases_kubectl $PS_SCRIPTS_PATH/ps_aliases_kubectl.ps1
}

# *setup profiles
Write-Host 'setting up profile for all users...' -ForegroundColor Green
wsl.exe --distribution $distro --user root --exec .assets/provision/setup_profiles_allusers.ps1
wsl.exe --distribution $distro --user root --exec .assets/provision/setup_profiles_allusers.sh
wsl.exe --distribution $distro --user root --exec .assets/provision/setup_omp.sh
Write-Host 'setting up profile for current user...' -ForegroundColor Green
wsl.exe --distribution $distro --exec .assets/provision/setup_profiles_user.ps1
wsl.exe --distribution $distro --exec .assets/provision/setup_profiles_user.sh

# *setup GitHub repositories
if ($repos) {
    Write-Host 'setting up GitHub repositories...' -ForegroundColor Green
    wsl.exe --distribution $distro --exec .assets/provision/setup_gh_repos.ps1 -d $distro -r "$repos" -g $gh_user -w $env:USERNAME
}
