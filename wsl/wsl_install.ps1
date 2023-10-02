<#
.SYNOPSIS
Script synopsis.
.EXAMPLE
# :perform basic Ubuntu WSL setup
wsl/wsl_install.ps1 -Distro 'Ubuntu'
# :fix network in the Ubuntu WSL distro
wsl/wsl_install.ps1 -Distro 'Ubuntu' -FixNetwork
# :set up WSL distro with specified installation scopes
$Scope = @('python')
$Scope = @('az', 'docker')
wsl/wsl_install.ps1 -Distro 'Ubuntu' -s $Scope
# :set up WSL distro and clone specified GitHub repositories
$Repos = @('szymonos/linux-setup-scripts')
wsl/wsl_install.ps1 -Distro 'Ubuntu' -s $Scope -r $Repos
#>
[CmdletBinding(DefaultParameterSetName = 'Setup')]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateScript({ $_.ForEach({ $_ -in @('az', 'docker', 'python') }) -notcontains $false })]
    [string[]]$Scope,

    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [ValidateScript({ $_.ForEach({ $_ -match '^[\w-]+/[\w-]+$' }) -notcontains $false })]
    [string[]]$Repos,

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [switch]$FixNetwork
)

begin {
    $ErrorActionPreference = 'Stop'

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
    # import InstallUtils for the Update-SessionEnvironmentPath function
    Import-Module (Resolve-Path './modules/InstallUtils')
    # update environment paths
    Update-SessionEnvironmentPath
}

process {
    # *Install PowerShell
    try {
        Get-Command pwsh.exe -CommandType Application | Out-Null
    } catch {
        $scriptPath = Resolve-Path wsl/pwsh_setup.ps1
        if (Test-IsAdmin) {
            & $scriptPath
            # update environment paths
            Update-SessionEnvironmentPath
        } else {
            Start-Process powershell.exe "-NoProfile -File `"$scriptPath`"" -Verb RunAs
            Write-Host "`nInstalling PowerShell Core. Complete the installation and run the script again!`n" -ForegroundColor Yellow
            exit 0
        }
    }

    # *Set up WSL
    $cmd = "wsl/wsl_setup.ps1 -Distro '$Distro'"
    if ($Scope) { $cmd += " -Scope @($($Scope.ForEach({ "'$_'" }) -join ','),'shell')" }
    if ($Repos) { $cmd += " -Repos @($($Repos.ForEach({ "'$_'" }) -join ','))" }
    if ($FixNetwork) { $cmd += ' -FixNetwork' }
    $cmd += ' -OmpTheme base -AddCertificate'
    pwsh.exe -NoProfile -Command $cmd
}

end {
    Pop-Location
}
