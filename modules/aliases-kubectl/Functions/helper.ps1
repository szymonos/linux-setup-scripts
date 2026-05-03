#region helper functions
<#
.SYNOPSIS
Get kubectl client version.
#>
function Get-KubectlVersion {
    # get-full version
    $v = kubectl version -o=json 2>$null | ConvertFrom-Json
    # convert back to json selected properties
    $verJson = [ordered]@{
        clientVersion = [ordered]@{
            gitVersion = $v.clientVersion.gitVersion
            buildDate  = $v.clientVersion.buildDate
            goVersion  = $v.clientVersion.goVersion
            platform   = $v.clientVersion.platform
        }
        serverVersion = [ordered]@{
            gitVersion = $v.serverVersion.gitVersion -replace '(v[\d.]+).*', "`$1"
            buildDate  = $v.serverVersion.buildDate
            goVersion  = $v.serverVersion.goVersion
            platform   = $v.serverVersion.platform
        }
    } | ConvertTo-Json

    # format output command
    if (Get-Command yq -CommandType Application -ErrorAction SilentlyContinue) {
        $verJson | yq -p json -o yaml
    } elseif (Get-Command jq -CommandType Application -ErrorAction SilentlyContinue) {
        $verJson | jq
    } else {
        $verJson
    }
}


<#
.SYNOPSIS
Get kubectl client version.
#>
function Get-KubectlClientVersion {
    return (kubectl version -o=json 2>$null | ConvertFrom-Json).clientVersion.gitVersion
}


<#
.SYNOPSIS
Get kubernetes server version.
#>
function Get-KubectlServerVersion {
    return (kubectl version -o=json 2>$null | ConvertFrom-Json).serverVersion.gitVersion -replace '(v[\d.]+).*', "`$1"
}


<#
.SYNOPSIS
Set kubernetes current namespace context.

.PARAMETER Namespace
Kubernetes namespace name to set the namespace current context to.
#>
function Set-KubectlContextCurrentNamespace {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace
    )

    begin {
        # get namespace name
        $namespace = if ($PsBoundParameters.Namespace) {
            $PsBoundParameters.Namespace
        } else {
            $prop = @(
                @{ Name = 'Name'; Expression = { $_.metadata.name } }
                @{ Name = 'Status'; Expression = { $_.status.phase } }
                @{ Name = 'CreatedAt'; Expression = { $_.metadata.creationTimestamp } }
            )
            kubectl get namespace --output json `
            | ConvertFrom-Json `
            | Select-Object -ExpandProperty items `
            | Select-Object -Property $prop `
            | Get-ArrayIndexMenu -Value -Message 'Select namespace to switch context to' `
            | Select-Object -ExpandProperty name
        }
    }

    process {
        # execute command
        $cmnd = @('config', 'set-context', '--current', '--namespace', $namespace)
        Invoke-WriteExecKubectl -Command $cmnd
    }
}


<#
.SYNOPSIS
Set kubernetes current namespace context using kubens cli.

.PARAMETER Namespace
Kubernetes namespace name to set the current namespace context to.
#>
function Set-KubensContextCurrentNamespace {
    [CmdletBinding()]
    param (
        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace
    )

    # build kubectl command string
    [System.Collections.Generic.List[string]]$cmdArgs = @()
    if ($PSBoundParameters.Namespace) {
        $cmdArgs.Add($Namespace)
    }

    # execute kubens command
    & kubens @cmdArgs
}


<#
.SYNOPSIS
Change kubernetes context and sets the corresponding kubectl client version.

.PARAMETER Context
Kubernetes cluster context name to be set.
.PARAMETER Cluster
Kubernetes cluster name for the context to be set.
#>
function Set-KubectlContext {
    [CmdletBinding(DefaultParameterSetName = 'context')]
    param (
        [Alias('n')]
        [Parameter(Position = 0, ParameterSetName = 'context')]
        [ArgumentCompleter({ ArgK8sGetContexts @args })]
        [string]$Context,

        [Alias('c')]
        [Parameter(Position = 0, ParameterSetName = 'cluster')]
        [ArgumentCompleter({ ArgK8sGetClusters @args })]
        [string]$Cluster
    )

    begin {
        # get kubectl contexts
        $ctxs = Get-KubectlContext -Object

        # get context name
        $ctx = if ($PSBoundParameters.Context) {
            $ctxs.Where({ $_.name -eq $Context }).name
        } elseif ($PSBoundParameters.Cluster) {
            $ctxs.Where({ $_.cluster -eq $Cluster }).name
        } else {
            Get-KubectlContext -Object `
            | Select-Object name, cluster, namespace `
            | Get-ArrayIndexMenu -Value -Message 'Select kubernetes context to switch to.' `
            | Select-Object -ExpandProperty name
        }
    }

    process {
        if ($ctx) {
            # execute command
            $cmnd = @('config', 'use-context', $ctx)
            Invoke-WriteExecKubectl -Command $cmnd
            # set kubectl binary to server version
            Set-KubectlLocal
        } else {
            Write-Warning "$($Context ? "Context '$Context'" : "Cluster '$Cluster'") not found."
        }
    }
}


