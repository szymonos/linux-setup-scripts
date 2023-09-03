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
Set-PSReadLineOption -MaximumHistoryCount 16384 -HistoryNoDuplicates
Set-PSReadLineOption -AddToHistoryHandler { param([string]$line) return $line.Length -gt 3 }
Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord F2 -Function SwitchPredictionView
Set-PSReadLineKeyHandler -Chord Shift+Tab -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord Alt+j -Function NextHistory
Set-PSReadLineKeyHandler -Chord Alt+k -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Chord Ctrl+RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Chord Alt+Delete -Function DeleteLine
#endregion

#region environment variables and aliases
[Environment]::SetEnvironmentVariable('OMP_PATH', '/usr/local/share/oh-my-posh')
[Environment]::SetEnvironmentVariable('SCRIPTS_PATH', '/usr/local/share/powershell/Scripts')
(Select-String '(?<=^ID.+)(alpine|arch|fedora|debian|ubuntu|opensuse)' -List /etc/os-release).Matches.Value.ForEach({
        [Environment]::SetEnvironmentVariable('DISTRO_FAMILY', $_)
    }
)
# $env:PATH variable
@(
    [IO.Path]::Combine($HOME, '.local', 'bin')
    [IO.Path]::Combine($HOME, '.cargo', 'bin')
) | ForEach-Object {
    if ((Test-Path $_) -and $_ -notin $env:PATH.Split([IO.Path]::PathSeparator)) {
        [Environment]::SetEnvironmentVariable('PATH', [string]::Join([IO.Path]::PathSeparator, $_, $env:PATH))
    }
}
# dot source PowerShell alias scripts
if (Test-Path $env:SCRIPTS_PATH) {
    Get-ChildItem -Path $env:SCRIPTS_PATH -Filter '_aliases_*.ps1' -File | ForEach-Object { . $_.FullName }
}
#endregion

# region brew
foreach ($path in @('/home/linuxbrew/.linuxbrew', "$HOME/.linuxbrew")) {
    if (Test-Path $path/bin/brew -PathType Leaf) {
        (& $path/bin/brew 'shellenv') | Out-String | Invoke-Expression
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
    # disable venv prompt as it is handled in oh-my-posh theme
    [Environment]::SetEnvironmentVariable('VIRTUAL_ENV_DISABLE_PROMPT', $true)
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
