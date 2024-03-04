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
- az: azure-cli, do-az from ps-modules if pwsh scope specified; autoselects python scope
- docker: docker, containerd buildx docker-compose (WSL2 only)
- k8s_base: kubectl, kubelogin, helm, k9s, kubeseal, flux, kustomize
- k8s_ext: minikube, k3d, argorollouts-cli (WSL2 only); autoselects docker and k8s_base scopes
- pwsh: PowerShell Core and corresponding PS modules; autoselects shell scope
- python: pip, venv, miniconda
- shell: bat, eza, oh-my-posh, ripgrep, yq
- terraform: terraform, terrascan, tfswitch
- zsh: zsh shell with plugins
.PARAMETER Repos
List of GitHub repositories in format "Owner/RepoName" to clone into the WSL.
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
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [ValidateScript({ $_.ForEach({ $_ -in @('az', 'docker', 'k8s_base', 'k8s_ext', 'oh_my_posh', 'pwsh', 'python', 'shell', 'terraform', 'zsh') }) -notcontains $false })]
    [string[]]$Scope,

    [ValidateScript({ $_.ForEach({ $_ -match '^[\w-]+/[\w-]+$' }) -notcontains $false })]
    [string[]]$Repos,

    [switch]$AddCertificate,

    [switch]$FixNetwork
)

begin {
    $ErrorActionPreference = 'Stop'

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
    # import InstallUtils for the Update-SessionEnvironmentPath function
    Import-Module (Resolve-Path './modules/InstallUtils')

    Write-Host 'checking if the repository is up to date...' -ForegroundColor Cyan
    if ((Update-GitRepository) -eq 2) {
        Write-Host "`nRun the script again!" -ForegroundColor Yellow
        exit 0
    }

    # update environment paths
    Update-SessionEnvironmentPath
    # WSL feature name
    $wslFeat = @('VirtualMachinePlatform', 'Microsoft-Windows-Subsystem-Linux')
}

process {
    # *Check if WSL Feature is enabled
    if ((Test-IsAdmin) -and (Get-WindowsOptionalFeature -FeatureName $wslFeat[0] -Online).State -ne 'Enabled') {
        $enabled = Enable-WindowsOptionalFeature -FeatureName $wslFeat -Online
        if ($enabled.RestartNeeded) {
            Write-Host 'Microsoft-Windows-Subsystem-Linux feature enabled.'
            Write-Host "`nRestart the system and run the script again to install the specified WSL distro!`n" -ForegroundColor Yellow
            exit 0
        }
    }

    # *Check if WSL is updated
    wsl --version | Out-Null
    # perform initial update
    if (-not $?) { wsl.exe --update }
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