<#
.SYNOPSIS
Get list of available kubernetes contexts.
#>
function Remove-KubectlContext {
    $ctx = Get-KubectlContext -Object | Select-Object name, cluster, user | Get-ArrayIndexMenu -Value

    # unset context
    kubectl config unset "contexts.$($ctx.name)"
    kubectl config unset "clusters.$($ctx.cluster)"
    kubectl config unset "users.$($ctx.user)"
}


<#
.SYNOPSIS
Get list of available kubernetes contexts.

.PARAMETER Table
Switch whether to return the output in table format.
.PARAMETER Json
Switch whether to return the output in JSON format.
.PARAMETER Object
Switch whether to return the output as a PowerShell object.
.PARAMETER Context
Get kubernetes context details by context name.
.PARAMETER Cluster
Get kubernetes context details by cluster name.
.PARAMETER Current
The parameter to specify if the current context should be returned.
#>
function Get-KubectlContext {
    [CmdletBinding(DefaultParameterSetName = 'table')]
    param (
        [Parameter(ParameterSetName = 'table')]
        [switch]$Table,

        [Parameter(ParameterSetName = 'json')]
        [switch]$Json,

        [Parameter(ParameterSetName = 'object')]
        [switch]$Object,

        [Alias('n')]
        [Parameter(Mandatory, ParameterSetName = 'context')]
        [Parameter(ParameterSetName = 'table')]
        [Parameter(ParameterSetName = 'json')]
        [Parameter(ParameterSetName = 'object')]
        [string]$Context,

        [Alias('c')]
        [Parameter(Mandatory, ParameterSetName = 'cluster')]
        [Parameter(ParameterSetName = 'table')]
        [Parameter(ParameterSetName = 'json')]
        [Parameter(ParameterSetName = 'object')]
        [string]$Cluster,

        [Parameter(Mandatory, ParameterSetName = 'current')]
        [Parameter(ParameterSetName = 'table')]
        [Parameter(ParameterSetName = 'json')]
        [Parameter(ParameterSetName = 'object')]
        [switch]$Current
    )

    begin {
        [System.Collections.Generic.List[string]]$cmdArgs = @()
        # get kubectl config
        @('config', 'view', '--output', 'json').ForEach({ $cmdArgs.Add($_) })
        if ($PSBoundParameters.Current) {
            $cmdArgs.Add('--minify')
        }
        Write-Debug "kubectl $($cmdArgs -join ' ')"
        $config = & kubectl @cmdArgs | ConvertFrom-Json
    }

    process {
        # create context objects
        $ctxs = foreach ($ctx in $config.contexts) {
            [PSCustomObject]@{
                '@'       = $ctx.name -eq $config.'current-context' ? '*' : $null
                name      = $ctx.name
                cluster   = $ctx.context.cluster
                namespace = $ctx.context.namespace
                user      = $ctx.context.user
            }
        }

        # filter contexts
        if ($PSBoundParameters.Cluster) {
            $ctxs = $ctxs.Where({ $_.cluster -eq $Cluster })
        } elseif ($PSBoundParameters.Context) {
            $ctxs = $ctxs.Where({ $_.name -eq $Context })
        }

    }

    end {
        # return output
        switch ($PsCmdlet.ParameterSetName) {
            json {
                if (Get-Command jq -CommandType Application -ErrorAction SilentlyContinue) {
                    $ctxs | ConvertTo-Json | jq
                } else {
                    $ctxs | ConvertTo-Json
                }
            }
            object {
                $ctxs
            }
            table {
                $ctxs | Format-Table
            }
        }
    }
}


