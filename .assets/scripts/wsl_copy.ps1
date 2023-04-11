<#
.SYNOPSIS
Copy files between WSL distributions.

.PARAMETER Source
Source written using the <distro>:<path> convention.
Path needs to be absolute or starts in ~ home directory.
.PARAMETER Destination
Destination written using the <distro>:<path> convention.
You can specify only the destination <distro> and the source path will be used.
.PARAMETER Root
Copy files as root.

.EXAMPLE
$Source = 'Debian:~/source'
# ~ copy to the same path in destination distro
$Destination = 'Ubuntu'
# ~ copy to other specified path in destination distro
$Destination = 'Ubuntu:~/myfiles'

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
if (-not $dstPath) {
    $dstPath = $srcPath
}

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
if [ "`$(basename '$srcPath')" = "`$(basename $dstPath)" ]; then
    dst="`$(readlink -m `$(dirname $dstPath))"
else
    dst="`$(readlink -m $dstPath)"
fi
mkdir -p "`$dst" && cp -rf "$srcPath" "`$dst"
"@
if ($Root) {
    wsl.exe -d $dstDistro --user root --exec bash -c $cmd
} else {
    wsl.exe -d $dstDistro --exec bash -c $cmd
}
