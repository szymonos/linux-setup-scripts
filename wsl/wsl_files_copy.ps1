#Requires -PSEdition Core
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
$Source = 'Debian:~/.local/share'
$Source = 'Debian:~/.ssh'
$Source = 'Debian:~/.kube'
# :copy to the same path in destination distro
$Destination = 'Ubuntu'
# :copy to other specified path in destination distro
$Destination = 'Ubuntu:~/myfiles'

wsl/wsl_files_copy.ps1 $Source $Destination
wsl/wsl_files_copy.ps1 $Source $Destination -Root
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
    # check if the script is running on Windows
    if (-not $IsWindows) {
        Write-Warning 'Run the script on Windows!'
        exit 0
    }

    # import SetupUtils for the Get-WslDistro function
    Import-Module (Convert-Path './modules/SetupUtils')

    # calculate source and destination distros and paths
    $srcDistro, $srcPath = $Source.Split(':')
    $dstDistro, $dstPath = $Destination.Split(':')
    if (-not $dstPath) {
        $dstPath = $srcPath
    }

    # check if specified distros exist
    $distros = Get-WslDistro -FromRegistry
    if ($srcDistro -notin $distros.Name) {
        Write-Warning "Specified source distro does not exist ($srcDistro)."
        exit
    } elseif ($dstDistro -notin $distros.Name) {
        Write-Warning "Specified destination distro does not exist ($dstDistro)."
        exit
    }

    # calculate source mount path
    $mntDir = "/mnt/wsl/$srcDistro"

    # determine if distros using different user ids
    $srcDefUid = $distros.Where({ $_.Name -eq $srcDistro }).DefaultUid
    $dstDefUid = $distros.Where({ $_.Name -eq $dstDistro }).DefaultUid
    $useTmp = $srcDefUid -ne $dstDefUid ? $true : $false
}

process {
    # get information from the source distro
    $cmnd = "wsl.exe -d $srcDistro $($Root ? '--user root ' : '')--exec bash -c 'readlink -e $srcPath'"
    $rlPath = Invoke-Expression $cmnd
    if ($rlPath) {
        $srcPath = $mntDir + $rlPath
    } else {
        Write-Warning "Source path is incorrect ($srcPath)."
        exit
    }

    # bind mount root filesystem of the source distro
    $cmnd = "findmnt $mntDir >/dev/null || mkdir -p $mntDir && mount --bind / $mntDir"
    wsl.exe -d $srcDistro --user root --exec bash -c $cmnd

    # move source files to tmp dir if distros are using different user ids
    if ($useTmp) {
        $cmnd = "mkdir -p /tmp/cpf && mv `"$($rlPath)`" /tmp/cpf"
        Invoke-Expression "wsl.exe -d $srcDistro $($Root ? '--user root ' : '')--exec bash -c '$cmnd'"
        $srcPath = "$mntDir/tmp/cpf/$(Split-Path $rlPath -Leaf)"
    }

    # copy files
    $cmnd = [string]::Join("`n",
        "if [ `"`$(basename $srcPath)`" = `"`$(basename $dstPath)`" ]; then",
        "`tdst=`"`$(readlink -m `$(dirname $dstPath))`"`nelse",
        "`tdst=`"`$(readlink -m $dstPath)`"`nfi",
        "mkdir -p `"`$dst`" && cp -rf `"$srcPath`" `"`$dst`""
    )
    Invoke-Expression "wsl.exe -d $dstDistro $($Root ? '--user root ' : '')--exec bash -c '$cmnd'"
}

end {
    # move source to original location
    if ($useTmp) {
        $cmnd = "mv `"/tmp/cpf/$(Split-Path $srcPath -Leaf)`" `"$($rlPath)`" && rm -fr /tmp/cpf"
        Invoke-Expression "wsl.exe -d $srcDistro $($Root ? '--user root ' : '')--exec bash -c '$cmnd'"
    }
}
