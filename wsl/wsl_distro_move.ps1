<#
.SYNOPSIS
Move/Copy (and optionally rename) existing WSL2 distro.

.PARAMETER Distro
Name of the existing WSL distro.
.PARAMETER Destination
Destination path, where distro folder will be created.
.PARAMETER NewName
Optional new name of the WSL distro.
.PARAMETER Copy
Switch whether to copy distro instead of moving.

.EXAMPLE
$Distro = 'Ubuntu'
$Destination = 'C:\VM\WSL'
$NewName = 'jammy'
wsl/wsl_distro_move.ps1 $Distro -d $Destination -n $NewName
wsl/wsl_distro_move.ps1 $Distro -d $Destination -n $NewName -Copy
wsl/wsl_distro_move.ps1 $Distro -d $Destination -n $NewName -WhatIf

.NOTES
# :save script example
./scripts_egsave.ps1 wsl/wsl_distro_move.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 wsl/wsl_distro_move.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 wsl/wsl_distro_move.ps1 -WriteOutput)
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Distro,

    [Alias('d')]
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Destination,

    [Alias('n')]
    [ValidateNotNullOrEmpty()]
    [string]$NewName,

    [switch]$Copy
)

begin {
    $ErrorActionPreference = 'Stop'
    # check if the script is running on Windows
    if ($env:OS -notmatch 'windows') {
        Write-Warning 'Run the script on Windows!'
        exit 0
    }

    if (-not $NewName) { $NewName = $Distro }

    # create destination path if it doesn't exist
    if (-not (Test-Path $Destination -PathType Container)) {
        New-Item $Destination -ItemType Directory | Out-Null
    }

    # get list of all registered WSL distros
    $distros = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss
    # check if the specified distro exists
    $distroKey = $distros.Where({ $_.GetValue('DistributionName') -eq $Distro }) | Get-ItemProperty
    if (-not $distroKey) {
        Write-Warning "The specified distro does not exist ($Distro)."
        exit
    } elseif ($distroKey.Version -ne 2) {
        Write-Warning "The specified distro is not version 2 ($Distro)."
        exit
    }
    # check if distro in destination location already exist
    $destPath = [IO.Path]::GetFullPath([IO.Path]::Combine($Destination, $NewName.ToLower()))
    if ($distros.Where({ $_.GetValue('BasePath') -like "*$destPath" })) {
        Write-Warning "WSL distro in specified location already exists ($destPath)."
        exit
    }
    # calculate source path
    $srcPath = $distroKey.BasePath.Replace('\\?\', '')
}

process {
    if ($PSCmdlet.ShouldProcess("Move '$Distro' to '$destPath'")) {
        # create destination directory if not exists
        if (-not (Test-Path $destPath)) {
            New-Item $destPath -ItemType Directory | Out-Null
        }
        # shutting down distro before copying vhdx
        wsl.exe --shutdown $Distro
        # copy distro disk image to new location
        if ([IO.Path]::GetPathRoot($srcPath) -eq [IO.Path]::GetPathRoot($destPath) -and -not $Copy) {
            New-Item -ItemType HardLink ([IO.Path]::Combine($destPath, 'ext4.vhdx')) -Target ([IO.Path]::Combine($srcPath, 'ext4.vhdx')) | Out-Null
        } else {
            Copy-Item ([IO.Path]::Combine($srcPath, 'ext4.vhdx')) -Destination $destPath -ErrorAction Stop
        }
        # unregister existing distro
        if (-not $Copy) {
            wsl.exe --unregister $Distro
        }
        # recreate WSL entry in registry
        $destKey = if ($Copy) {
            New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -Name "{$([guid]::NewGuid())}"
        } else {
            New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -Name $distroKey.PSChildName
        }
        New-ItemProperty -Path $destKey.PSPath -Name 'BasePath' -PropertyType String -Value "\\?\$destPath" | Out-Null
        New-ItemProperty -Path $destKey.PSPath -Name 'DistributionName' -PropertyType String -Value $NewName | Out-Null
        New-ItemProperty -Path $destKey.PSPath -Name 'DefaultUid' -PropertyType DWORD -Value $distroKey.DefaultUid | Out-Null
        New-ItemProperty -Path $destKey.PSPath -Name 'Flags' -PropertyType DWORD -Value $distroKey.Flags | Out-Null
        New-ItemProperty -Path $destKey.PSPath -Name 'State' -PropertyType DWORD -Value $distroKey.State | Out-Null
        New-ItemProperty -Path $destKey.PSPath -Name 'Version' -PropertyType DWORD -Value $distroKey.Version | Out-Null
    }
}

end {
    Write-Host "Distro ($Distro) has been $($Copy ? 'copied' : 'moved') to '$destPath'."
}
