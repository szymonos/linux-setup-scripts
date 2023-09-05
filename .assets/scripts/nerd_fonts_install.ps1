#Requires -RunAsAdministrator
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
.assets/scripts/nerd_fonts_install.ps1 $Font
# :check installed fonts
[Drawing.Text.InstalledFontCollection]::new().Families | Select-String $Font
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

    $tmp = New-Item "tmp.$(Get-Random)" -ItemType Directory
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

    # install fonts
    $shellApp = New-Object -ComObject shell.application
    $fonts = $shellApp.NameSpace(0x14)
    $fontFiles.ForEach({ $fonts.CopyHere($_.FullName) })
}

end {
    Remove-Item $tmp -Recurse -Force
}
