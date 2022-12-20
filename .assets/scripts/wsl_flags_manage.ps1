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

.EXAMPLE
$Distro = 'Ubuntu'
.assets/scripts/wsl_flags_manage.ps1 $Distro -Interop $true
.assets/scripts/wsl_flags_manage.ps1 $Distro -Interop $false
.assets/scripts/wsl_flags_manage.ps1 $Distro -AppendWindowsPath $true
.assets/scripts/wsl_flags_manage.ps1 $Distro -AppendWindowsPath $false
.assets/scripts/wsl_flags_manage.ps1 $Distro -Automount $true
.assets/scripts/wsl_flags_manage.ps1 $Distro -Automount $false
#>
[CmdletBinding(SupportsShouldProcess)]
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
    # check if source distro exists
    $srcDistro = $distros.Where({ $_.GetValue('DistributionName') -eq $Distro }) | Get-ItemProperty
    if (-not $srcDistro) {
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
                $srcDistro.Flags = $srcDistro.Flags -bor [WSL_FLAGS]::ENABLE_INTEROP
            } elseif ($srcDistro.Flags -band [WSL_FLAGS]::ENABLE_INTEROP) {
                $srcDistro.Flags = $srcDistro.Flags -bxor [WSL_FLAGS]::ENABLE_INTEROP
            }
            continue
        }

        ntpath {
            if ($AppendWindowsPath) {
                $srcDistro.Flags = $srcDistro.Flags -bor [WSL_FLAGS]::APPEND_NT_PATH
            } elseif ($srcDistro.Flags -band [WSL_FLAGS]::APPEND_NT_PATH) {
                $srcDistro.Flags = $srcDistro.Flags -bxor [WSL_FLAGS]::APPEND_NT_PATH
            }
            continue
        }

        mounting {
            if ($Automount) {
                $srcDistro.Flags = $srcDistro.Flags -bor [WSL_FLAGS]::DRIVE_MOUNTING
            } elseif ($srcDistro.Flags -band [WSL_FLAGS]::DRIVE_MOUNTING) {
                $srcDistro.Flags = $srcDistro.Flags -bxor [WSL_FLAGS]::DRIVE_MOUNTING
            }
            continue
        }
    }
    Set-ItemProperty -Path $srcDistro.PSPath -Name 'Flags' -Value $srcDistro.Flags
}

end {
    # print current flags value
    @{ Flags = Get-ItemPropertyValue -Path $srcDistro.PSPath -Name Flags }
}
