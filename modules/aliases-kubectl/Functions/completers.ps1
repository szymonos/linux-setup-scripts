<#
.SYNOPSIS
Get list of kubectl config clusters for the function ArgumentCompleter attribute.
#>
function ArgK8sGetClusters {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # get clusters
    $cmdArgs = @(
        'config', 'view'
        '--output', 'json'
    )
    [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).clusters.name

    # return matching clusters
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}


<#
.SYNOPSIS
Get list of kubectl config contexts for the function ArgumentCompleter attribute.
#>
function ArgK8sGetContexts {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # get contexts
    $cmdArgs = @(
        'config', 'view'
        '--output', 'json'
    )
    [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).contexts.name

    # return matching contexts
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}


<#
.SYNOPSIS
Get list of kubernetes namespaces for the function ArgumentCompleter attribute.
#>
function ArgK8sGetNamespaces {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # get namespaces
    $cmdArgs = @(
        'get', 'namespaces'
        '--field-selector=status.phase=Active'
        '--output', 'json'
    )
    [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).items.metadata.name

    # return matching namespaces
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}


<#
.SYNOPSIS
Get list of kubernetes pods for the function ArgumentCompleter attribute.
#>
function ArgK8sGetPods {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # build kubectl command string
    $cmdArgs = [System.Collections.Generic.List[string]]::new()
    $cmdArgs.AddRange([string[]]@('get', 'pods', '--field-selector=status.phase=Running'))
    if ($fakeBoundParameters.ContainsKey('Namespace')) {
        $cmdArgs.AddRange([string[]]@('--namespace', $fakeBoundParameters.Namespace))
    }
    $cmdArgs.AddRange([string[]]@('--output', 'json'))
    # get pods
    [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).items.metadata.name

    # return matching pods
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}


<#
.SYNOPSIS
Get list of pod containers for the function ArgumentCompleter attribute.
#>
function ArgK8sGetPodContainers {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    if ($fakeBoundParameters.ContainsKey('Pod')) {
        # build kubectl command string
        $cmdArgs = [System.Collections.Generic.List[string]]::new()
        $cmdArgs.AddRange([string[]]@('get', 'pod', $fakeBoundParameters.Pod))
        if ($fakeBoundParameters.ContainsKey('Namespace')) {
            $cmdArgs.AddRange([string[]]@('--namespace', $fakeBoundParameters.Namespace))
        }
        $cmdArgs.AddRange([string[]]@('--output', 'json'))
        # get pod containers
        [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).spec.containers.name

        # # return matching containers
        $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
    }
}


<#
.SYNOPSIS
Get list of kubernetes secrets for the function ArgumentCompleter attribute.
#>
function ArgK8sGetSecrets {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    # build kubectl command string
    $cmdArgs = [System.Collections.Generic.List[string]]::new()
    $cmdArgs.AddRange([string[]]@('get', 'secrets'))
    if ($fakeBoundParameters.ContainsKey('Namespace')) {
        $cmdArgs.AddRange([string[]]@('--namespace', $fakeBoundParameters.Namespace))
    }
    $cmdArgs.AddRange([string[]]@('--output', 'json'))
    # get pods
    [string[]]$possibleValues = (& kubectl @cmdArgs | ConvertFrom-Json).items.metadata.name

    # return matching pods
    $possibleValues.Where({ $_ -like "$wordToComplete*" }).ForEach({ $_ })
}
