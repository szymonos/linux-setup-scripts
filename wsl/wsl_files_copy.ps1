#Requires -PSEdition Core -Version 7.3
<#
.SYNOPSIS
Copy files between WSL distributions.

.PARAMETER SourceDistro
Name of the source WSL distribution to copy files from.
.PARAMETER DestinationDistro
Name of the destination WSL distribution to copy files to.
.PARAMETER Path
Path of the files to copy from the source distribution.
.PARAMETER DestinationPath
Path of the files to copy to the destination distribution.
.PARAMETER Root
Switch to run the command as root in the source distribution.

.EXAMPLE
$SourceDistro = 'Debian'
$DestinationDistro = 'Ubuntu'
$Path = '~/source'
$Path = '~/.local/share'
$Path = '~/.gitconfig*'
$Path = '~/.ssh'
$Path = '~/.kube'
wsl/wsl_files_copy.ps1 -s $SourceDistro -d $DestinationDistro -p $Path
# :copy files as root user
wsl/wsl_files_copy.ps1 -s $SourceDistro -d $DestinationDistro -p $Path -Root

# :copy to other specified path in destination distro
$DestinationPath = '~/myfiles'
wsl/wsl_files_copy.ps1 -s $SourceDistro -d $DestinationDistro -p $Path -dp $DestinationPath

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
    [ValidateNotNullOrEmpty()]
    [string]$SourceDistro,

    [Alias('d')]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationDistro,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [Alias('dp')]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationPath,

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

    # get list of existing WSL distros
    $distros = Get-WslDistro -FromRegistry

    if ($PSBoundParameters.ContainsKey('SourceDistro')) {
        if ($SourceDistro -notin $distros.Name) {
            Write-Warning "Specified source distro does not exist ($SourceDistro)."
            exit
        }
    } else {
        $msg = 'Select source distro:'
        $SourceDistro = $distros.Name | Get-ArrayIndexMenu -Message $msg -Value
    }
    if ($PSBoundParameters.ContainsKey('DestinationDistro')) {
        if ($DestinationDistro -notin $distros.Name) {
            Write-Warning "Specified destination distro does not exist ($DestinationDistro)."
            exit
        }
    } else {
        $msg = 'Select destination distro:'
        $DestinationDistro = $distros.Name | Get-ArrayIndexMenu -Message $msg -Value
    }

    # calculate destination path
    if (-not $PSBoundParameters.DestinationPath -or $PSBoundParameters.DestinationPath -eq $Path) {
        $DestinationPath = $Path -replace '/[^/]+/?$'  # get the parent directory
    }

    # calculate source mount path
    $mntDir = "/mnt/wsl/$SourceDistro"

    # determine if distros using different user ids
    $srcDefUid = $distros.Where({ $_.Name -eq $SourceDistro }).DefaultUid
    $dstDefUid = $distros.Where({ $_.Name -eq $DestinationDistro }).DefaultUid
    $useTmp = $srcDefUid -eq $dstDefUid ? $false : $true

    # instantiate wsl command arguments variable
    $wslArgs = [System.Collections.Generic.List[string]]::new()
    # get information from the source distro
    $wslArgs.AddRange([string[]]@('--distribution', $SourceDistro))
    if ($Root) {
        $wslArgs.AddRange([string[]]@('--user', 'root'))
    }
    $wslArgs.AddRange([string[]]@('--exec', 'bash'))
}

process {
    $wslArgs.AddRange([string[]]@('-c', "readlink -e $Path"))
    $rlPath = @(& wsl.exe @wslArgs)

    if ($rlPath) {
        $srcPath = $rlPath.ForEach({ "${mntDir}${_}" })
    } else {
        Write-Warning "Source path is incorrect ($Path)."
        exit
    }

    # bind mount root filesystem of the source distro
    $cmnd = "findmnt $mntDir >/dev/null || mkdir -p $mntDir && mount --bind / $mntDir"
    & wsl.exe -d $SourceDistro --user root --exec bash -c $cmnd

    # create temporary directory if distros are using different user ids
    if ($useTmp) {
        $mv = $srcPath.ForEach({ "mv `"$($_)`" /tmp/cpf" }) -join ' && '
        $wslArgs[-1] = "mkdir -p /tmp/cpf && $mv"
        & wsl.exe @wslArgs
        $srcPath = $rlPath.ForEach({ "$mntDir/tmp/cpf/$(Split-Path $_ -Leaf)" })
    }

    # calculate destination path
    $wslArgs[1] = $DestinationDistro
    $wslArgs[-1] = "readlink -m $DestinationPath"
    $dst = & wsl.exe @wslArgs
    # copy files from source to destination
    $cp = $srcPath.ForEach({ "cp -rf `"$($_)`" `"$dst`"" }) -join ' && '
    $wslArgs[-1] = "[ -d `"$dst`" ] || mkdir -p `"$dst`" && $cp"
    & wsl.exe @wslArgs
}

clean {
    # move source to original location
    if ($useTmp -and $srcPath) {
        $wslArgs[1] = $SourceDistro
        $mv = $srcPath.ForEach({ "mv `"/tmp/cpf/$(Split-Path $_ -Leaf)`" $(Split-Path $Path -Parent)" }) -join ' && '
        $wslArgs[-1] = "$mv && rm -fr /tmp/cpf"
        & wsl.exe @wslArgs
    }
}
