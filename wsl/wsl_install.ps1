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
- can fix networkin issues on VPN by rewriting DNS settings from selected Windows network interface,
- can fix self-signed certificate in chain error, if the host is behind MITM proxy.

.PARAMETER Distro
Name of the WSL distro to install and set up.
.PARAMETER Scope
List of installation scopes. Valid values:
- az: azure-cli, Az PowerShell module if pwsh scope specified; autoselects conda scope
- conda: miniconda, uv, pip, venv
- distrobox: (WSL2 only) - podman and distrobox
- docker: (WSL2 only) - docker, containerd buildx docker-compose
- k8s_base: kubectl, kubelogin, cilium-cli, helm, k9s, kubeseal, flux, kustomize, kubectx, kubens
- k8s_ext: (WSL2 only) - minikube, k3d, argorollouts-cli; autoselects docker and k8s_base scopes
- nodejs: Node.js JavaScript runtime environment
- pwsh: PowerShell Core and corresponding PS modules; autoselects shell scope
- rice: btop, cmatrix, cowsay, fastfetch
- shell: bat, eza, oh-my-posh, ripgrep, yq
- terraform: terraform, terrascan, tfswitch
- zsh: zsh shell with plugins
.PARAMETER Repos
List of GitHub repositories in format "Owner/RepoName" to clone into the WSL.
.PARAMETER AddCertificate
Intercept and add certificates from chain into selected distro.
.PARAMETER FixNetwork
Set network settings from the selected network interface in Windows.

.EXAMPLE
# :perform basic Ubuntu WSL setup
wsl/wsl_install.ps1 -Distro 'Ubuntu'
# :fix network in the Ubuntu WSL distro
wsl/wsl_install.ps1 -Distro 'Ubuntu' -FixNetwork
# :set up WSL distro with specified installation scopes
$Scope = @('python')
$Scope = @('az', 'docker', 'shell')
$Scope = @('az', 'docker', 'pwsh')
$Scope = @('az', 'docker', 'k8s_base', 'pwsh', 'terraform')
wsl/wsl_install.ps1 -Distro 'Ubuntu' -s $Scope
# :set up WSL distro and clone specified GitHub repositories
$Repos = @('procter-gamble/de-cf-wsl-setup-scripts')
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

    [ValidateScript({ $_.ForEach({ $_ -in @('az', 'conda', 'distrobox', 'docker', 'k8s_base', 'k8s_ext', 'nodejs', 'oh_my_posh', 'pwsh', 'rice', 'shell', 'terraform', 'zsh') }) -notcontains $false })]
    [string[]]$Scope,

    [ValidateScript({ $_.ForEach({ $_ -match '^[\w-]+/[\w-]+$' }) -notcontains $false })]
    [string[]]$Repos,

    [switch]$AddCertificate,

    [switch]$FixNetwork
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
    # import InstallUtils for the Update-SessionEnvironmentPath function
    Import-Module (Resolve-Path './modules/InstallUtils') -Force

    Write-Host 'checking if the repository is up to date...' -ForegroundColor Cyan
    if ((Update-GitRepository) -eq 2) {
        Write-Host "`nRun the script again!" -ForegroundColor Yellow
        exit 0
    }

    # update environment paths
    Update-SessionEnvironmentPath
    # WSL feature name
    $features = @('VirtualMachinePlatform', 'Microsoft-Windows-Subsystem-Linux')
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
        if ((Read-Host -Prompt 'Would you like to switch to WSL 2 (recommended)? [Y/n]') -ne 'n') {
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
    # build command string
    $sb = [System.Text.StringBuilder]::new("wsl/wsl_setup.ps1 -Distro '$Distro'")
    if ($Scope) {
        $scopeStr = $Scope | Join-Str -Separator ',' -SingleQuote
        $sb.Append(" -Scope @($scopeStr,'shell')") | Out-Null
    }
    if ($Repos) {
        $reposStr = $Repos | Join-Str -Separator ',' -SingleQuote
        $sb.Append(" -Repos @($reposStr)") | Out-Null
    }
    if ($AddCertificate) { $sb.Append(' -AddCertificate') | Out-Null }
    $sb.Append(" -OmpTheme 'base'") | Out-Null
    $sb.Append(' -SkipRepoUpdate') | Out-Null
    # run the wsl_setup script
    pwsh.exe -NoProfile -Command $sb.ToString()
}

end {
    Pop-Location
}
