#Requires -RunAsAdministrator
<#
.SYNOPSIS
Install and set up the specified WSL distro.

.DESCRIPTION
The script will perform the following:
- install PowerShell Core if not present to intercept TLS certificates in chain,
- enable WSL feature on Windows if not yet enabled,
- install specified WSL distro from available online distros,
- set up the specified WSL distro with sane defaults,
- can fix networking issues on VPN by rewriting DNS settings from selected Windows network interface,
- can fix self-signed certificate in chain error, if the host is behind MITM proxy.

All setup related parameters are forwarded to the wsl/wsl_setup.ps1 script.

.PARAMETER Distro
Name of the WSL distro to install and set up.
.PARAMETER Scope
List of installation scopes. Valid values:
- az: azure-cli, azcopy, Az PowerShell module if pwsh scope specified; autoselects python scope
- bun: Bun - all-in-one JavaScript, TypeScript & JSX toolkit using JavaScriptCore engine
- conda: miniforge
- distrobox: (WSL2 only) - podman and distrobox
- docker: (WSL2 only) - docker, containerd buildx docker-compose
- gcloud: google-cloud-cli
- k8s_base: kubectl, kubelogin, k9s, kubecolor, kubectx, kubens
- k8s_dev: argorollouts, cilium, hubble, helm, flux, humioctl, kustomize and trivy cli tools; autoselects k8s_base scope
- k8s_ext: (WSL2 only) - minikube, k3d, kind local kubernetes tools; autoselects docker, k8s_base and k8s_dev scopes
- nodejs: Node.js JavaScript runtime environment using V8 engine
- pwsh: PowerShell Core and corresponding PS modules; autoselects shell scope
- python: uv, prek, pip, venv
- rice: btop, cmatrix, cowsay, fastfetch
- shell: bat, eza, oh-my-posh, ripgrep, yq, copilot-cli
- terraform: terraform, terrascan, tflint, tfswitch
- zsh: zsh shell with plugins
The shell scope is always installed, regardless of the specified scopes.
.PARAMETER OmpTheme
Specify to install oh-my-posh prompt theme engine and name of the theme to be used.
You can specify one of the three included profiles: base, powerline, nerd,
or use any theme available on the page: https://ohmyposh.dev/docs/themes/
.PARAMETER GtkTheme
Specify gtk theme for wslg. Available values: light, dark.
Default: automatically detects based on the system theme.
.PARAMETER Repos
List of GitHub repositories in format "Owner/RepoName" to clone into the WSL.
.PARAMETER AddCertificate
Intercept and add certificates from chain into selected distro.
.PARAMETER FixNetwork
Set network settings from the selected network interface in Windows.
.PARAMETER SkipRepoUpdate
Skip updating current repository before running the setup.
.PARAMETER WebDownload
Switch, whether to use web download for WSL distro installation instead of Microsoft Store.
This is useful when the Store download is very slow or unavailable.

.EXAMPLE
# :perform basic Ubuntu WSL setup
wsl/wsl_install.ps1 -Distro 'Ubuntu'
# :fix network in the Ubuntu WSL distro
wsl/wsl_install.ps1 -Distro 'Ubuntu' -FixNetwork
# :intercept and add certificates in chain
wsl/wsl_install.ps1 -Distro 'Ubuntu' -AddCertificate
# :set up WSL distro with specified installation scopes
$Scope = @('python')
$Scope = @('az', 'docker')
$Scope = @('az', 'conda', 'docker', 'gcloud', 'k8s_base')  # with gcloud cli
$Scope = @('az', 'docker', 'pwsh')
$Scope = @('az', 'docker', 'k8s_base', 'pwsh', 'terraform')
wsl/wsl_install.ps1 -Distro 'Ubuntu' -s $Scope
# :set up shell with the specified oh-my-posh theme
$OmpTheme = 'nerd'
wsl/wsl_install.ps1 -Distro 'Ubuntu' -s $Scope -o $OmpTheme
# :set up WSL distro and clone specified GitHub repositories
$Repos = @('szymonos/linux-setup-scripts')
wsl/wsl_install.ps1 -Distro 'Ubuntu' -r $Repos
# with the specified scope
wsl/wsl_install.ps1 -Distro 'Ubuntu' -r $Repos -s $Scope

.NOTES
# :save script example
./scripts_egsave.ps1 wsl/wsl_install.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 wsl/wsl_install.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 wsl/wsl_install.ps1 -WriteOutput)
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [Alias('s')]
    [ValidateScript(
        { $_.ForEach({ $_ -in @('az', 'bun', 'conda', 'distrobox', 'docker', 'gcloud', 'k8s_base', 'k8s_dev', 'k8s_ext', 'nodejs', 'oh_my_posh', 'pwsh', 'python', 'rice', 'shell', 'terraform', 'zsh') }) -notcontains $false },
        ErrorMessage = 'Wrong scope provided. Valid values: az bun conda distrobox docker gcloud k8s_base k8s_dev k8s_ext nodejs oh_my_posh pwsh python rice shell terraform zsh')
    ]
    [string[]]$Scope,

    [ValidateNotNullOrEmpty()]
    [string]$OmpTheme = 'base',

    [ValidateSet('light', 'dark')]
    [string]$GtkTheme,

    [ValidateScript(
        { $_.ForEach({ $_ -match '^[\w-]+/[\w-]+$' }) -notcontains $false },
        ErrorMessage = 'Repos should be provided in "Owner/RepoName" format.')
    ]
    [string[]]$Repos,

    [switch]$AddCertificate,

    [switch]$FixNetwork,

    [switch]$SkipRepoUpdate,

    [switch]$WebDownload
)

