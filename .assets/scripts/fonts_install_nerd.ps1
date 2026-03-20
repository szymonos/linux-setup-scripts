#Requires -RunAsAdministrator
#Requires -PSEdition Core -Version 7.3
<#
.SYNOPSIS
Install specified nerd font from ryanoasis/nerd-fonts GitHub repo.
.LINK
https://github.com/ryanoasis/nerd-fonts

.PARAMETER Font
Name of the nerd font to be installed.
.PARAMETER FontExt
Specified font extension.

.EXAMPLE
$Font = 'FiraCode'
.assets/scripts/fonts_install_nerd.ps1 $Font
# :check installed fonts
[Drawing.Text.InstalledFontCollection]::new().Families | Select-String $Font

.NOTES
# :save script example
./scripts_egsave.ps1 .assets/scripts/fonts_install_nerd.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 .assets/scripts/fonts_install_nerd.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 .assets/scripts/fonts_install_nerd.ps1 -WriteOutput)
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Font,

    [ValidateSet('ttf', 'otf')]
    [string]$FontExt = 'otf'
)

begin {
    $ErrorActionPreference = 'Stop'

    # set location to workspace folder
    Push-Location "$PSScriptRoot/../.."

    $tmp = New-Item -Name ([System.IO.Path]::GetRandomFileName()) -ItemType Directory
    $fontArchive = [IO.Path]::Combine($tmp, "${Font}.zip")
}

process {
    # download font
    try {
        $uri = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${Font}.zip"
        [Net.WebClient]::new().DownloadFile($uri, $fontArchive)
    } catch {
        Write-Warning "Font not found ($Font)."
        exit 1
    }
    Expand-Archive $fontArchive -DestinationPath $tmp

    # filter fonts by type
    if (-not $($fontFiles = Get-ChildItem $tmp -Filter "*.$FontExt" -File -Recurse)) {
        $otherFontExt = $('ttf', 'otf') -ne $FontExt
        $fontFiles = Get-ChildItem $tmp -Filter "*.$otherFontExt" -File -Recurse
    }

    # use only Windows Compatible fonts if available
    if ($fontFiles.BaseName -match 'Windows Compatible$') {
        $fontFiles = $fontFiles | Where-Object BaseName -Match 'Windows Compatible$'
    }

    # remove existing per-user fonts and install new ones
    $userFontsDir = [IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft\Windows\Fonts')
    $regKey = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    $regProps = Get-ItemProperty -Path $regKey -ErrorAction SilentlyContinue
    foreach ($file in $fontFiles) {
        try {
            Remove-Item "$userFontsDir/$($file.Name)" -ErrorAction Stop
            if ($regProps) {
                $regProps.PSObject.Properties.Where({ $_.Value -like "*\$($file.Name)" }).ForEach(
                    { Remove-ItemProperty -Path $regKey -Name $_.Name -ErrorAction SilentlyContinue }
                )
            }
        } catch [System.Management.Automation.ItemNotFoundException] {
            # font file doesn't exist, nothing to remove
        } catch {
            Write-Warning "Failed to remove existing font $($file.Name): $_"
        }
    }
    $shellApp = New-Object -ComObject shell.application
    $fonts = $shellApp.NameSpace(0x14)
    $fontFiles.ForEach({ $fonts.CopyHere($_.FullName) })
}

clean {
    if (Test-Path $tmp -PathType Container) {
        Remove-Item $tmp -Recurse -Force
    }
    Pop-Location
}
