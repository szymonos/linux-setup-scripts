#region functions with autocomplete
<#
.SYNOPSIS
Get kubernetes secret(s).

.PARAMETER Resource
Name of the secret. Optional parameter. If not specified, all secrets in the namespace will be returned.
.PARAMETER Namespace
Specify namespace of the pod. Optional parameter.
.PARAMETER Xargs
Additional arguments to be passed to the kubectl command.
.PARAMETER WhatIf
If specified, the command will not be executed, but only written to the console.
.PARAMETER Quiet
If specified, the command will not be printed to the console.
#>
function kgsec {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgK8sGetSecrets @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Namespace,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $param = @{
        Verb = 'get'
        Kind = 'secrets'
    }
    return Build-KubectlCommand @param @PSBoundParameters
}
function kgsecd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ArgumentCompleter({ ArgK8sGetSecrets @args })]
        [string]$Resource,

        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Namespace,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $param = @{
        Verb  = 'get'
        Kind  = 'secrets'
        Xargs = @('--output', 'json')
    }
    # convert secret to PSObject
    $secretObj = Build-KubectlCommand @param @PSBoundParameters | ConvertFrom-Json
    # decode and write secret data
    $secretObj.data.PSobject.Properties | ForEach-Object {
        Write-Host "# $($_.Name)" -ForegroundColor DarkGreen
        [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_.Value)).Trim()
    }
}
#endregion
