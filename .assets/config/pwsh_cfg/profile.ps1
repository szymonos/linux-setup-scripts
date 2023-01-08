#Requires -Version 7.2

#region startup settings
# import posh-git module for git autocompletion.
try {
    Import-Module posh-git -ErrorAction Stop
    $GitPromptSettings.EnablePromptStatus = $false
} catch {
    Out-Null
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
#endregion

#region environment variables and aliases
[Environment]::SetEnvironmentVariable('OMP_PATH', '/usr/local/share/oh-my-posh')
[Environment]::SetEnvironmentVariable('SCRIPTS_PATH', '/usr/local/share/powershell/Scripts')
# $PATH variable
@(
    [IO.Path]::Combine($HOME, '.local', 'bin')
    [IO.Path]::Combine($HOME, '.cargo', 'bin')
).ForEach{
    if ((Test-Path $_) -and $env:PATH -NotMatch "$_/?($([IO.Path]::PathSeparator)|$)") {
        [Environment]::SetEnvironmentVariable('PATH', [string]::Join([IO.Path]::PathSeparator, $_, $env:PATH))
    }
}
# aliases
(Get-ChildItem -Path $env:SCRIPTS_PATH -Filter 'ps_aliases_*.ps1' -File).ForEach{ . $_.FullName }
#endregion

# region brew
foreach ($path in @('/home/linuxbrew/.linuxbrew/bin/brew', "$HOME/.linuxbrew/bin/brew")) {
    if (Test-Path $path -PathType Leaf) {
        (& $path 'shellenv') | Out-String | Invoke-Expression
        $env:HOMEBREW_NO_ENV_HINTS = 1
        continue
    }
}
Remove-Variable path
#endregion

#region prompt
try {
    Get-Command oh-my-posh -CommandType Application -ErrorAction Stop | Out-Null
    oh-my-posh --init --shell pwsh --config "$(Resolve-Path $env:OMP_PATH/theme.omp.json -ErrorAction Stop)" | Invoke-Expression
} catch {
    function Prompt {
        $split = $($PWD.Path.Replace($HOME, '~').Replace('Microsoft.PowerShell.Core\FileSystem::', '') -replace '\\$').Split([IO.Path]::DirectorySeparatorChar, [StringSplitOptions]::RemoveEmptyEntries)
        $promptPath = if ($split.Count -gt 3) {
            [string]::Join('/', $split[0], '..', $split[-1])
        } else {
            [string]::Join('/', $split)
        }
        return "`e[1;32m{0}@{1}`e[0m: `e[1;34m$promptPath`e[0m> " -f $env:USER, ($env:HOSTNAME ?? $env:WSL_DISTRO_NAME)
    }
}
#endregion
