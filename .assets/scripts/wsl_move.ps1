<#
.SYNOPSIS
Move (and optionally rename) existing WSL distro.
.PARAMETER Distro
Name of the existing WSL distro.
.PARAMETER Destination
Existing destination path, where distro folder will be created.
.PARAMETER NewName
Optional new name of the WSL distro.

.EXAMPLE
$Name = 'Ubuntu'
$Destination = 'C:\VM\WSL'
$NewName = 'jammy'
.assets/scripts/wsl_move.ps1 $Distro -d $Destination -n $NewName
.assets/scripts/wsl_move.ps1 $Distro -d $Destination -n $NewName -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [Alias('d')]
    [Parameter(Mandatory)]
    [string]$Destination,

    [Alias('n')]
    [string]$NewName
)

begin {
    $ErrorActionPreference = 'Stop'
    if (-not $NewName) { $NewName = $Distro }

    # create destination path if it doesn't exist
    if (-not (Test-Path $Destination -PathType Container)) {
        New-Item $Destination -ItemType Directory | Out-Null
    }

    # get list of all registered WSL distros
    $distros = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss
    # check if source distro exists
    $srcDistro = $distros.Where({ $_.GetValue('DistributionName') -eq $Distro }) | Get-ItemProperty
    if (-not $srcDistro) {
        Write-Warning "The specified distro does not exist ($Distro)."
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
    if ($PSCmdlet.ShouldProcess("Move '$Distro' to '$destPath'")) {
        # copy distro disk image to new location
        New-Item $Destination -Name $NewName.ToLower() -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        Copy-Item ([IO.Path]::Combine($srcDistro.BasePath.Replace('\\?\', ''), '*')) -Destination $destPath -ErrorAction Stop
        # unregister existing distro
        wsl.exe --unregister $Distro
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
    Write-Host "Done." -ForegroundColor Green
}