<#
.SYNOPSIS
Downloads kubectl client version corresponding to kubernetes server version and creates symbolic link
to the client in $HOME/.local/bin directory.
.DESCRIPTION
Function requires the $HOME/.local/bin directory to be preceding path in $PATH environment variable.
#>
function Set-KubectlLocal {
    begin {
        # determine kubectl binary name
        $KUBECTL = $IsWindows ? 'kubectl.exe' : 'kubectl'
        # calculate paths
        $LOCAL_BIN = [IO.Path]::Combine($HOME, '.local', 'bin')
        $KUBECTL_LOCAL = [IO.Path]::Combine($LOCAL_BIN, $KUBECTL)
        $KUBECTL_DIR = [IO.Path]::Combine($HOME, '.local', 'share', 'kubectl')
        # initialize retry variable for kubectl download loop
        $RETRY_COUNT = 0
    }

    process {
        # check kubernetes server version
        $serverVersion = Get-KubectlServerVersion
        if (-not $serverVersion) {
            Write-Warning 'Server not available.'
            break
        }
        # calculate kubectl path corresponding to server version
        $kctlVer = [IO.Path]::Combine($KUBECTL_DIR, $serverVersion, $KUBECTL)

        # check if ~/.local/bin/kubectl symbolic link points to the above path
        if ((Get-ItemPropertyValue $KUBECTL_LOCAL -Name LinkTarget -ErrorAction SilentlyContinue) -ne $kctlVer) {
            if (-not (Test-Path $LOCAL_BIN)) {
                New-Item $LOCAL_BIN -ItemType Directory | Out-Null
            }
            if (-not (Test-Path $kctlVer -PathType Leaf)) {
                New-Item $([IO.Path]::Combine($KUBECTL_DIR, $serverVersion)) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
                $dlSysArch = if ($IsWindows) {
                    'windows/amd64'
                } elseif ($IsLinux) {
                    'linux/amd64'
                } elseif ($IsMacOS) {
                    'darwin/arm64'
                }
                do {
                    [Net.WebClient]::new().DownloadFile("https://dl.k8s.io/release/${serverVersion}/bin/$dlSysArch/$KUBECTL", $kctlVer)
                    $RETRY_COUNT++
                } until ((Test-Path $kctlVer -PathType Leaf) -or $RETRY_COUNT -ge 2)
            }

            # replace existing ~/.local/bin/kubectl symbolic link
            if (Test-Path $kctlVer -PathType Leaf) {
                New-Item -ItemType SymbolicLink -Path $KUBECTL_LOCAL -Target $kctlVer -Force | Out-Null
            }
        }
    }

    clean {
        # add executable bit to the kubectl binary
        if ($serverVersion) {
            if (-not $IsWindows -and (Test-Path $kctlVer -PathType Leaf) -and ((Get-Item $kctlVer).UnixMode -ne '-rwxr-xr-x')) {
                chmod +x $kctlVer
            }
        }

        # check if the symbolic link points to the existing file and remove otherwise
        if ((Test-Path $KUBECTL_LOCAL -PathType Leaf) -and (Get-ItemPropertyValue $KUBECTL_LOCAL -Name 'LinkType')) {
            $linkTarget = Get-ItemPropertyValue $KUBECTL_LOCAL -Name LinkTarget
            if (-not (Test-Path $linkTarget -PathType Leaf)) {
                Remove-Item $KUBECTL_LOCAL -Force
            }
        }
    }
}


<#
.SYNOPSIS
Connect remotely to the specified pod on the cluster. By default sh shell is being executed.

