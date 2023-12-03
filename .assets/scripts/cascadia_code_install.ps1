#Requires -RunAsAdministrator
<#
.SYNOPSIS
Install latest CascadaCode fonts.
.LINK
https://github.com/microsoft/cascadia-code

.EXAMPLE
.assets/scripts/cascadia_code_install.ps1
# :check installed fonts
[Drawing.Text.InstalledFontCollection]::new().Families | Select-String 'cascadia' -Raw
#>
param ()

begin {
    $ErrorActionPreference = 'Stop'

    $tmp = New-Item "tmp.$(Get-Random)" -ItemType Directory
    $fontArchive = [IO.Path]::Combine($tmp, 'CascadiaCode.zip')
}

process {
    # get latest version
    $rel = (Invoke-RestMethod https://api.github.com/repos/microsoft/cascadia-code/releases/latest).tag_name -replace '^v'
    # download font
    try {
        $uri = "https://github.com/microsoft/cascadia-code/releases/download/v${REL}/CascadiaCode-${REL}.zip"
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
    $fontFiles.ForEach({ $fonts.CopyHere($_.FullName) })
}

end {
    Remove-Item $tmp -Recurse -Force
}
