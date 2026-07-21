<#
.SYNOPSIS
Registers a tab-completion function for Makefile targets.

.DESCRIPTION
Call 'Register-MakeCompleter' in your Powershell Profile for auto-completions on your Makefiles.
If you include a description for you target, it'll use that too:
    target: ## This target does a thing.
#>
function Register-MakeCompleter {
    $ScriptBlock = {
        param(
            $wordToComplete
        )

        # if no Makefile exists in the current directory, return no completions
        if (-not (Test-Path './Makefile')) {
            return
        }

        # parse the Makefile, looking for targets and their descriptions
        # the regex looks for a line starting with a target name, followed by ':', and optionally a comment starting with '##'.
        $content = [System.IO.File]::ReadAllLines("$PWD/Makefile")

        $targets = $content.ForEach({
                if ($_ -match '^([a-zA-Z0-9_-]+):.*?\#\#\s*(.*)$') {
                    # try capturing target and description
                    [PSCustomObject]@{
                        Name        = $matches[1]
                        Description = $matches[2].Trim()
                    }
                } elseif ($_ -match '^([a-zA-Z0-9_-]+):') {
                    # target without a description
                    [PSCustomObject]@{
                        Name        = $matches[1]
                        Description = ''
                    }
                }
            }
        ) | Sort-Object Name -Unique

        # calculate the maximum length of target names for padding purposes
        $maxNameLength = ($targets.ForEach({ $_.Name.Length }) | Measure-Object -Maximum).Maximum

        # define colors and styles for the display text
        $blue = $PSStyle.Foreground.Blue
        $bold = $PSStyle.Bold
        $reset = $PSStyle.Reset

        # filter and return the completion results
        $targets.Where({ $_.Name -match "^$wordToComplete" }).ForEach({
                # incorporate description into the display text for visibility
                $paddedName = $_.Name.PadRight($maxNameLength + 2)
                $displayText = if ([string]::IsNullOrWhiteSpace($_.Description)) {
                    $_.Name
                } else {
                    "$($blue)$($bold)$($paddedName)$($reset)$($_.Description)"
                }

                # even though we still pass the description as tooltip, it's mainly for completeness
                # the $displayText ensures visibility in the suggestion list.
                [System.Management.Automation.CompletionResult]::new(
                    $_.Name,            # completionText
                    $displayText,       # listItemText
                    'ParameterValue',   # resultType
                    $displayText        # toolTip
                )
            }
        )
    }

    Register-ArgumentCompleter -Native -CommandName @('make', 'm') -ScriptBlock $ScriptBlock
}
