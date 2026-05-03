#region functions with autocomplete
<#
.SYNOPSIS
Kubernetes pod(s) information.

.PARAMETER Resource
Name of the pod.
.PARAMETER Namespace
Specify namespace of the pod.
.PARAMETER Xargs
Additional arguments to be passed to the kubectl command.
.PARAMETER WhatIf
If specified, the command will not be executed, but only written to the console.
.PARAMETER Quiet
If specified, the command will not be printed to the console.
#>
function kgpo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
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
        Kind = 'pods'
    }
    return Build-KubectlCommand @param @PSBoundParameters
}
function kdpo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
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
        Verb = 'describe'
        Kind = 'pods'
    }
    return Build-KubectlCommand @param @PSBoundParameters
}
function kgpocntr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [string]$Resource,

        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Namespace,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $param = @{
        Verb  = 'get'
        Kind  = 'pods'
        Xargs = @('--output', 'jsonpath={.spec.containers[*].name}')
    }
    return (Build-KubectlCommand @param @PSBoundParameters).Split()
}
function kgporsrc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [Alias('ns')]
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

    # resources columns
    $columns = [string]::Join(',',
        'NAMESPACE:.metadata.namespace',
        'POD:.metadata.name',
        'CONTAINER:.spec.containers[*].name',
        'CPU_REQUEST:.spec.containers[*].resources.requests.cpu',
        'CPU_LIMIT:.spec.containers[*].resources.limits.cpu',
        'MEM_REQUEST:.spec.containers[*].resources.requests.memory',
        'MEM_LIMIT:.spec.containers[*].resources.limits.memory'
    )

    $param = @{
        Verb = 'get'
        Kind = 'pods'
        Xargs = @('--output', "custom-columns=$columns")
    }
    return Build-KubectlCommand @param @PSBoundParameters
}
function ktpo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [Alias('ns')]
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
        Verb = 'top'
        Kind = 'pods'
        Xargs = @('--use-protocol-buffers')
    }
    return Build-KubectlCommand @param @PSBoundParameters
}
function ktpocntr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [Alias('ns')]
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
        Verb = 'top'
        Kind = 'pods'
        Xargs = @('--use-protocol-buffers', '--containers')
    }
    return Build-KubectlCommand @param @PSBoundParameters
}
#endregion
