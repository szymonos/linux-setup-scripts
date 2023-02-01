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

begin {
    # calculate destination distro and path
    $dstDistro, $dstPath = $Destination.Split(':')
    # calculate source distro and paths
    $srcDistro, $path = $Source.Split(':')

    # get list of distros
    [string[]]$distros = (Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss).ForEach({ $_.GetValue('DistributionName') }).Where({ $_ -notmatch '^docker-desktop' })
    # check if specified distros exist
    if ($srcDistro -notin $distros) {
        Write-Warning "The specified distro does not exist ($srcDistro)."
        exit
    } elseif ($dstDistro -notin $distros) {
        Write-Warning "The specified distro does not exist ($dstDistro)."
        exit
    }

    # resolve ~ path for source distro
    if ($path -match '~') {
        $path = if ($Root) {
            wsl.exe -d $srcDistro --user root --exec bash -c "readlink -f $path"
        } else {
            wsl.exe -d $srcDistro --exec bash -c "readlink -f $path"
        }
    }
    if (-not [IO.Path]::IsPathRooted($path)) {
        Write-Warning "Source path is incorrect ($path)."
        exit
    }
    # calculate source path
    $mntDir = "/mnt/wsl/$srcDistro"
    $srcPath = [IO.Path]::Join($mntDir, $path)
}

process {
    # bind mount root filesystem of the source distro
    wsl.exe -d $srcDistro --user root --exec bash -c "findmnt $mntDir >/dev/null || mkdir -p $mntDir && mount --bind / $mntDir"

    # copy files
    if ($Root) {
        wsl.exe -d $dstDistro --user root --exec bash -c "cp -fr $srcPath $dstPath"
    } else {
        wsl.exe -d $dstDistro --exec bash -c "cp -fr $srcPath $dstPath"
    }
}

end {
    Write-Host 'Done.' -ForegroundColor Green
}
