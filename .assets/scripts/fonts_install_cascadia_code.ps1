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

    # install fonts
    $shellApp = New-Object -ComObject shell.application
    $fonts = $shellApp.NameSpace(0x14)
    $fontFiles.ForEach({ $fonts.CopyHere($_.FullName, 0x10) })
}

clean {
    if (Test-Path $tmp -PathType Container) {
        Remove-Item $tmp -Recurse -Force
    }
    Pop-Location
}