.PARAMETER Pod
Name of the pod to connect to.
.PARAMETER Container
Explicitly specify the container in the pod to connect to.
.PARAMETER Namespace
Specify namespace of the pod.
.PARAMETER Command
Specify to run any specified command.
.PARAMETER bash
Specify to run bash shell.
.PARAMETER python
Specify to run python REPL.
.PARAMETER pwsh
Specify to run PowerShell shell.
#>
function Connect-KubernetesContainer {
    [CmdletBinding(DefaultParameterSetName = 'Shell')]
    param (
        [Alias('p')]
        [Parameter(Position = 0, Mandatory = $true)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [string]$Pod,

        [Alias('c')]
        [Parameter(Position = 1)]
        [ArgumentCompleter({ ArgK8sGetPodContainers @args })]
        [string]$Container,

        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace,

        [Alias('cmd')]
        [Parameter(ParameterSetName = 'Command')]
        [string]$Command,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$bash,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$python,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$pwsh
    )

    begin {
        # build kubectl command parameters
        $cmnd = [System.Collections.Generic.List[string]]::new([string[]]@('exec', '--stdin', '--tty'))
        $cmnd.Add($PSBoundParameters.Pod)
        if ($PSBoundParameters.Namespace) {
            $cmnd.AddRange([string[]]@('--namespace', $Namespace))
        }
        if ($PSBoundParameters.Container) {
            $cmnd.AddRange([string[]]@('--container', $Container))
        }
        # specify command to be used in the container
        switch ($PsCmdlet.ParameterSetName) {
            Shell {
                if ($PSBoundParameters.bash) {
                    $cmnd.AddRange([string[]]@('--', 'bash'))
                } elseif ($PSBoundParameters.python) {
                    $cmnd.AddRange([string[]]@('--', 'python'))
                } elseif ($PSBoundParameters.PowerShell) {
                    $cmnd.AddRange([string[]]@('--', 'pwsh'))
                } else {
                    $cmnd.AddRange([string[]]@('--', 'sh'))
                }
            }
            Command {
                $cmnd.AddRange([string[]]@('--', $Command))
            }
        }
    }

    process {
        # execute command
        Invoke-WriteExecKubectl -Command $cmnd
    }
}


<#
.SYNOPSIS
Debug cluster pods using interactive debugging containers.

.PARAMETER Pod
Name of the pod to be debugged.
.PARAMETER Namespace
Specify namespace of the pod.
.PARAMETER Command
Specify to run any specified command in the debug container.
.PARAMETER bash
Specify to run bash shell in the debug container.
.PARAMETER python
Specify to run python REPL in the debug container.
.PARAMETER pwsh
Specify to run PowerShell shell in the debug container.
#>
function Debug-KubernetesPod {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [string]$Pod,

        [Parameter(Position = 1)]
        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace,

        [ValidateNotNullOrEmpty()]
        [string]$Image = 'busybox',

        [Alias('cmd')]
        [Parameter(ParameterSetName = 'Command')]
        [string]$Command,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$sh,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$bash,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$python,

        [Parameter(ParameterSetName = 'Shell')]
        [switch]$pwsh
    )

    begin {
        # build kubectl command parameters
        $cmnd = [System.Collections.Generic.List[string]]::new([string[]]@('debug', '--stdin', '--tty'))
        $cmnd.AddRange([string[]]@($PSBoundParameters.Pod, "--image=$Image"))
        if ($PSBoundParameters.Namespace) {
            $cmnd.AddRange([string[]]@('--namespace', $Namespace))
        }
        # specify command to be used in the container
        switch ($PsCmdlet.ParameterSetName) {
            Shell {
                if ($PSBoundParameters.bash) {
                    $cmnd.AddRange([string[]]@('--', 'bash'))
                } elseif ($PSBoundParameters.python) {
                    $cmnd.AddRange([string[]]@('--', 'python'))
                } elseif ($PSBoundParameters.PowerShell) {
                    $cmnd.AddRange([string[]]@('--', 'pwsh'))
                } else {
                    $cmnd.AddRange([string[]]@('--', 'sh'))
                }
            }
            Command {
                $cmnd.AddRange([string[]]@('--', $Command))
            }
        }
    }

    process {
        # execute command
        Invoke-WriteExecKubectl -Command $cmnd
    }
}


<#
.SYNOPSIS
Get logs from the specified pod.

