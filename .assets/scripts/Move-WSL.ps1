#!/usr/bin/env -S pwsh -nop
<#
.SYNOPSIS
Script synopsis.
.EXAMPLE
$Name = 'Debian'
$Destination = 'F:\Virtual Machines\WSL'
$NewName = 'debian11'
.assets\scripts\Move-WSL.ps1 $Name -d $Destination -e $NewName
.assets\scripts\Move-WSL.ps1 $Name -d $Destination -e $NewName -WhatIf
.assets\scripts\Move-WSL.ps1 $Name -d $Destination -e $NewName -Confirm
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ [regex]::IsMatch($_, '^\w+$') }, ErrorMessage = "'{0}' is not a valid folder path.")]
    [string]$Name,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType 'Container' }, ErrorMessage = "'{0}' is not a valid folder path.")]
    [string]$Destination,

    [Alias('e')]
    [ValidateNotNullorEmpty()]
    [object]$NewName
)

begin {
    $ErrorActionPreference = 'Stop'
    $NewName ??= $Name

    # get list of all registered WSL distros
    $distros = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss
    # check if source distro exists
    $srcDistro = $distros.Where({ $_.GetValue('DistributionName') -eq $Name }) | Get-ItemProperty
    if (-not $srcDistro) {
        Write-Warning "The specified distro does not exist ($Name)."
        exit
    }
    # check if distro in destination location already exist
    $destPath = [IO.Path]::Combine($Destination, $NewName.ToLower())
    if ($distros.Where({ $_.GetValue('BasePath') -like "*$destPath" })) {
        Write-Warning "WSL distro in specified location already exists ($destPath)."
        exit
    }
}

process {
    if ($PSCmdlet.ShouldProcess("Move `e[4m$Name`e[24m to `e[4m$destPath`e[0m")) {
        # copy distro disk image to new location
        New-Item $Destination -Name $NewName.ToLower() -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        Copy-Item ([IO.Path]::Combine($srcDistro.BasePath.Replace('\\?\', ''), '*')) -Destination $destPath -ErrorAction Stop
        # unregister existing distro
        wsl.exe --unregister $Name
        # recreate WSL entry in registry
        $destKey = New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -Name $srcDistro.PSChildName
        New-ItemProperty -Path $destKey.PSPath -Name 'BasePath' -PropertyType String -Value "\\?\$destPath" | Out-Null
        New-ItemProperty -Path $destKey.PSPath -Name 'DistributionName' -PropertyType String -Value $NewName | Out-Null
        New-ItemProperty -Path $destKey.PSPath -Name 'DefaultUid' -PropertyType DWORD -Value $srcDistro.DefaultUid | Out-Null
        New-ItemProperty -Path $destKey.PSPath -Name 'Flags' -PropertyType DWORD -Value $srcDistro.Flags | Out-Null
        New-ItemProperty -Path $destKey.PSPath -Name 'State' -PropertyType DWORD -Value $srcDistro.State | Out-Null
        New-ItemProperty -Path $destKey.PSPath -Name 'Version' -PropertyType DWORD -Value $srcDistro.Version | Out-Null
    }
}

end {
    Write-Host "`e[92mDone.`e[0m"
}
