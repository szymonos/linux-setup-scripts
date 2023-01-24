#!/usr/bin/env -S pwsh -nop
<#
.SYNOPSIS
Clone specified GitHub repositories into ~/source/repos folder.

.PARAMETER Repos
List of GitHub repositories in format "Owner/RepoName" to clone into the WSL.
.PARAMETER WorkspaceSuffix
Workspace suffix to build the name in format "DistroName-WorkspaceSuffix".
.PARAMETER UserName
Windows user name to copy ssh keys from.

.EXAMPLE
$Repos = 'szymonos/vagrant-scripts szymonos/ps-modules'
$User  = 'szymo'
.assets/provision/setup_gh_repos.ps1 $Repos -u $User
.assets/provision/setup_gh_repos.ps1 $Repos -u $User -WorkspaceSuffix 'scripts'
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ -not ($_.Split().ForEach({ $_ -match '^[\w-]+/[\w-]+$' }) -contains $false) }, ErrorMessage = 'Repos should be provided in "Owner/RepoName" format.')]
    [string]$Repos,

    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceSuffix = 'devops',

    [string]$UserName
)
$ErrorActionPreference = 'SilentlyContinue'

[string[]]$Repos = "$Repos".Split()

# *copy ssh keys on WSL
if ($env:WSL_DISTRO_NAME) {
    $distro = $env:WSL_DISTRO_NAME
    if ($UserName) {
        Write-Host 'copying ssh keys from the host...' -ForegroundColor DarkGreen
        New-Item ~/.ssh -ItemType Directory | Out-Null
        Copy-Item /mnt/c/Users/$UserName/.ssh/id_* ~/.ssh/
        chmod 400 ~/.ssh/id_*
    }
} else {
    $distro = (Select-String '(?<=^ID=).+' -Path /etc/os-release).Matches.Value.Trim("'`" ")
}
$ws_path = "$HOME/source/workspaces/$($distro.ToLower())-$($WorkspaceSuffix.ToLower()).code-workspace"

# *add github.com to known_hosts
$knownHosts = "$HOME/.ssh/known_hosts"
$keysExist = try { Select-String 'github.com' $knownHosts -Quiet } catch { $false }
if (-not $keysExist) {
    Write-Host 'adding github public keys...' -ForegroundColor DarkGreen
    [string[]]$ghKeys = ssh-keyscan 'github.com' 2>$null
    [IO.File]::AppendAllLines($knownHosts, $ghKeys)
}

# *setup source folder
# create folders
New-Item $HOME/source/repos -ItemType Directory | Out-Null
New-Item $HOME/source/workspaces -ItemType Directory | Out-Null
Push-Location $HOME/source/repos

$ws = if (Test-Path $ws_path -PathType Leaf) {
    Get-Content $ws_path | ConvertFrom-Json
} else {
    [PSCustomObject]@{ folders = @() }
}

# clone repositories and add them to workspace file
Write-Host 'cloning repositories...' -ForegroundColor DarkGreen
foreach ($repo in $Repos) {
    $owner, $repo_name = $repo.Split('/')
    New-Item $owner -ItemType Directory | Out-Null
    Push-Location $owner
    git clone "git@github.com:$repo.git" 2>$null && Write-Host $repo
    if (-not ($ws.folders.path -match $repo) -and (Test-Path $repo_name -PathType Container)) {
        $ws.folders += [PSCustomObject]@{ name = $repo_name; path = "../repos/$repo" }
    }
    Pop-Location
}
[IO.File]::WriteAllText($ws_path, ($ws | ConvertTo-Json))
Pop-Location
