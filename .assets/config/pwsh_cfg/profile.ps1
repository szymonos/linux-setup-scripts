#Requires -Version 7.2
#Requires -Modules PSReadLine

#region startup settings
# import posh-git module for git autocompletion.
if (Get-Command git -CommandType Application -ErrorAction SilentlyContinue) {
    Import-Module posh-git; $GitPromptSettings.EnablePromptStatus = $false
}
# make PowerShell console Unicode (UTF-8) aware
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()
# set culture to English Sweden for ISO-8601 datetime settings
[Threading.Thread]::CurrentThread.CurrentCulture = 'en-SE'
# Change PSStyle for directory coloring.
$PSStyle.FileInfo.Directory = "$($PSStyle.Bold)$($PSStyle.Foreground.Blue)"
# Configure PSReadLine setting.
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView
Set-PSReadLineKeyHandler -Key Shift+Tab -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Key Alt+j -Function NextHistory
Set-PSReadLineKeyHandler -Key Alt+k -Function PreviousHistory
Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Key Ctrl+v -Function Paste
Set-PSReadLineKeyHandler -Key Alt+Delete -Function DeleteLine
# set Startup Working Directory variable
$SWD = $PWD.Path
function cds { Set-Location $SWD }
#endregion

#region environment variables and aliases
# PATH env
$private:pPaths = @(
    [IO.Path]::Join($HOME, '.local', 'bin')
)
foreach ($p in $pPaths) {
    if ((Test-Path $p) -and $env:PATH -NotMatch "$p/?($([IO.Path]::PathSeparator)|$)") {
        $env:PATH = [string]::Join([IO.Path]::PathSeparator, $p, $env:PATH)
    }
}
# aliases
$private:pAliasFiles = Get-ChildItem -Path /usr/local/share/powershell/Scripts -Filter 'ps_aliases_*.ps1' -File -ErrorAction SilentlyContinue
foreach ($file in $pAliasFiles) {
    . $file.FullName
}
#endregion

#region startup
$private:pOSEdition = (Select-String -Pattern '^PRETTY_NAME=(.*)' -Path /etc/os-release).Matches.Groups[1].Value.Trim("`"|'")
Write-Host "$($PSStyle.Foreground.BrightWhite)$pOSEdition | PowerShell $($PSVersionTable.PSVersion)$($PSStyle.Reset)"

# oh-my-posh initialization
$private:pOmpTheme = '/usr/local/share/oh-my-posh/theme.omp.json'
if ((Get-Command oh-my-posh -CommandType Application -ErrorAction SilentlyContinue) -and (Test-Path $pOmpTheme -PathType Leaf)) {
    oh-my-posh --init --shell pwsh --config $pOmpTheme | Invoke-Expression
}
#endregion
