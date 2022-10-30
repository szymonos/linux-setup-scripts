#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Script synopsis.
.EXAMPLE
$distro = 'Fedora'
$repos = "ps-szymonos vagrant"
$gh_user = 'szymonos'
$win_user = 'szymo'
.assets/provision/setup_gh_repos.ps1
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$distro,

    [Parameter(Mandatory)]
    [string]$repos,

    [Parameter(Mandatory)]
    [string]$gh_user,

    [Parameter(Mandatory)]
    [string]$win_user

)
$ErrorActionPreference = 'SilentlyContinue'

[string[]]$repos = "$repos".Split()
$ws_path = "$HOME/source/workspaces/$($distro.ToLower())-devops.code-workspace"

# *copy ssh keys on WSL
if ($env:WSL_DISTRO_NAME) {
    Write-Host 'copying ssh keys from the host...'
    New-Item ~/.ssh -ItemType Directory | Out-Null
    Copy-Item /mnt/c/Users/$win_user/.ssh/id_* ~/.ssh/
    chmod 400 ~/.ssh/id_*
}

# *add github.com to known_hosts
$knownHosts = "$HOME/.ssh/known_hosts"
$keysExist = try { Select-String 'github.com' $knownHosts -Quiet } catch { $false }
if (-not $keysExist) {
    Write-Host 'adding github public keys...'
    [string[]]$ghKeys = ssh-keyscan 'github.com' 2>$null
    [IO.File]::AppendAllLines($knownHosts, $ghKeys)
}

# *setup source folder
# create folders
New-Item ~/source/repos/$gh_user -ItemType Directory | Out-Null
New-Item ~/source/workspaces -ItemType Directory | Out-Null
# create workspace file
if (-not (Test-Path $ws_path -PathType Leaf)) {
    Set-Content $ws_path -Value "{`n`t`"folders`": [`n`t]`n}"
}
# clone repositories and add them to workspace file
Set-Location ~/source/repos/$gh_user
$content = [IO.File]::ReadAllText($ws_path).TrimEnd()
Write-Host 'cloning repositories...'
foreach ($repo in $repos) {
    git clone "git@github.com:$gh_user/$repo.git" 2>$null
    if ((Test-Path $repo -PathType Container) -and -not (Select-String -Pattern $repo -Path $ws_path -Quiet)) {
        $folder = "`t{`n`t`t`t`"name`": `"$repo`",`n`t`t`t`"path`": `"../repos/$gh_user/$repo`"`n`t`t},`n`t"
        $content = $content -replace ']', "$folder]"
    }
}
[IO.File]::WriteAllText($ws_path, $content)