.PARAMETER Pod
Name of the pod to get logs from.
.PARAMETER Container
Specify container in the pod to get logs from.
.PARAMETER Namespace
Specify namespace of the pod.
#>
function Get-KubectlPodLogs {
    [CmdletBinding(DefaultParameterSetName = 'Shell')]
    param (
        [Alias('p')]
        [Parameter(Position = 0, Mandatory = $true)]
        [ArgumentCompleter({ ArgK8sGetPods @args })]
        [string]$Pod,

        [Alias('c')]
        [Parameter(Position = 1)]
        [ArgumentCompleter({ ArgK8sGetPodContainers @args })]
        [string]$Container,

        [ArgumentCompleter({ ArgK8sGetNamespaces @args })]
        [string]$Namespace
    )

    begin {
        # build kubectl command parameters
        $cmnd = [System.Collections.Generic.List[string]]::new([string[]]@('logs', '-f'))
        $cmnd.Add($PSBoundParameters.Pod)
        if ($PSBoundParameters.Namespace) {
            $cmnd.AddRange([string[]]@('--namespace', $Namespace))
        }
        if ($PSBoundParameters.Container) {
            $cmnd.AddRange([string[]]@('--container', $Container))
        }
    }

    process {
        # execute command
        Invoke-WriteExecKubectl -Command $cmnd
    }
}


function Get-KubectlApiResourceShortNames {
    [CmdletBinding()]
    param ()

    begin {
        Write-Debug 'Retrieving kubernetes API resources...'
        $apiResources = kubectl api-resources
        if (-not $?) {
            throw 'Failed to retrieve kubernetes API resources.'
        }
        Write-Debug "kubectl api-resources returned $($apiResources.Length - 1) results."

        # index columns
        $idxName = $apiResources[0].IndexOf('NAME')
        $idxShort = $apiResources[0].IndexOf('SHORTNAMES')
        $idxAPI = $apiResources[0].IndexOf('APIVERSION')
    }

    process {
        # parse API resources
        # return as list of objects
        $collection = [System.Collections.Generic.List[pscustomobject]]::new()
        for ($i = 1; $i -lt $apiResources.Length; $i++) {
            $apiResource = [PSCustomObject]@{
                Name       = $apiResources[$i].Substring($idxName, $idxShort).TrimEnd()
                ShortNames = $apiResources[$i].Substring($idxShort, $idxAPI - $idxShort).TrimEnd().Split(',')
            }
            if ($apiResource.ShortNames) {
                $collection.Add($apiResource)
            }
        }
    }

    end {
        $collection | Sort-Object -Property Name
    }
}

<#
.SYNOPSIS
Get kubernetes short names for resources.
#>
function kapishortnames {
    $apiResources = (Get-KubectlApiResources -AsObject).Where({ $_.ShortName })

    $props = @(
        @{ Name = 'Name'; Expression = { $_.Plural } }
        @{ Name = 'ShortName'; Expression = { $_.ShortName -join ',' } }
    )
    $apiResources | Select-Object -Property $props | Sort-Object Name
}
#endregion


#region aliases
New-Alias -Name kv -Value Get-KubectlVersion
New-Alias -Name kvc -Value Get-KubectlClientVersion
New-Alias -Name kvs -Value Get-KubectlServerVersion
New-Alias -Name kcgctx -Value Get-KubectlContext
New-Alias -Name kcuctx -Value Set-KubectlContext
New-Alias -Name kc -Value Set-KubectlContext
New-Alias -Name kcrmctx -Value Remove-KubectlContext
New-Alias -Name kcsctxcns -Value Set-KubectlContextCurrentNamespace
New-Alias -Name kex -Value Connect-KubernetesContainer
New-Alias -Name kdbg -Value Debug-KubernetesPod
New-Alias -Name klo -Value Get-KubectlPodLogs
if (Test-Path '/usr/bin/kubens' -PathType Leaf) {
    New-Alias -Name kn -Value Set-KubensContextCurrentNamespace
} else {
    New-Alias -Name kn -Value Set-KubectlContextCurrentNamespace
}
New-Alias -Name kapishorts -Value Get-KubectlApiResourceShortNames
#endregion
