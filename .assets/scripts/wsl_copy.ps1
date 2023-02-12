<#
.SYNOPSIS
Copy files between WSL distributions.

.PARAMETER Source
Source Distro:Path. Path needs to be absolute or starts in ~ home directory.
.PARAMETER Destination
Destination Distro:Path.
.PARAMETER Root
Copy files as root.

.EXAMPLE
$Source = 'Debian:~/source'
$Destination = 'Ubuntu:~'

.assets/scripts/wsl_copy.ps1 $Source $Destination
.assets/scripts/wsl_copy.ps1 $Source $Destination -Root
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript( { $_ -match '^[\w-]+:(/|~)' } )]
    [string]$Source,

    [Parameter(Mandatory, Position = 1)]
    [string]$Destination,

    [switch]$Root
)

# *calculate source and destination distros and paths
$srcDistro, $srcPath = $Source.Split(':')
$dstDistro, $dstPath = $Destination.Split(':')

# *check if specified distros exist
[string[]]$distros = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss `
| ForEach-Object { $_.GetValue('DistributionName') } `
| Where-Object { $_ -notmatch '^docker-desktop' }
if ($srcDistro -notin $distros) {
    Write-Warning "The specified distro does not exist ($srcDistro)."
    exit
} elseif ($dstDistro -notin $distros) {
    Write-Warning "The specified distro does not exist ($dstDistro)."
    exit
}

# *resolve source path
$rlPath = if ($Root) {
    wsl.exe -d $srcDistro --user root --exec bash -c "readlink -e $srcPath"
} else {
    wsl.exe -d $srcDistro --exec bash -c "readlink -e $srcPath"
}
if (-not $rlPath) {
    Write-Warning "Source path is incorrect ($srcPath)."
    exit
}
# calculate source path
$mntDir = "/mnt/wsl/$srcDistro"
$srcPath = $mntDir + $rlPath

# *bind mount root filesystem of the source distro
$cmd = "findmnt $mntDir >/dev/null || mkdir -p $mntDir && mount --bind / $mntDir"
wsl.exe -d $srcDistro --user root --exec bash -c $cmd

# *copy files
$cmd = @"
dst="`$(readlink -m $dstPath)"
if [[ -f '$srcPath' ]] && [[ "`$(basename '$srcPath')" = "`$(basename `$dst)" ]]; then
    mkdir -p "`$(dirname `$dst)"
else
    mkdir -p "`$dst"
fi
cp -rf "$srcPath" "`$dst"
"@
if ($Root) {
    wsl.exe -d $dstDistro --user root --exec bash -c $cmd
} else {
    wsl.exe -d $dstDistro --exec bash -c $cmd
}