begin {
    $ErrorActionPreference = 'Stop'
    # check if the script has been executed on Windows
    if ($IsLinux) {
        Write-Warning 'This script is intended to be run on Windows only (outside of WSL).'
        exit 1
    }

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
    # import utils-install for the Update-GitRepository function
    Import-Module (Resolve-Path './modules/utils-install') -Force
    # import psm-windows for the Update-SessionEnvironmentPath function
    Import-Module (Resolve-Path './modules/psm-windows') -Force

    if (-not $PSBoundParameters.SkipRepoUpdate) {
        Write-Host 'checking if the repository is up to date...' -ForegroundColor Cyan
        if ((Update-GitRepository) -eq 2) {
            Write-Host "`nRun the script again!" -ForegroundColor Yellow
            exit 0
        }
    }

    # update environment paths
    Update-SessionEnvironmentPath
    # WSL feature name
    $features = @('VirtualMachinePlatform', 'Microsoft-Windows-Subsystem-Linux')
    # name of the environment variable used to pass parameters to the setup script
    $paramsEnvVar = 'WSL_SETUP_PARAMS'
}

process {
    # *Check if WSL Feature is enabled
    $wslFeat = Get-WindowsOptionalFeature -FeatureName $features[0] -Online
    if ($wslFeat.State -ne 'Enabled') {
        $wslFeat = Enable-WindowsOptionalFeature -FeatureName $features -Online
    }
    # *Check if restart is needed
    if ($wslFeat.RestartNeeded) {
        Write-Host 'Required features enabled and system restart is needed.'
        Write-Host "`nRestart the system and run the script again to install the specified WSL distro!`n" -ForegroundColor Yellow
        exit 0
    }

    # *Perform WSL update
    wsl.exe --update

    # *Check the current default version
    $gpParam = @{
        Path        = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss'
        ErrorAction = 'SilentlyContinue'
    }
    $wslDefaultVersion = (Get-ItemProperty @gpParam).DefaultVersion
    if ($wslDefaultVersion -eq 1) {
        Write-Warning 'You are currently using WSL version 1 as default.'
        if ((Read-Host -Prompt 'Would you like to switch to WSL 2 (may break current distro)? [y/N]') -eq 'y') {
            Write-Host 'Setting the default version to WSL 2.'
            wsl.exe --set-default-version 2
        } else {
            Write-Host 'Keeping the default WSL 1 version.'
        }
    } elseif ($null -eq $wslDefaultVersion) {
        wsl.exe --set-default-version 2 | Out-Null
    }

    # *Install PowerShell
    try {
        Get-Command pwsh.exe -CommandType Application | Out-Null
    } catch {
        wsl/pwsh_setup.ps1
        # update environment paths
        Update-SessionEnvironmentPath
    }

    # *Set up WSL
    # build parameters for the setup script, always including the shell scope
    # and skipping the repository update, as it has been already done above
    $setupParams = @{
        Distro         = $Distro
        Scope          = [string[]]($Scope + 'shell' | Sort-Object -Unique)
        OmpTheme       = $OmpTheme
        SkipRepoUpdate = $true
    }
    # forward the specified optional parameters
    foreach ($param in @('GtkTheme', 'Repos')) {
        if ($PSBoundParameters.ContainsKey($param)) {
            $setupParams[$param] = $PSBoundParameters[$param]
        }
    }
    # forward the specified switches as booleans, so they can be splatted after deserialization
    foreach ($param in @('AddCertificate', 'FixNetwork', 'WebDownload')) {
        if ($PSBoundParameters[$param]) {
            $setupParams[$param] = $true
        }
    }
    # try/finally: guarantee the process-scoped env var never outlives this script,
    # even if a terminating error strikes between setting and consuming it - which
    # would otherwise leak it into the caller's session, since a terminating error
    # here skips the `end` block rather than falling through to it.
    try {
        # pass the parameters as JSON in an environment variable, to splat them in the
        # child process without building and escaping a command line string
        [System.Environment]::SetEnvironmentVariable($paramsEnvVar, ($setupParams | ConvertTo-Json -Compress))
        # run the wsl_setup script
        pwsh.exe -NoProfile -Command "`$setupParams = `$env:$paramsEnvVar | ConvertFrom-Json -AsHashtable; wsl/wsl_setup.ps1 @setupParams"
    } finally {
        [System.Environment]::SetEnvironmentVariable($paramsEnvVar, $null)
    }
}

end {
    Pop-Location
}
