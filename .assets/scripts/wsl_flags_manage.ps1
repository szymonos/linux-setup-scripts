<#
.SYNOPSIS
Specifies the behavior of a distribution in the Windows Subsystem for Linux.

.PARAMETER Distro
Name of the existing WSL distro.
.PARAMETER Interop
Allow the distribution to interoperate with Windows processes.
.PARAMETER AppendWindowsPath
Add the Windows %PATH% environment variable values to WSL sessions.
.PARAMETER Automount
Automatically mount Windows drives inside of WSL sessions.

.LINK
https://learn.microsoft.com/en-gb/windows/win32/api/wslapi/ne-wslapi-wsl_distribution_flags

.EXAMPLE
$Distro = 'Ubuntu'
.assets/scripts/wsl_flags_manage.ps1 $Distro
.assets/scripts/wsl_flags_manage.ps1 $Distro -Interop $true
.assets/scripts/wsl_flags_manage.ps1 $Distro -Interop $false
.assets/scripts/wsl_flags_manage.ps1 $Distro -AppendWindowsPath $true
.assets/scripts/wsl_flags_manage.ps1 $Distro -AppendWindowsPath $false
.assets/scripts/wsl_flags_manage.ps1 $Distro -Automount $true
.assets/scripts/wsl_flags_manage.ps1 $Distro -Automount $false
#>
[CmdletBinding(DefaultParameterSetName = 'Show')]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Distro,

    [Parameter(Mandatory, ParameterSetName = 'interop')]
    [bool]$Interop,

    [Parameter(Mandatory, ParameterSetName = 'ntpath')]
    [bool]$AppendWindowsPath,

    [Parameter(Mandatory, ParameterSetName = 'mounting')]
    [bool]$Automount

)

begin {
    # get list of all registered WSL distros
    $distros = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss
    # check if the specified distro exists
    $distroKey = $distros.Where({ $_.GetValue('DistributionName') -eq $Distro }) | Get-ItemProperty
    if (-not $distroKey) {
        Write-Warning "The specified distro does not exist ($Distro)."
        exit
    }
    # WSL_DISTRIBUTION_FLAGS enumeration
    [Flags()] enum WSL_FLAGS {
        ENABLE_INTEROP = 1
        APPEND_NT_PATH = 2
        DRIVE_MOUNTING = 4
    }
}

process {
    switch ($PsCmdlet.ParameterSetName) {
        interop {
            if ($Interop) {
                $distroKey.Flags = $distroKey.Flags -bor [WSL_FLAGS]::ENABLE_INTEROP
            } elseif ($distroKey.Flags -band [WSL_FLAGS]::ENABLE_INTEROP) {
                $distroKey.Flags = $distroKey.Flags -bxor [WSL_FLAGS]::ENABLE_INTEROP
            }
            continue
        }

        ntpath {
            if ($AppendWindowsPath) {
                $distroKey.Flags = $distroKey.Flags -bor [WSL_FLAGS]::APPEND_NT_PATH
            } elseif ($distroKey.Flags -band [WSL_FLAGS]::APPEND_NT_PATH) {
                $distroKey.Flags = $distroKey.Flags -bxor [WSL_FLAGS]::APPEND_NT_PATH
            }
            continue
        }

        mounting {
            if ($Automount) {
                $distroKey.Flags = $distroKey.Flags -bor [WSL_FLAGS]::DRIVE_MOUNTING
            } elseif ($distroKey.Flags -band [WSL_FLAGS]::DRIVE_MOUNTING) {
                $distroKey.Flags = $distroKey.Flags -bxor [WSL_FLAGS]::DRIVE_MOUNTING
            }
            continue
        }
    }
    # set WSL distro flags in registry
    Set-ItemProperty -Path $distroKey.PSPath -Name 'Flags' -Value $distroKey.Flags
}

end {
    # print current flags values
    [ordered]@{
        DistributionName  = $distroKey.DistributionName
        Flags             = '0x{0:x} ({0})' -f $distroKey.Flags
        Interop           = [bool]$($distroKey.Flags -band [WSL_FLAGS]::ENABLE_INTEROP)
        AppendWindowsPath = [bool]$($distroKey.Flags -band [WSL_FLAGS]::APPEND_NT_PATH)
        Automount         = [bool]$($distroKey.Flags -band [WSL_FLAGS]::DRIVE_MOUNTING)
    }
}
