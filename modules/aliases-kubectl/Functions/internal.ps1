<#
.SYNOPSIS
Write provided kubectl with its arguments and then execute it.
You can suppress writing the kubectl by providing -Quiet as one of the arguments.
You can suppress executing the kubectl by providing -WhatIf as one of the arguments.

.PARAMETER Command
kubectl command to be executed.
.PARAMETER Xargs
Additional arguments to be passed to the kubectl command.
.PARAMETER WhatIf
If specified, the command will not be executed, but only written to the console.
.PARAMETER Quiet
If specified, the command will not be printed to the console.
#>
function Invoke-WriteExecKubectl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$Command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    if (-not $PsBoundParameters.Quiet) {
        # write command
        $writeCmd = , 'kubectl' + $Command + $Xargs | ForEach-Object {
            switch -Regex ($_) {
                "'" {
                    "`"$_`""
                    break
                }
                '\s|"' {
                    "'$_'"
                    break
                }
                Default {
                    $_
                    break
                }
            }
        } | Join-String -Separator ' '
        Write-Host $writeCmd -ForegroundColor Magenta
    }

    if (-not $PsBoundParameters.WhatIf) {
        # write debug information
        Write-Debug "Invoke-WriteExecKubectl.Command`n`e[22m$cmnd`n"
        if ($PSBoundParameters.Xargs) {
            Write-Debug "Invoke-WriteExecKubectl.Xargs`n`e[22m$Xargs`n"
        }
        # execute command
        & kubectl @Command @Xargs
    }
}


<#
.SYNOPSIS
Build a kubectl command for specific kinds and o operations (verbs).
.DESCRIPTION
The command allows to create functions with autocompletion for specific kubectl operations.

.PARAMETER Verb
The kubectl operation to be performed. Valid values are 'get', 'describe', and 'delete'.
.PARAMETER Kind
The kind of kubernetes object to be operated on. Valid values are 'Pod', 'Service', 'Namespace', and 'Secret'.
.PARAMETER Name
The name of the resource to be operated on. Optional parameter.
.PARAMETER Namespace
The namespace in which the operation should be performed. Optional parameter.
.PARAMETER Xargs
Additional arguments to be passed to the kubectl command.
.PARAMETER WhatIf
If specified, the command will not be executed, but only written to the console.
.PARAMETER Quiet
If specified, the command will not be printed to the console.
#>
function Build-KubectlCommand {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Verb,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Kind,

        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [ValidateNotNullOrEmpty()]
        [string]$Namespace,

        [string[]]$Xargs,

        [switch]$WhatIf,

        [switch]$Quiet
    )

    begin {
        # write debug information
        Write-Debug "Build-KubectlCommand.PSBoundParameters`n`e[22m$($PSBoundParameters.GetEnumerator().ForEach({ "$($_.Key): $($_.Value)" }) -join "`n")`n"

        # build command
        $cmnd = [System.Collections.Generic.List[string]]::new()
        $cmnd.AddRange([string[]]@($PSBoundParameters.Verb.ToLower(), $PSBoundParameters.Kind.ToLower()))
        @('Verb', 'Kind').ForEach({ $PSBoundParameters.Remove($_) | Out-Null })

        # build parameters
        if ($PSBoundParameters.Resource) {
            $cmnd.Add($Resource)
            $PSBoundParameters.Remove('Resource') | Out-Null
        }

        if ($PSBoundParameters.Namespace) {
            if ($Kind -notin @('ns', 'namespace', 'namespaces')) {
                $cmnd.AddRange([string[]]@('--namespace', $Namespace))
            }
            $PSBoundParameters.Remove('Namespace') | Out-Null
        }
    }

    process {
        # write debug information
        Write-Debug "Build-KubectlCommand.Command`n`e[22m$cmnd`n"
        # execute command
        Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
    }
}
