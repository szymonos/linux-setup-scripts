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
# change PSStyle for directory coloring.
$PSStyle.FileInfo.Directory = "$($PSStyle.Bold)$($PSStyle.Foreground.Blue)"
# determine WSL version
$isWSL1 = (Test-Path /usr/bin/uname) ? (uname -r | Select-String '\bMicrosoft$' -Quiet) : $null
# configure PSReadLine setting.
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -AddToHistoryHandler { param([string]$line) return $line.Length -gt 1 }
Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord F2 -Function SwitchPredictionView
Set-PSReadLineKeyHandler -Chord Shift+Tab -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord Alt+j -Function NextHistory
Set-PSReadLineKeyHandler -Chord Alt+k -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Chord Ctrl+RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Chord Alt+Delete -Function DeleteLine
if (-not $isWSL1) {
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
    Set-PSReadLineOption -MaximumHistoryCount 16384 -HistoryNoDuplicates
}
#endregion

#region environment variables and aliases
[Environment]::SetEnvironmentVariable('OMP_PATH', '/usr/local/share/oh-my-posh')
[Environment]::SetEnvironmentVariable('SCRIPTS_PATH', '/usr/local/share/powershell/Scripts')
[Environment]::SetEnvironmentVariable('USER_SCRIPTS_PATH', "$HOME/.config/powershell/Scripts")
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
if (Test-Path $env:SCRIPTS_PATH -PathType Container) {
    Get-ChildItem -Path $env:SCRIPTS_PATH -Filter '_aliases_*.ps1' -File | ForEach-Object { . $_.FullName }
}
if (Test-Path $env:USER_SCRIPTS_PATH -PathType Container) {
    Get-ChildItem -Path $env:USER_SCRIPTS_PATH -Filter '_aliases_*.ps1' -File | ForEach-Object { . $_.FullName }
}
#endregion

#region initializations
# brew
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
if (-not $isWSL1 -and (Test-Path /usr/bin/oh-my-posh -PathType Leaf) -and (Test-Path "$env:OMP_PATH/theme.omp.json" -PathType Leaf)) {
    oh-my-posh init pwsh --config "$env:OMP_PATH/theme.omp.json" | Invoke-Expression | Out-Null
    # disable venv prompt as it is handled in oh-my-posh theme
    [Environment]::SetEnvironmentVariable('VIRTUAL_ENV_DISABLE_PROMPT', $true)
} else {
    function Prompt {
        $execStatus = $?
        # get execution time of the last command
        if (Get-Command Format-Duration -CommandType Function -ErrorAction SilentlyContinue) {
            $executionTime = (Get-History).Count -gt 0 ? (Format-Duration -TimeSpan (Get-History)[-1].Duration) : $null
        }
        # build current prompt path
        $pathString = $PWD.Path.Replace($HOME, '~').Replace('Microsoft.PowerShell.Core\FileSystem::', '') -replace '\\$'
        $split = $pathString.Split([IO.Path]::DirectorySeparatorChar, [StringSplitOptions]::RemoveEmptyEntries)
        $promptPath = if ($split.Count -gt 3) {
            [string]::Join('/', $split[0], '..', $split[-1])
        } else {
            [string]::Join('/', $split)
        }
        # run elevated indicator
        if ((id -u) -eq 0) {
            [Console]::Write("`e[91m#`e[0m ")
        }
        # write last execution time
        if ($executionTime) {
            [Console]::Write("[`e[93m$executionTime`e[0m] ")
        }
        # write last execution status
        [Console]::Write("$($PSStyle.Bold){0}`u{2192} ", $execStatus ? $PSStyle.Foreground.BrightGreen : $PSStyle.Foreground.BrightRed)
        # write prompt path
        [Console]::Write("`e[1;94m$promptPath`e[0m ")
        # write git branch/status
        if ($GitPromptSettings) {
            # get git status
            $gitStatus = @(git status -b --porcelain=v2 2>$null)[1..4]
            if ($gitStatus) {
                # get branch name and upstream status
                $branch = $gitStatus[0].Split(' ')[2] + ($gitStatus[1] -match 'branch.upstream' ? $null : " `u{21E1}")
                # format branch name color depending on working tree status
                [Console]::Write(
                    "`e[38;2;232;204;151m({0}$branch`e[38;2;232;204;151m) ",
                    ($gitStatus | Select-String -Pattern '^(?!#)' -Quiet) ? "`e[38;2;255;146;72m" : "`e[38;2;212;170;252m"
                )
            }
        }
        return '{0}{1} ' -f ($PSStyle.Reset, '>' * ($nestedPromptLevel + 1))
    }
}
#endregion
