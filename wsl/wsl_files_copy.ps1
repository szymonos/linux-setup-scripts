#Requires -PSEdition Core -Version 7.3
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
$Source = 'Debian:~/.ssh/config'
# :copy to the same path in destination distro
$Destination = 'Ubuntu'
# :copy to other specified path in destination distro
$Destination = 'Ubuntu:~/myfiles'

wsl/wsl_files_copy.ps1 $Source $Destination
wsl/wsl_files_copy.ps1 $Source $Destination -Root

.NOTES
# :save script example
./scripts_egsave.ps1 wsl/wsl_files_copy.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 wsl/wsl_files_copy.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 wsl/wsl_files_copy.ps1 -WriteOutput)
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

    # instantiate wsl command arguments variable
    $wslArgs = [System.Collections.Generic.List[string]]::new()
    # get information from the source distro
    $wslArgs.AddRange([string[]]@('--distribution', $srcDistro))
    if ($Root) {
        $wslArgs.AddRange([string[]]@('--user', 'root'))
    }
    $wslArgs.AddRange([string[]]@('--exec', 'bash'))
}

process {
    $wslArgs.AddRange([string[]]@('-c', "readlink -e $srcPath"))
    $rlPath = & wsl.exe @wslArgs

    if ($rlPath) {
        $srcPath = $mntDir + $rlPath
    } else {
        Write-Warning "Source path is incorrect ($srcPath)."
        exit
    }

    # bind mount root filesystem of the source distro
    $cmnd = "findmnt $mntDir >/dev/null || mkdir -p $mntDir && mount --bind / $mntDir"
    & wsl.exe -d $srcDistro --user root --exec bash -c $cmnd

    # move source files to tmp dir if distros are using different user ids
    if ($useTmp) {
        $wslArgs[-1] = "mkdir -p /tmp/cpf && mv `"$($rlPath)`" /tmp/cpf"
        & wsl.exe @wslArgs
        $srcPath = "$mntDir/tmp/cpf/$(Split-Path $rlPath -Leaf)"
    }

    # copy files
    $wslArgs[1] = $dstDistro
    $wslArgs[-1] = [string]::Join("`n",
        "if [ `"`$(basename $srcPath)`" = `"`$(basename $dstPath)`" ]; then",
        "`tdst=`"`$(readlink -m `$(dirname $dstPath))`"`nelse",
        "`tdst=`"`$(readlink -m $dstPath)`"`nfi",
        "mkdir -p `"`$dst`" && cp -rf `"$srcPath`" `"`$dst`""
    )
    & wsl.exe @wslArgs
}

clean {
    # move source to original location
    if ($useTmp) {
        $wslArgs[1] = $srcDistro
        $wslArgs[-1] = = "mv `"/tmp/cpf/$(Split-Path $srcPath -Leaf)`" `"$($rlPath)`" && rm -fr /tmp/cpf"
        & wsl.exe @wslArgs
    }
}
