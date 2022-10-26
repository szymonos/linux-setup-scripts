<#
.SYNOPSIS
Setting up fresh WSL distro.
.EXAMPLE
$distro = 'Fedora'
$gh_user = 'szymonos'
$repos = 'devops-scripts,powershell-scripts,ps-szymonos,vagrant'
$scope = 'k8s_basic'
$theme_font = 'powerline'
~install packages and setup profile
.assets/scripts/setup_wsl.ps1 -d $distro -s $scope -f $theme_font
~install packages, setup profiles and clone repositories
.assets/scripts/setup_wsl.ps1 -d $distro -s $scope -f $theme_font -r $repos -g $gh_user
#>
[CmdletBinding()]
[CmdletBinding(DefaultParameterSetName = 'Default')]
param (
    [Alias('d')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Default')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'GitHub')]
    [string]$distro,

    [Alias('s')]
    [Parameter(Mandatory, Position = 1, ParameterSetName = 'Default')]
    [Parameter(Mandatory, Position = 1, ParameterSetName = 'GitHub')]
    [ValidateSet('base', 'k8s_basic', 'k8s_full')]
    [string]$scope = 'base',

    [Alias('f')]
    [Parameter(Mandatory, Position = 2, ParameterSetName = 'Default')]
    [Parameter(Mandatory, Position = 2, ParameterSetName = 'GitHub')]
    [ValidateSet('base', 'powerline')]
    [string]$theme_font = 'base',

    [Alias('r')]
    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [string]$repos,

    [Alias('g')]
    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [string]$gh_user
)

# change temporarily encoding to utf-16 to match wsl output
[Console]::OutputEncoding = [System.Text.Encoding]::Unicode
$distroExists = [bool](wsl.exe -l | Select-String -Pattern "\b$distro\b")
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not $distroExists) {
    Write-Warning "Specified distro doesn't exist!"
    break
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
    Write-Host "installing kubernetes base packages..." -ForegroundColor Green
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_kubectl.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_helm.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_minikube.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_k3d.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_k9s.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_yq.sh
}
if ($scope -eq 'k8s_full') {
    Write-Host "installing kubernetes additional packages..." -ForegroundColor Green
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_flux.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_kubeseal.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_kustomize.sh
    wsl.exe --distribution $distro --user root --exec .assets/provision/install_argorolloutscli.sh
}

# *copy files
# calculate variables
Write-Host "copying files..." -ForegroundColor Green
$OMP_THEME = switch ($theme_font) {
    'base' {
        '.assets/config/theme.omp.json'
    }
    'powerline' {
        '.assets/config/theme-pl.omp.json'
    }
}
$SH_PROFILE_PATH = '/etc/profile.d'
$PS_PROFILE_PATH = wsl.exe --distribution $distro --exec pwsh -nop -c '[IO.Path]::GetDirectoryName($PROFILE.AllUsersAllHosts)'
$PS_SCRIPTS_PATH = '/usr/local/share/powershell/Scripts'
$OH_MY_POSH_PATH = '/usr/local/share/oh-my-posh'

# bash aliases
wsl.exe --distribution $distro --user root --exec cp .assets/config/bash_aliases $SH_PROFILE_PATH
wsl.exe --distribution $distro --user root --exec chmod 644 $SH_PROFILE_PATH/bash_aliases
# oh-my-posh theme
wsl.exe --distribution $distro --user root --exec mkdir -p $OH_MY_POSH_PATH
wsl.exe --distribution $distro --user root --exec cp -f $OMP_THEME "$OH_MY_POSH_PATH/theme.omp.json"
wsl.exe --distribution $distro --user root --exec chmod 644 "$OH_MY_POSH_PATH/theme.omp.json"
# PowerShell profile
wsl.exe --distribution $distro --user root --exec cp -f .assets/config/profile.ps1 $PS_PROFILE_PATH
wsl.exe --distribution $distro --user root --exec chmod 644 "$PS_PROFILE_PATH/profile.ps1"
# PowerShell functions
wsl.exe --distribution $distro --user root --exec mkdir -p $PS_SCRIPTS_PATH
wsl.exe --distribution $distro --user root --exec cp -f .assets/config/ps_aliases_common.ps1 $PS_SCRIPTS_PATH
wsl.exe --distribution $distro --user root --exec chmod 644 "$PS_SCRIPTS_PATH/ps_aliases_common.ps1"
# git functions
wsl.exe --distribution $distro --user root --exec cp -f .assets/config/bash_aliases_git $SH_PROFILE_PATH
wsl.exe --distribution $distro --user root --exec chmod 644 "$SH_PROFILE_PATH/bash_aliases_git"
wsl.exe --distribution $distro --user root --exec cp -f .assets/config/ps_aliases_git.ps1 $PS_SCRIPTS_PATH
wsl.exe --distribution $distro --user root --exec chmod 644 "$PS_SCRIPTS_PATH/ps_aliases_git.ps1"
# kubectl functions
if ($scope -in @('k8s_basic', 'k8s_full')) {
    wsl.exe --distribution $distro --user root --exec cp -f .assets/config/bash_aliases_kubectl $SH_PROFILE_PATH
    wsl.exe --distribution $distro --user root --exec chmod 644 "$SH_PROFILE_PATH/bash_aliases_kubectl"
    wsl.exe --distribution $distro --user root --exec cp -f .assets/config/ps_aliases_kubectl.ps1 $PS_SCRIPTS_PATH
    wsl.exe --distribution $distro --user root --exec chmod 644 "$PS_SCRIPTS_PATH/ps_aliases_kubectl.ps1"
}

# *setup profiles
Write-Host "setting up profile for all users..." -ForegroundColor Green
wsl.exe --distribution $distro --user root --exec .assets/provision/setup_profiles_allusers.sh
Write-Host "setting up profile for current user..." -ForegroundColor Green
wsl.exe --distribution $distro --exec .assets/provision/setup_profiles_user.sh

# *setup GitHub repositories
if ($repos) {
    Write-Host "setting up GitHub repositories..." -ForegroundColor Green
    wsl.exe --distribution $distro --exec .assets/provision/setup_gh_repos.sh "$($distro.ToLower())" "$repos" "$gh_user" "$env:USERNAME"
}
