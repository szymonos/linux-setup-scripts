#Requires -RunAsAdministrator
#Requires -PSEdition Core -Version 7.3
<#
.SYNOPSIS
Install latest CascadaCode fonts.
.LINK
https://github.com/microsoft/cascadia-code

.EXAMPLE
.assets/scripts/fonts_install_cascadia_code.ps1
# :check installed fonts
[Drawing.Text.InstalledFontCollection]::new().Families | Select-String 'cascadia' -Raw
#>
[CmdletBinding()]
param ()

begin {
    $ErrorActionPreference = 'Stop'

    # set location to workspace folder
    Push-Location "$PSScriptRoot/../.."

    $tmp = New-Item -Name ([System.IO.Path]::GetRandomFileName()) -ItemType Directory
    $fontArchive = [IO.Path]::Combine($tmp, 'CascadiaCode.zip')

    # latest release api endpoint for the cascadia-code repo
    $urlGHRel = 'https://api.github.com/repos/microsoft/cascadia-code/releases/latest'
}

process {
    # get latest version
    $rel = (Invoke-RestMethod $urlGHRel).tag_name -replace '^v'
    # download font
    try {
        $uri = "https://github.com/microsoft/cascadia-code/releases/download/v${rel}/CascadiaCode-${rel}.zip"
        [Net.WebClient]::new().DownloadFile($uri, $fontArchive)
    } catch {
        Write-Warning "Font not found ($Font)."
        exit 1
    }
    Expand-Archive $fontArchive -DestinationPath $tmp
    $fontFiles = Get-ChildItem "$tmp/ttf" -Filter '*.ttf' -File

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
