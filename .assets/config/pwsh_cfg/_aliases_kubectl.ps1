#region internal functions
<#
.SYNOPSIS
Write provided command with its arguments and then execute it.
You can suppress writing the command by providing -Quiet as one of the arguments.
You can suppress executing the command by providing -WhatIf as one of the arguments.

.PARAMETER Command
Command to be executed.
.PARAMETER Arguments
Command arguments to be passed to the provided command.
.PARAMETER Parameters
Control parameters: WhatIf, Quiet.
#>
function Invoke-WriteExecCmd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Command,

        [Parameter(ParameterSetName = 'Arguments')]
        [string[]]$Arguments,

        [Parameter(ParameterSetName = 'Parameters')]
        [string[]]$Parameters
    )

    begin {
        # clean up command from control parameters
        $Command = $Command -replace (' -WhatIf| -Quiet')
        # calculate control parameters
        $Parameters = $($Parameters ? $Parameters : $Arguments).Where({ $_ -match '^-WhatIf$|^-Quiet$' })
        # remove control parameters from arguments and quote arguments with spaces
        $Arguments = $Arguments.Where({ $_ -notmatch '^-WhatIf$|^-Quiet$' }).ForEach({ $_ -match '\s' ? "'$_'" : $_ })
        # build the command expression
        $cmd = "$Command $Arguments"
    }

    process {
        if ('-Quiet' -notin $Parameters) {
            # write the command
            Write-Host $cmd -ForegroundColor Magenta
        }
        if ('-WhatIf' -notin $Parameters) {
            # execute the command
            Invoke-Expression $cmd
        }
    }
}
#endregion

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
Downloads kubectl client version corresponding to kubernetes server version and creates symbolic link
to the client in $HOME/.local/bin directory.
.DESCRIPTION
Function requires the $HOME/.local/bin directory to be preceding path in $PATH environment variable.
#>
function Set-KubectlLocal {
    $LOCAL_BIN = [IO.Path]::Combine($HOME, '.local', 'bin')
    $KUBECTL = $IsWindows ? 'kubectl.exe' : 'kubectl'
    $KUBECTL_LOCAL = [IO.Path]::Combine($LOCAL_BIN, $KUBECTL)
    $KUBECTL_DIR = [IO.Path]::Combine($HOME, '.local', 'share', 'kubectl')

    $serverVersion = Get-KubectlServerVersion
    if (-not $serverVersion) {
        Write-Warning 'Server not available.'
        break
    }
    $kctlVer = [IO.Path]::Combine($KUBECTL_DIR, $serverVersion, $KUBECTL)

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
            } until (Test-Path $kctlVer -PathType Leaf)
            if (-not $IsWindows) {
                chmod +x $kctlVer
            }
        }
        Remove-Item $KUBECTL_LOCAL -Force -ErrorAction SilentlyContinue
        New-Item -ItemType SymbolicLink -Path $KUBECTL_LOCAL -Target $kctlVer | Out-Null
    }
}

<#
.SYNOPSIS
Get list of available kubernetes contexts.
#>
function Get-KubectlContext {
    (kubectl config get-contexts) -replace '\s+', "`f" `
    | ConvertFrom-Csv -Delimiter "`f" `
    | Format-Table @{ N = '@'; E = { $_.CURRENT } }, NAME, CLUSTER, NAMESPACE
}

<#
.SYNOPSIS
Change kubernetes context and sets the corresponding kubectl client version.
#>
function Set-KubectlContext {
    Write-Host "kubectl config use-context $args" -ForegroundColor Magenta
    kubectl config use-context @args
    Set-KubectlLocal
}
#endregion

#region aliases
Set-Alias -Name k -Value kubectl
Set-Alias -Name kv -Value Get-KubectlVersion
Set-Alias -Name kvc -Value Get-KubectlClientVersion
Set-Alias -Name kvs -Value Get-KubectlServerVersion
Set-Alias -Name kcgctx -Value Get-KubectlContext
Set-Alias -Name kcuctx -Value Set-KubectlContext
#endregion

#region alias functions
function ktop { Invoke-WriteExecCmd -Command 'kubectl top pod --use-protocol-buffers' -Arguments $args }
function ktopcntr { Invoke-WriteExecCmd -Command 'kubectl top pod --use-protocol-buffers --containers' -Arguments $args }
function kinf { Invoke-WriteExecCmd -Command 'kubectl cluster-info' -Arguments $args }
function kav { Invoke-WriteExecCmd -Command 'kubectl api-versions' -Arguments $args }
function kcv { Invoke-WriteExecCmd -Command 'kubectl config view' -Arguments $args }
function kcsctxcns { Invoke-WriteExecCmd -Command 'kubectl config set-context --current --namespace' -Arguments $args }
function ksys { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system' -Arguments $args }
function ka { Invoke-WriteExecCmd -Command 'kubectl apply --recursive -f' -Arguments $args }
function ksysa { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system apply --recursive -f' -Arguments $args }
function kak { Invoke-WriteExecCmd -Command 'kubectl apply -k' -Arguments $args }
function kk { Invoke-WriteExecCmd -Command 'kubectl kustomize' -Arguments $args }
function krmk { Invoke-WriteExecCmd -Command 'kubectl delete -k' -Arguments $args }
function kex { Invoke-WriteExecCmd -Command 'kubectl exec -i -t' -Arguments $args }
function kexsh { Invoke-WriteExecCmd -Command "kubectl exec -i -t $args -- sh" -Parameters $args }
function kexbash { Invoke-WriteExecCmd -Command "kubectl exec -i -t $args -- bash" -Parameters $args }
function kexpwsh { Invoke-WriteExecCmd -Command "kubectl exec -i -t $args -- pwsh" -Parameters $args }
function kexpy { Invoke-WriteExecCmd -Command "kubectl exec -i -t $args -- python" -Parameters $args }
function kexipy { Invoke-WriteExecCmd -Command "kubectl exec -i -t $args -- ipython" -Parameters $args }
function kre { Invoke-WriteExecCmd -Command 'kubectl replace' -Arguments $args }
function kre! { Invoke-WriteExecCmd -Command 'kubectl replace --force' -Arguments $args }
function kref { Invoke-WriteExecCmd -Command 'kubectl replace -f' -Arguments $args }
function kref! { Invoke-WriteExecCmd -Command 'kubectl replace --force -f' -Arguments $args }
function ksysex { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system exec -i -t' -Arguments $args }
function klo { Invoke-WriteExecCmd -Command 'kubectl logs -f' -Arguments $args }
function ksyslo { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system logs -f' -Arguments $args }
function klop { Invoke-WriteExecCmd -Command 'kubectl logs -f -p' -Arguments $args }
function ksyslop { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system logs -f -p' -Arguments $args }
function kp { Invoke-WriteExecCmd -Command 'kubectl proxy' -Arguments $args }
function kpf { Invoke-WriteExecCmd -Command 'kubectl port-forward' -Arguments $args }
function kg { Invoke-WriteExecCmd -Command 'kubectl get' -Arguments $args }
function ksysg { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get' -Arguments $args }
function kd { Invoke-WriteExecCmd -Command 'kubectl describe' -Arguments $args }
function ksysd { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe' -Arguments $args }
function krm { Invoke-WriteExecCmd -Command 'kubectl delete' -Arguments $args }
function ksysrm { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete' -Arguments $args }
function krun { Invoke-WriteExecCmd -Command 'kubectl run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t' -Arguments $args }
function ksysrun { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t' -Arguments $args }
function kgpo { Invoke-WriteExecCmd -Command 'kubectl get pods' -Arguments $args }
function ksysgpo { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods' -Arguments $args }
function kdpo { Invoke-WriteExecCmd -Command 'kubectl describe pods' -Arguments $args }
function ksysdpo { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe pods' -Arguments $args }
function krmpo { Invoke-WriteExecCmd -Command 'kubectl delete pods' -Arguments $args }
function ksysrmpo { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete pods' -Arguments $args }
function kgdep { Invoke-WriteExecCmd -Command 'kubectl get deployment' -Arguments $args }
function ksysgdep { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment' -Arguments $args }
function kddep { Invoke-WriteExecCmd -Command 'kubectl describe deployment' -Arguments $args }
function ksysddep { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe deployment' -Arguments $args }
function krmdep { Invoke-WriteExecCmd -Command 'kubectl delete deployment' -Arguments $args }
function ksysrmdep { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete deployment' -Arguments $args }
function kgsvc { Invoke-WriteExecCmd -Command 'kubectl get service' -Arguments $args }
function ksysgsvc { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service' -Arguments $args }
function kdsvc { Invoke-WriteExecCmd -Command 'kubectl describe service' -Arguments $args }
function ksysdsvc { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe service' -Arguments $args }
function krmsvc { Invoke-WriteExecCmd -Command 'kubectl delete service' -Arguments $args }
function ksysrmsvc { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete service' -Arguments $args }
function kging { Invoke-WriteExecCmd -Command 'kubectl get ingress' -Arguments $args }
function ksysging { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress' -Arguments $args }
function kding { Invoke-WriteExecCmd -Command 'kubectl describe ingress' -Arguments $args }
function ksysding { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe ingress' -Arguments $args }
function krming { Invoke-WriteExecCmd -Command 'kubectl delete ingress' -Arguments $args }
function ksysrming { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete ingress' -Arguments $args }
function kgcm { Invoke-WriteExecCmd -Command 'kubectl get configmap' -Arguments $args }
function ksysgcm { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap' -Arguments $args }
function kdcm { Invoke-WriteExecCmd -Command 'kubectl describe configmap' -Arguments $args }
function ksysdcm { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe configmap' -Arguments $args }
function krmcm { Invoke-WriteExecCmd -Command 'kubectl delete configmap' -Arguments $args }
function ksysrmcm { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete configmap' -Arguments $args }
function kgsec { Invoke-WriteExecCmd -Command 'kubectl get secret' -Arguments $args }
function ksysgsec { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret' -Arguments $args }
function kdsec { Invoke-WriteExecCmd -Command 'kubectl describe secret' -Arguments $args }
function ksysdsec { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe secret' -Arguments $args }
function krmsec { Invoke-WriteExecCmd -Command 'kubectl delete secret' -Arguments $args }
function ksysrmsec { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete secret' -Arguments $args }
function kgno { Invoke-WriteExecCmd -Command 'kubectl get nodes' -Arguments $args }
function kdno { Invoke-WriteExecCmd -Command 'kubectl describe nodes' -Arguments $args }
function kgns { Invoke-WriteExecCmd -Command 'kubectl get namespaces' -Arguments $args }
function kdns { Invoke-WriteExecCmd -Command 'kubectl describe namespaces' -Arguments $args }
function krmns { Invoke-WriteExecCmd -Command 'kubectl delete namespaces' -Arguments $args }
function kgoyaml { Invoke-WriteExecCmd -Command 'kubectl get -o=yaml' -Arguments $args }
function ksysgoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get -o=yaml' -Arguments $args }
function kgpooyaml { Invoke-WriteExecCmd -Command 'kubectl get pods -o=yaml' -Arguments $args }
function ksysgpooyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods -o=yaml' -Arguments $args }
function kgdepoyaml { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=yaml' -Arguments $args }
function ksysgdepoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment -o=yaml' -Arguments $args }
function kgsvcoyaml { Invoke-WriteExecCmd -Command 'kubectl get service -o=yaml' -Arguments $args }
function ksysgsvcoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service -o=yaml' -Arguments $args }
function kgingoyaml { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=yaml' -Arguments $args }
function ksysgingoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress -o=yaml' -Arguments $args }
function kgcmoyaml { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=yaml' -Arguments $args }
function ksysgcmoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap -o=yaml' -Arguments $args }
function kgsecoyaml { Invoke-WriteExecCmd -Command 'kubectl get secret -o=yaml' -Arguments $args }
function ksysgsecoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret -o=yaml' -Arguments $args }
function kgnooyaml { Invoke-WriteExecCmd -Command 'kubectl get nodes -o=yaml' -Arguments $args }
function kgnsoyaml { Invoke-WriteExecCmd -Command 'kubectl get namespaces -o=yaml' -Arguments $args }
function kgowide { Invoke-WriteExecCmd -Command 'kubectl get -o=wide' -Arguments $args }
function ksysgowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get -o=wide' -Arguments $args }
function kgpoowide { Invoke-WriteExecCmd -Command 'kubectl get pods -o=wide' -Arguments $args }
function ksysgpoowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods -o=wide' -Arguments $args }
function kgdepowide { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=wide' -Arguments $args }
function ksysgdepowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment -o=wide' -Arguments $args }
function kgsvcowide { Invoke-WriteExecCmd -Command 'kubectl get service -o=wide' -Arguments $args }
function ksysgsvcowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service -o=wide' -Arguments $args }
function kgingowide { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=wide' -Arguments $args }
function ksysgingowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress -o=wide' -Arguments $args }
function kgcmowide { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=wide' -Arguments $args }
function ksysgcmowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap -o=wide' -Arguments $args }
function kgsecowide { Invoke-WriteExecCmd -Command 'kubectl get secret -o=wide' -Arguments $args }
function ksysgsecowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret -o=wide' -Arguments $args }
function kgnoowide { Invoke-WriteExecCmd -Command 'kubectl get nodes -o=wide' -Arguments $args }
function kgnsowide { Invoke-WriteExecCmd -Command 'kubectl get namespaces -o=wide' -Arguments $args }
function kgojson { Invoke-WriteExecCmd -Command 'kubectl get -o=json' -Arguments $args }
function ksysgojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get -o=json' -Arguments $args }
function kgpoojson { Invoke-WriteExecCmd -Command 'kubectl get pods -o=json' -Arguments $args }
function ksysgpoojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods -o=json' -Arguments $args }
function kgdepojson { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=json' -Arguments $args }
function ksysgdepojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment -o=json' -Arguments $args }
function kgsvcojson { Invoke-WriteExecCmd -Command 'kubectl get service -o=json' -Arguments $args }
function ksysgsvcojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service -o=json' -Arguments $args }
function kgingojson { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=json' -Arguments $args }
function ksysgingojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress -o=json' -Arguments $args }
function kgcmojson { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=json' -Arguments $args }
function ksysgcmojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap -o=json' -Arguments $args }
function kgsecojson { Invoke-WriteExecCmd -Command 'kubectl get secret -o=json' -Arguments $args }
function ksysgsecojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret -o=json' -Arguments $args }
function kgnoojson { Invoke-WriteExecCmd -Command 'kubectl get nodes -o=json' -Arguments $args }
function kgnsojson { Invoke-WriteExecCmd -Command 'kubectl get namespaces -o=json' -Arguments $args }
function kgall { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces' -Arguments $args }
function kdall { Invoke-WriteExecCmd -Command 'kubectl describe --all-namespaces' -Arguments $args }
function kgpoall { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces' -Arguments $args }
function kdpoall { Invoke-WriteExecCmd -Command 'kubectl describe pods --all-namespaces' -Arguments $args }
function kgdepall { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces' -Arguments $args }
function kddepall { Invoke-WriteExecCmd -Command 'kubectl describe deployment --all-namespaces' -Arguments $args }
function kgsvcall { Invoke-WriteExecCmd -Command 'kubectl get service --all-namespaces' -Arguments $args }
function kdsvcall { Invoke-WriteExecCmd -Command 'kubectl describe service --all-namespaces' -Arguments $args }
function kgingall { Invoke-WriteExecCmd -Command 'kubectl get ingress --all-namespaces' -Arguments $args }
function kdingall { Invoke-WriteExecCmd -Command 'kubectl describe ingress --all-namespaces' -Arguments $args }
function kgcmall { Invoke-WriteExecCmd -Command 'kubectl get configmap --all-namespaces' -Arguments $args }
function kdcmall { Invoke-WriteExecCmd -Command 'kubectl describe configmap --all-namespaces' -Arguments $args }
function kgsecall { Invoke-WriteExecCmd -Command 'kubectl get secret --all-namespaces' -Arguments $args }
function kdsecall { Invoke-WriteExecCmd -Command 'kubectl describe secret --all-namespaces' -Arguments $args }
function kgnsall { Invoke-WriteExecCmd -Command 'kubectl get namespaces --all-namespaces' -Arguments $args }
function kdnsall { Invoke-WriteExecCmd -Command 'kubectl describe namespaces --all-namespaces' -Arguments $args }
function kgsl { Invoke-WriteExecCmd -Command 'kubectl get --show-labels' -Arguments $args }
function ksysgsl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --show-labels' -Arguments $args }
function kgposl { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels' -Arguments $args }
function ksysgposl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --show-labels' -Arguments $args }
function kgdepsl { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels' -Arguments $args }
function ksysgdepsl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --show-labels' -Arguments $args }
function krmall { Invoke-WriteExecCmd -Command 'kubectl delete --all' -Arguments $args }
function ksysrmall { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete --all' -Arguments $args }
function krmpoall { Invoke-WriteExecCmd -Command 'kubectl delete pods --all' -Arguments $args }
function ksysrmpoall { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete pods --all' -Arguments $args }
function krmdepall { Invoke-WriteExecCmd -Command 'kubectl delete deployment --all' -Arguments $args }
function ksysrmdepall { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete deployment --all' -Arguments $args }
function krmsvcall { Invoke-WriteExecCmd -Command 'kubectl delete service --all' -Arguments $args }
function ksysrmsvcall { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete service --all' -Arguments $args }
function krmingall { Invoke-WriteExecCmd -Command 'kubectl delete ingress --all' -Arguments $args }
function ksysrmingall { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete ingress --all' -Arguments $args }
function krmcmall { Invoke-WriteExecCmd -Command 'kubectl delete configmap --all' -Arguments $args }
function ksysrmcmall { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete configmap --all' -Arguments $args }
function krmsecall { Invoke-WriteExecCmd -Command 'kubectl delete secret --all' -Arguments $args }
function ksysrmsecall { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete secret --all' -Arguments $args }
function krmnsall { Invoke-WriteExecCmd -Command 'kubectl delete namespaces --all' -Arguments $args }
function kgw { Invoke-WriteExecCmd -Command 'kubectl get --watch' -Arguments $args }
function ksysgw { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch' -Arguments $args }
function kgpow { Invoke-WriteExecCmd -Command 'kubectl get pods --watch' -Arguments $args }
function ksysgpow { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch' -Arguments $args }
function kgdepw { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch' -Arguments $args }
function ksysgdepw { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch' -Arguments $args }
function kgsvcw { Invoke-WriteExecCmd -Command 'kubectl get service --watch' -Arguments $args }
function ksysgsvcw { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service --watch' -Arguments $args }
function kgingw { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch' -Arguments $args }
function ksysgingw { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress --watch' -Arguments $args }
function kgcmw { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch' -Arguments $args }
function ksysgcmw { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap --watch' -Arguments $args }
function kgsecw { Invoke-WriteExecCmd -Command 'kubectl get secret --watch' -Arguments $args }
function ksysgsecw { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret --watch' -Arguments $args }
function kgnow { Invoke-WriteExecCmd -Command 'kubectl get nodes --watch' -Arguments $args }
function kgnsw { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch' -Arguments $args }
function kgoyamlall { Invoke-WriteExecCmd -Command 'kubectl get -o=yaml --all-namespaces' -Arguments $args }
function kgpooyamlall { Invoke-WriteExecCmd -Command 'kubectl get pods -o=yaml --all-namespaces' -Arguments $args }
function kgdepoyamlall { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=yaml --all-namespaces' -Arguments $args }
function kgsvcoyamlall { Invoke-WriteExecCmd -Command 'kubectl get service -o=yaml --all-namespaces' -Arguments $args }
function kgingoyamlall { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=yaml --all-namespaces' -Arguments $args }
function kgcmoyamlall { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=yaml --all-namespaces' -Arguments $args }
function kgsecoyamlall { Invoke-WriteExecCmd -Command 'kubectl get secret -o=yaml --all-namespaces' -Arguments $args }
function kgnsoyamlall { Invoke-WriteExecCmd -Command 'kubectl get namespaces -o=yaml --all-namespaces' -Arguments $args }
function kgalloyaml { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces -o=yaml' -Arguments $args }
function kgpoalloyaml { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces -o=yaml' -Arguments $args }
function kgdepalloyaml { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces -o=yaml' -Arguments $args }
function kgsvcalloyaml { Invoke-WriteExecCmd -Command 'kubectl get service --all-namespaces -o=yaml' -Arguments $args }
function kgingalloyaml { Invoke-WriteExecCmd -Command 'kubectl get ingress --all-namespaces -o=yaml' -Arguments $args }
function kgcmalloyaml { Invoke-WriteExecCmd -Command 'kubectl get configmap --all-namespaces -o=yaml' -Arguments $args }
function kgsecalloyaml { Invoke-WriteExecCmd -Command 'kubectl get secret --all-namespaces -o=yaml' -Arguments $args }
function kgnsalloyaml { Invoke-WriteExecCmd -Command 'kubectl get namespaces --all-namespaces -o=yaml' -Arguments $args }
function kgwoyaml { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=yaml' -Arguments $args }
function ksysgwoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch -o=yaml' -Arguments $args }
function kgpowoyaml { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=yaml' -Arguments $args }
function ksysgpowoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch -o=yaml' -Arguments $args }
function kgdepwoyaml { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=yaml' -Arguments $args }
function ksysgdepwoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch -o=yaml' -Arguments $args }
function kgsvcwoyaml { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=yaml' -Arguments $args }
function ksysgsvcwoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service --watch -o=yaml' -Arguments $args }
function kgingwoyaml { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=yaml' -Arguments $args }
function ksysgingwoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress --watch -o=yaml' -Arguments $args }
function kgcmwoyaml { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=yaml' -Arguments $args }
function ksysgcmwoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap --watch -o=yaml' -Arguments $args }
function kgsecwoyaml { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=yaml' -Arguments $args }
function ksysgsecwoyaml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret --watch -o=yaml' -Arguments $args }
function kgnowoyaml { Invoke-WriteExecCmd -Command 'kubectl get nodes --watch -o=yaml' -Arguments $args }
function kgnswoyaml { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch -o=yaml' -Arguments $args }
function kgowideall { Invoke-WriteExecCmd -Command 'kubectl get -o=wide --all-namespaces' -Arguments $args }
function kgpoowideall { Invoke-WriteExecCmd -Command 'kubectl get pods -o=wide --all-namespaces' -Arguments $args }
function kgdepowideall { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=wide --all-namespaces' -Arguments $args }
function kgsvcowideall { Invoke-WriteExecCmd -Command 'kubectl get service -o=wide --all-namespaces' -Arguments $args }
function kgingowideall { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=wide --all-namespaces' -Arguments $args }
function kgcmowideall { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=wide --all-namespaces' -Arguments $args }
function kgsecowideall { Invoke-WriteExecCmd -Command 'kubectl get secret -o=wide --all-namespaces' -Arguments $args }
function kgnsowideall { Invoke-WriteExecCmd -Command 'kubectl get namespaces -o=wide --all-namespaces' -Arguments $args }
function kgallowide { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces -o=wide' -Arguments $args }
function kgpoallowide { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces -o=wide' -Arguments $args }
function kgdepallowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces -o=wide' -Arguments $args }
function kgsvcallowide { Invoke-WriteExecCmd -Command 'kubectl get service --all-namespaces -o=wide' -Arguments $args }
function kgingallowide { Invoke-WriteExecCmd -Command 'kubectl get ingress --all-namespaces -o=wide' -Arguments $args }
function kgcmallowide { Invoke-WriteExecCmd -Command 'kubectl get configmap --all-namespaces -o=wide' -Arguments $args }
function kgsecallowide { Invoke-WriteExecCmd -Command 'kubectl get secret --all-namespaces -o=wide' -Arguments $args }
function kgnsallowide { Invoke-WriteExecCmd -Command 'kubectl get namespaces --all-namespaces -o=wide' -Arguments $args }
function kgowidesl { Invoke-WriteExecCmd -Command 'kubectl get -o=wide --show-labels' -Arguments $args }
function ksysgowidesl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get -o=wide --show-labels' -Arguments $args }
function kgpoowidesl { Invoke-WriteExecCmd -Command 'kubectl get pods -o=wide --show-labels' -Arguments $args }
function ksysgpoowidesl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods -o=wide --show-labels' -Arguments $args }
function kgdepowidesl { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=wide --show-labels' -Arguments $args }
function ksysgdepowidesl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment -o=wide --show-labels' -Arguments $args }
function kgslowide { Invoke-WriteExecCmd -Command 'kubectl get --show-labels -o=wide' -Arguments $args }
function ksysgslowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --show-labels -o=wide' -Arguments $args }
function kgposlowide { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels -o=wide' -Arguments $args }
function ksysgposlowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --show-labels -o=wide' -Arguments $args }
function kgdepslowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels -o=wide' -Arguments $args }
function ksysgdepslowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --show-labels -o=wide' -Arguments $args }
function kgwowide { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=wide' -Arguments $args }
function ksysgwowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch -o=wide' -Arguments $args }
function kgpowowide { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=wide' -Arguments $args }
function ksysgpowowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch -o=wide' -Arguments $args }
function kgdepwowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=wide' -Arguments $args }
function ksysgdepwowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch -o=wide' -Arguments $args }
function kgsvcwowide { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=wide' -Arguments $args }
function ksysgsvcwowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service --watch -o=wide' -Arguments $args }
function kgingwowide { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=wide' -Arguments $args }
function ksysgingwowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress --watch -o=wide' -Arguments $args }
function kgcmwowide { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=wide' -Arguments $args }
function ksysgcmwowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap --watch -o=wide' -Arguments $args }
function kgsecwowide { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=wide' -Arguments $args }
function ksysgsecwowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret --watch -o=wide' -Arguments $args }
function kgnowowide { Invoke-WriteExecCmd -Command 'kubectl get nodes --watch -o=wide' -Arguments $args }
function kgnswowide { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch -o=wide' -Arguments $args }
function kgojsonall { Invoke-WriteExecCmd -Command 'kubectl get -o=json --all-namespaces' -Arguments $args }
function kgpoojsonall { Invoke-WriteExecCmd -Command 'kubectl get pods -o=json --all-namespaces' -Arguments $args }
function kgdepojsonall { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=json --all-namespaces' -Arguments $args }
function kgsvcojsonall { Invoke-WriteExecCmd -Command 'kubectl get service -o=json --all-namespaces' -Arguments $args }
function kgingojsonall { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=json --all-namespaces' -Arguments $args }
function kgcmojsonall { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=json --all-namespaces' -Arguments $args }
function kgsecojsonall { Invoke-WriteExecCmd -Command 'kubectl get secret -o=json --all-namespaces' -Arguments $args }
function kgnsojsonall { Invoke-WriteExecCmd -Command 'kubectl get namespaces -o=json --all-namespaces' -Arguments $args }
function kgallojson { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces -o=json' -Arguments $args }
function kgpoallojson { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces -o=json' -Arguments $args }
function kgdepallojson { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces -o=json' -Arguments $args }
function kgsvcallojson { Invoke-WriteExecCmd -Command 'kubectl get service --all-namespaces -o=json' -Arguments $args }
function kgingallojson { Invoke-WriteExecCmd -Command 'kubectl get ingress --all-namespaces -o=json' -Arguments $args }
function kgcmallojson { Invoke-WriteExecCmd -Command 'kubectl get configmap --all-namespaces -o=json' -Arguments $args }
function kgsecallojson { Invoke-WriteExecCmd -Command 'kubectl get secret --all-namespaces -o=json' -Arguments $args }
function kgnsallojson { Invoke-WriteExecCmd -Command 'kubectl get namespaces --all-namespaces -o=json' -Arguments $args }
function kgwojson { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=json' -Arguments $args }
function ksysgwojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch -o=json' -Arguments $args }
function kgpowojson { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=json' -Arguments $args }
function ksysgpowojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch -o=json' -Arguments $args }
function kgdepwojson { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=json' -Arguments $args }
function ksysgdepwojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch -o=json' -Arguments $args }
function kgsvcwojson { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=json' -Arguments $args }
function ksysgsvcwojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service --watch -o=json' -Arguments $args }
function kgingwojson { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=json' -Arguments $args }
function ksysgingwojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress --watch -o=json' -Arguments $args }
function kgcmwojson { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=json' -Arguments $args }
function ksysgcmwojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap --watch -o=json' -Arguments $args }
function kgsecwojson { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=json' -Arguments $args }
function ksysgsecwojson { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret --watch -o=json' -Arguments $args }
function kgnowojson { Invoke-WriteExecCmd -Command 'kubectl get nodes --watch -o=json' -Arguments $args }
function kgnswojson { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch -o=json' -Arguments $args }
function kgallsl { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces --show-labels' -Arguments $args }
function kgpoallsl { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces --show-labels' -Arguments $args }
function kgdepallsl { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces --show-labels' -Arguments $args }
function kgslall { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --all-namespaces' -Arguments $args }
function kgposlall { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --all-namespaces' -Arguments $args }
function kgdepslall { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --all-namespaces' -Arguments $args }
function kgallw { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces --watch' -Arguments $args }
function kgpoallw { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces --watch' -Arguments $args }
function kgdepallw { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces --watch' -Arguments $args }
function kgsvcallw { Invoke-WriteExecCmd -Command 'kubectl get service --all-namespaces --watch' -Arguments $args }
function kgingallw { Invoke-WriteExecCmd -Command 'kubectl get ingress --all-namespaces --watch' -Arguments $args }
function kgcmallw { Invoke-WriteExecCmd -Command 'kubectl get configmap --all-namespaces --watch' -Arguments $args }
function kgsecallw { Invoke-WriteExecCmd -Command 'kubectl get secret --all-namespaces --watch' -Arguments $args }
function kgnsallw { Invoke-WriteExecCmd -Command 'kubectl get namespaces --all-namespaces --watch' -Arguments $args }
function kgwall { Invoke-WriteExecCmd -Command 'kubectl get --watch --all-namespaces' -Arguments $args }
function kgpowall { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --all-namespaces' -Arguments $args }
function kgdepwall { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --all-namespaces' -Arguments $args }
function kgsvcwall { Invoke-WriteExecCmd -Command 'kubectl get service --watch --all-namespaces' -Arguments $args }
function kgingwall { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch --all-namespaces' -Arguments $args }
function kgcmwall { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch --all-namespaces' -Arguments $args }
function kgsecwall { Invoke-WriteExecCmd -Command 'kubectl get secret --watch --all-namespaces' -Arguments $args }
function kgnswall { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch --all-namespaces' -Arguments $args }
function kgslw { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --watch' -Arguments $args }
function ksysgslw { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --show-labels --watch' -Arguments $args }
function kgposlw { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --watch' -Arguments $args }
function ksysgposlw { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --show-labels --watch' -Arguments $args }
function kgdepslw { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --watch' -Arguments $args }
function ksysgdepslw { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --show-labels --watch' -Arguments $args }
function kgwsl { Invoke-WriteExecCmd -Command 'kubectl get --watch --show-labels' -Arguments $args }
function ksysgwsl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch --show-labels' -Arguments $args }
function kgpowsl { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --show-labels' -Arguments $args }
function ksysgpowsl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch --show-labels' -Arguments $args }
function kgdepwsl { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --show-labels' -Arguments $args }
function ksysgdepwsl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch --show-labels' -Arguments $args }
function kgallwoyaml { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces --watch -o=yaml' -Arguments $args }
function kgpoallwoyaml { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces --watch -o=yaml' -Arguments $args }
function kgdepallwoyaml { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces --watch -o=yaml' -Arguments $args }
function kgsvcallwoyaml { Invoke-WriteExecCmd -Command 'kubectl get service --all-namespaces --watch -o=yaml' -Arguments $args }
function kgingallwoyaml { Invoke-WriteExecCmd -Command 'kubectl get ingress --all-namespaces --watch -o=yaml' -Arguments $args }
function kgcmallwoyaml { Invoke-WriteExecCmd -Command 'kubectl get configmap --all-namespaces --watch -o=yaml' -Arguments $args }
function kgsecallwoyaml { Invoke-WriteExecCmd -Command 'kubectl get secret --all-namespaces --watch -o=yaml' -Arguments $args }
function kgnsallwoyaml { Invoke-WriteExecCmd -Command 'kubectl get namespaces --all-namespaces --watch -o=yaml' -Arguments $args }
function kgwoyamlall { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=yaml --all-namespaces' -Arguments $args }
function kgpowoyamlall { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=yaml --all-namespaces' -Arguments $args }
function kgdepwoyamlall { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=yaml --all-namespaces' -Arguments $args }
function kgsvcwoyamlall { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=yaml --all-namespaces' -Arguments $args }
function kgingwoyamlall { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=yaml --all-namespaces' -Arguments $args }
function kgcmwoyamlall { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=yaml --all-namespaces' -Arguments $args }
function kgsecwoyamlall { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=yaml --all-namespaces' -Arguments $args }
function kgnswoyamlall { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch -o=yaml --all-namespaces' -Arguments $args }
function kgwalloyaml { Invoke-WriteExecCmd -Command 'kubectl get --watch --all-namespaces -o=yaml' -Arguments $args }
function kgpowalloyaml { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --all-namespaces -o=yaml' -Arguments $args }
function kgdepwalloyaml { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --all-namespaces -o=yaml' -Arguments $args }
function kgsvcwalloyaml { Invoke-WriteExecCmd -Command 'kubectl get service --watch --all-namespaces -o=yaml' -Arguments $args }
function kgingwalloyaml { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch --all-namespaces -o=yaml' -Arguments $args }
function kgcmwalloyaml { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch --all-namespaces -o=yaml' -Arguments $args }
function kgsecwalloyaml { Invoke-WriteExecCmd -Command 'kubectl get secret --watch --all-namespaces -o=yaml' -Arguments $args }
function kgnswalloyaml { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch --all-namespaces -o=yaml' -Arguments $args }
function kgowideallsl { Invoke-WriteExecCmd -Command 'kubectl get -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgpoowideallsl { Invoke-WriteExecCmd -Command 'kubectl get pods -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgdepowideallsl { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgowideslall { Invoke-WriteExecCmd -Command 'kubectl get -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgpoowideslall { Invoke-WriteExecCmd -Command 'kubectl get pods -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgdepowideslall { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgallowidesl { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgpoallowidesl { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgdepallowidesl { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgallslowide { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgpoallslowide { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgdepallslowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgslowideall { Invoke-WriteExecCmd -Command 'kubectl get --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgposlowideall { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgdepslowideall { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgslallowide { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgposlallowide { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgdepslallowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgallwowide { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces --watch -o=wide' -Arguments $args }
function kgpoallwowide { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces --watch -o=wide' -Arguments $args }
function kgdepallwowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces --watch -o=wide' -Arguments $args }
function kgsvcallwowide { Invoke-WriteExecCmd -Command 'kubectl get service --all-namespaces --watch -o=wide' -Arguments $args }
function kgingallwowide { Invoke-WriteExecCmd -Command 'kubectl get ingress --all-namespaces --watch -o=wide' -Arguments $args }
function kgcmallwowide { Invoke-WriteExecCmd -Command 'kubectl get configmap --all-namespaces --watch -o=wide' -Arguments $args }
function kgsecallwowide { Invoke-WriteExecCmd -Command 'kubectl get secret --all-namespaces --watch -o=wide' -Arguments $args }
function kgnsallwowide { Invoke-WriteExecCmd -Command 'kubectl get namespaces --all-namespaces --watch -o=wide' -Arguments $args }
function kgwowideall { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=wide --all-namespaces' -Arguments $args }
function kgpowowideall { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=wide --all-namespaces' -Arguments $args }
function kgdepwowideall { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=wide --all-namespaces' -Arguments $args }
function kgsvcwowideall { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=wide --all-namespaces' -Arguments $args }
function kgingwowideall { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=wide --all-namespaces' -Arguments $args }
function kgcmwowideall { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=wide --all-namespaces' -Arguments $args }
function kgsecwowideall { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=wide --all-namespaces' -Arguments $args }
function kgnswowideall { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch -o=wide --all-namespaces' -Arguments $args }
function kgwallowide { Invoke-WriteExecCmd -Command 'kubectl get --watch --all-namespaces -o=wide' -Arguments $args }
function kgpowallowide { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --all-namespaces -o=wide' -Arguments $args }
function kgdepwallowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --all-namespaces -o=wide' -Arguments $args }
function kgsvcwallowide { Invoke-WriteExecCmd -Command 'kubectl get service --watch --all-namespaces -o=wide' -Arguments $args }
function kgingwallowide { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch --all-namespaces -o=wide' -Arguments $args }
function kgcmwallowide { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch --all-namespaces -o=wide' -Arguments $args }
function kgsecwallowide { Invoke-WriteExecCmd -Command 'kubectl get secret --watch --all-namespaces -o=wide' -Arguments $args }
function kgnswallowide { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch --all-namespaces -o=wide' -Arguments $args }
function kgslwowide { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --watch -o=wide' -Arguments $args }
function ksysgslwowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --show-labels --watch -o=wide' -Arguments $args }
function kgposlwowide { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --watch -o=wide' -Arguments $args }
function ksysgposlwowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --show-labels --watch -o=wide' -Arguments $args }
function kgdepslwowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --watch -o=wide' -Arguments $args }
function ksysgdepslwowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide' -Arguments $args }
function kgwowidesl { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=wide --show-labels' -Arguments $args }
function ksysgwowidesl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch -o=wide --show-labels' -Arguments $args }
function kgpowowidesl { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=wide --show-labels' -Arguments $args }
function ksysgpowowidesl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch -o=wide --show-labels' -Arguments $args }
function kgdepwowidesl { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=wide --show-labels' -Arguments $args }
function ksysgdepwowidesl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels' -Arguments $args }
function kgwslowide { Invoke-WriteExecCmd -Command 'kubectl get --watch --show-labels -o=wide' -Arguments $args }
function ksysgwslowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch --show-labels -o=wide' -Arguments $args }
function kgpowslowide { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --show-labels -o=wide' -Arguments $args }
function ksysgpowslowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch --show-labels -o=wide' -Arguments $args }
function kgdepwslowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --show-labels -o=wide' -Arguments $args }
function ksysgdepwslowide { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide' -Arguments $args }
function kgallwojson { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces --watch -o=json' -Arguments $args }
function kgpoallwojson { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces --watch -o=json' -Arguments $args }
function kgdepallwojson { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces --watch -o=json' -Arguments $args }
function kgsvcallwojson { Invoke-WriteExecCmd -Command 'kubectl get service --all-namespaces --watch -o=json' -Arguments $args }
function kgingallwojson { Invoke-WriteExecCmd -Command 'kubectl get ingress --all-namespaces --watch -o=json' -Arguments $args }
function kgcmallwojson { Invoke-WriteExecCmd -Command 'kubectl get configmap --all-namespaces --watch -o=json' -Arguments $args }
function kgsecallwojson { Invoke-WriteExecCmd -Command 'kubectl get secret --all-namespaces --watch -o=json' -Arguments $args }
function kgnsallwojson { Invoke-WriteExecCmd -Command 'kubectl get namespaces --all-namespaces --watch -o=json' -Arguments $args }
function kgwojsonall { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=json --all-namespaces' -Arguments $args }
function kgpowojsonall { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=json --all-namespaces' -Arguments $args }
function kgdepwojsonall { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=json --all-namespaces' -Arguments $args }
function kgsvcwojsonall { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=json --all-namespaces' -Arguments $args }
function kgingwojsonall { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=json --all-namespaces' -Arguments $args }
function kgcmwojsonall { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=json --all-namespaces' -Arguments $args }
function kgsecwojsonall { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=json --all-namespaces' -Arguments $args }
function kgnswojsonall { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch -o=json --all-namespaces' -Arguments $args }
function kgwallojson { Invoke-WriteExecCmd -Command 'kubectl get --watch --all-namespaces -o=json' -Arguments $args }
function kgpowallojson { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --all-namespaces -o=json' -Arguments $args }
function kgdepwallojson { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --all-namespaces -o=json' -Arguments $args }
function kgsvcwallojson { Invoke-WriteExecCmd -Command 'kubectl get service --watch --all-namespaces -o=json' -Arguments $args }
function kgingwallojson { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch --all-namespaces -o=json' -Arguments $args }
function kgcmwallojson { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch --all-namespaces -o=json' -Arguments $args }
function kgsecwallojson { Invoke-WriteExecCmd -Command 'kubectl get secret --watch --all-namespaces -o=json' -Arguments $args }
function kgnswallojson { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch --all-namespaces -o=json' -Arguments $args }
function kgallslw { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces --show-labels --watch' -Arguments $args }
function kgpoallslw { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces --show-labels --watch' -Arguments $args }
function kgdepallslw { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces --show-labels --watch' -Arguments $args }
function kgallwsl { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces --watch --show-labels' -Arguments $args }
function kgpoallwsl { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces --watch --show-labels' -Arguments $args }
function kgdepallwsl { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces --watch --show-labels' -Arguments $args }
function kgslallw { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --all-namespaces --watch' -Arguments $args }
function kgposlallw { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --all-namespaces --watch' -Arguments $args }
function kgdepslallw { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --all-namespaces --watch' -Arguments $args }
function kgslwall { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --watch --all-namespaces' -Arguments $args }
function kgposlwall { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --watch --all-namespaces' -Arguments $args }
function kgdepslwall { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --watch --all-namespaces' -Arguments $args }
function kgwallsl { Invoke-WriteExecCmd -Command 'kubectl get --watch --all-namespaces --show-labels' -Arguments $args }
function kgpowallsl { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --all-namespaces --show-labels' -Arguments $args }
function kgdepwallsl { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --all-namespaces --show-labels' -Arguments $args }
function kgwslall { Invoke-WriteExecCmd -Command 'kubectl get --watch --show-labels --all-namespaces' -Arguments $args }
function kgpowslall { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --show-labels --all-namespaces' -Arguments $args }
function kgdepwslall { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --show-labels --all-namespaces' -Arguments $args }
function kgallslwowide { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces --show-labels --watch -o=wide' -Arguments $args }
function kgpoallslwowide { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces --show-labels --watch -o=wide' -Arguments $args }
function kgdepallslwowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces --show-labels --watch -o=wide' -Arguments $args }
function kgallwowidesl { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces --watch -o=wide --show-labels' -Arguments $args }
function kgpoallwowidesl { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces --watch -o=wide --show-labels' -Arguments $args }
function kgdepallwowidesl { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces --watch -o=wide --show-labels' -Arguments $args }
function kgallwslowide { Invoke-WriteExecCmd -Command 'kubectl get --all-namespaces --watch --show-labels -o=wide' -Arguments $args }
function kgpoallwslowide { Invoke-WriteExecCmd -Command 'kubectl get pods --all-namespaces --watch --show-labels -o=wide' -Arguments $args }
function kgdepallwslowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --all-namespaces --watch --show-labels -o=wide' -Arguments $args }
function kgslallwowide { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --all-namespaces --watch -o=wide' -Arguments $args }
function kgposlallwowide { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --all-namespaces --watch -o=wide' -Arguments $args }
function kgdepslallwowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --all-namespaces --watch -o=wide' -Arguments $args }
function kgslwowideall { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --watch -o=wide --all-namespaces' -Arguments $args }
function kgposlwowideall { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --watch -o=wide --all-namespaces' -Arguments $args }
function kgdepslwowideall { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --watch -o=wide --all-namespaces' -Arguments $args }
function kgslwallowide { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --watch --all-namespaces -o=wide' -Arguments $args }
function kgposlwallowide { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --watch --all-namespaces -o=wide' -Arguments $args }
function kgdepslwallowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --watch --all-namespaces -o=wide' -Arguments $args }
function kgwowideallsl { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgpowowideallsl { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgdepwowideallsl { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgwowideslall { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgpowowideslall { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgdepwowideslall { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgwallowidesl { Invoke-WriteExecCmd -Command 'kubectl get --watch --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgpowallowidesl { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgdepwallowidesl { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgwallslowide { Invoke-WriteExecCmd -Command 'kubectl get --watch --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgpowallslowide { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgdepwallslowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgwslowideall { Invoke-WriteExecCmd -Command 'kubectl get --watch --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgpowslowideall { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgdepwslowideall { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgwslallowide { Invoke-WriteExecCmd -Command 'kubectl get --watch --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgpowslallowide { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgdepwslallowide { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgf { Invoke-WriteExecCmd -Command 'kubectl get --recursive -f' -Arguments $args }
function kdf { Invoke-WriteExecCmd -Command 'kubectl describe --recursive -f' -Arguments $args }
function krmf { Invoke-WriteExecCmd -Command 'kubectl delete --recursive -f' -Arguments $args }
function kgoyamlf { Invoke-WriteExecCmd -Command 'kubectl get -o=yaml --recursive -f' -Arguments $args }
function kgowidef { Invoke-WriteExecCmd -Command 'kubectl get -o=wide --recursive -f' -Arguments $args }
function kgojsonf { Invoke-WriteExecCmd -Command 'kubectl get -o=json --recursive -f' -Arguments $args }
function kgslf { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --recursive -f' -Arguments $args }
function kgwf { Invoke-WriteExecCmd -Command 'kubectl get --watch --recursive -f' -Arguments $args }
function kgwoyamlf { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=yaml --recursive -f' -Arguments $args }
function kgowideslf { Invoke-WriteExecCmd -Command 'kubectl get -o=wide --show-labels --recursive -f' -Arguments $args }
function kgslowidef { Invoke-WriteExecCmd -Command 'kubectl get --show-labels -o=wide --recursive -f' -Arguments $args }
function kgwowidef { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=wide --recursive -f' -Arguments $args }
function kgwojsonf { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=json --recursive -f' -Arguments $args }
function kgslwf { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --watch --recursive -f' -Arguments $args }
function kgwslf { Invoke-WriteExecCmd -Command 'kubectl get --watch --show-labels --recursive -f' -Arguments $args }
function kgslwowidef { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --watch -o=wide --recursive -f' -Arguments $args }
function kgwowideslf { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=wide --show-labels --recursive -f' -Arguments $args }
function kgwslowidef { Invoke-WriteExecCmd -Command 'kubectl get --watch --show-labels -o=wide --recursive -f' -Arguments $args }
function kgl { Invoke-WriteExecCmd -Command 'kubectl get -l' -Arguments $args }
function ksysgl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get -l' -Arguments $args }
function kdl { Invoke-WriteExecCmd -Command 'kubectl describe -l' -Arguments $args }
function ksysdl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe -l' -Arguments $args }
function krml { Invoke-WriteExecCmd -Command 'kubectl delete -l' -Arguments $args }
function ksysrml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete -l' -Arguments $args }
function kgpol { Invoke-WriteExecCmd -Command 'kubectl get pods -l' -Arguments $args }
function ksysgpol { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods -l' -Arguments $args }
function kdpol { Invoke-WriteExecCmd -Command 'kubectl describe pods -l' -Arguments $args }
function ksysdpol { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe pods -l' -Arguments $args }
function krmpol { Invoke-WriteExecCmd -Command 'kubectl delete pods -l' -Arguments $args }
function ksysrmpol { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete pods -l' -Arguments $args }
function kgdepl { Invoke-WriteExecCmd -Command 'kubectl get deployment -l' -Arguments $args }
function ksysgdepl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment -l' -Arguments $args }
function kddepl { Invoke-WriteExecCmd -Command 'kubectl describe deployment -l' -Arguments $args }
function ksysddepl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe deployment -l' -Arguments $args }
function krmdepl { Invoke-WriteExecCmd -Command 'kubectl delete deployment -l' -Arguments $args }
function ksysrmdepl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete deployment -l' -Arguments $args }
function kgsvcl { Invoke-WriteExecCmd -Command 'kubectl get service -l' -Arguments $args }
function ksysgsvcl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service -l' -Arguments $args }
function kdsvcl { Invoke-WriteExecCmd -Command 'kubectl describe service -l' -Arguments $args }
function ksysdsvcl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe service -l' -Arguments $args }
function krmsvcl { Invoke-WriteExecCmd -Command 'kubectl delete service -l' -Arguments $args }
function ksysrmsvcl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete service -l' -Arguments $args }
function kgingl { Invoke-WriteExecCmd -Command 'kubectl get ingress -l' -Arguments $args }
function ksysgingl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress -l' -Arguments $args }
function kdingl { Invoke-WriteExecCmd -Command 'kubectl describe ingress -l' -Arguments $args }
function ksysdingl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe ingress -l' -Arguments $args }
function krmingl { Invoke-WriteExecCmd -Command 'kubectl delete ingress -l' -Arguments $args }
function ksysrmingl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete ingress -l' -Arguments $args }
function kgcml { Invoke-WriteExecCmd -Command 'kubectl get configmap -l' -Arguments $args }
function ksysgcml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap -l' -Arguments $args }
function kdcml { Invoke-WriteExecCmd -Command 'kubectl describe configmap -l' -Arguments $args }
function ksysdcml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe configmap -l' -Arguments $args }
function krmcml { Invoke-WriteExecCmd -Command 'kubectl delete configmap -l' -Arguments $args }
function ksysrmcml { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete configmap -l' -Arguments $args }
function kgsecl { Invoke-WriteExecCmd -Command 'kubectl get secret -l' -Arguments $args }
function ksysgsecl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret -l' -Arguments $args }
function kdsecl { Invoke-WriteExecCmd -Command 'kubectl describe secret -l' -Arguments $args }
function ksysdsecl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system describe secret -l' -Arguments $args }
function krmsecl { Invoke-WriteExecCmd -Command 'kubectl delete secret -l' -Arguments $args }
function ksysrmsecl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system delete secret -l' -Arguments $args }
function kgnol { Invoke-WriteExecCmd -Command 'kubectl get nodes -l' -Arguments $args }
function kdnol { Invoke-WriteExecCmd -Command 'kubectl describe nodes -l' -Arguments $args }
function kgnsl { Invoke-WriteExecCmd -Command 'kubectl get namespaces -l' -Arguments $args }
function kdnsl { Invoke-WriteExecCmd -Command 'kubectl describe namespaces -l' -Arguments $args }
function krmnsl { Invoke-WriteExecCmd -Command 'kubectl delete namespaces -l' -Arguments $args }
function kgoyamll { Invoke-WriteExecCmd -Command 'kubectl get -o=yaml -l' -Arguments $args }
function ksysgoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get -o=yaml -l' -Arguments $args }
function kgpooyamll { Invoke-WriteExecCmd -Command 'kubectl get pods -o=yaml -l' -Arguments $args }
function ksysgpooyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods -o=yaml -l' -Arguments $args }
function kgdepoyamll { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=yaml -l' -Arguments $args }
function ksysgdepoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment -o=yaml -l' -Arguments $args }
function kgsvcoyamll { Invoke-WriteExecCmd -Command 'kubectl get service -o=yaml -l' -Arguments $args }
function ksysgsvcoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service -o=yaml -l' -Arguments $args }
function kgingoyamll { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=yaml -l' -Arguments $args }
function ksysgingoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress -o=yaml -l' -Arguments $args }
function kgcmoyamll { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=yaml -l' -Arguments $args }
function ksysgcmoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap -o=yaml -l' -Arguments $args }
function kgsecoyamll { Invoke-WriteExecCmd -Command 'kubectl get secret -o=yaml -l' -Arguments $args }
function ksysgsecoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret -o=yaml -l' -Arguments $args }
function kgnooyamll { Invoke-WriteExecCmd -Command 'kubectl get nodes -o=yaml -l' -Arguments $args }
function kgnsoyamll { Invoke-WriteExecCmd -Command 'kubectl get namespaces -o=yaml -l' -Arguments $args }
function kgowidel { Invoke-WriteExecCmd -Command 'kubectl get -o=wide -l' -Arguments $args }
function ksysgowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get -o=wide -l' -Arguments $args }
function kgpoowidel { Invoke-WriteExecCmd -Command 'kubectl get pods -o=wide -l' -Arguments $args }
function ksysgpoowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods -o=wide -l' -Arguments $args }
function kgdepowidel { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=wide -l' -Arguments $args }
function ksysgdepowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment -o=wide -l' -Arguments $args }
function kgsvcowidel { Invoke-WriteExecCmd -Command 'kubectl get service -o=wide -l' -Arguments $args }
function ksysgsvcowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service -o=wide -l' -Arguments $args }
function kgingowidel { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=wide -l' -Arguments $args }
function ksysgingowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress -o=wide -l' -Arguments $args }
function kgcmowidel { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=wide -l' -Arguments $args }
function ksysgcmowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap -o=wide -l' -Arguments $args }
function kgsecowidel { Invoke-WriteExecCmd -Command 'kubectl get secret -o=wide -l' -Arguments $args }
function ksysgsecowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret -o=wide -l' -Arguments $args }
function kgnoowidel { Invoke-WriteExecCmd -Command 'kubectl get nodes -o=wide -l' -Arguments $args }
function kgnsowidel { Invoke-WriteExecCmd -Command 'kubectl get namespaces -o=wide -l' -Arguments $args }
function kgojsonl { Invoke-WriteExecCmd -Command 'kubectl get -o=json -l' -Arguments $args }
function ksysgojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get -o=json -l' -Arguments $args }
function kgpoojsonl { Invoke-WriteExecCmd -Command 'kubectl get pods -o=json -l' -Arguments $args }
function ksysgpoojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods -o=json -l' -Arguments $args }
function kgdepojsonl { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=json -l' -Arguments $args }
function ksysgdepojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment -o=json -l' -Arguments $args }
function kgsvcojsonl { Invoke-WriteExecCmd -Command 'kubectl get service -o=json -l' -Arguments $args }
function ksysgsvcojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service -o=json -l' -Arguments $args }
function kgingojsonl { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=json -l' -Arguments $args }
function ksysgingojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress -o=json -l' -Arguments $args }
function kgcmojsonl { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=json -l' -Arguments $args }
function ksysgcmojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap -o=json -l' -Arguments $args }
function kgsecojsonl { Invoke-WriteExecCmd -Command 'kubectl get secret -o=json -l' -Arguments $args }
function ksysgsecojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret -o=json -l' -Arguments $args }
function kgnoojsonl { Invoke-WriteExecCmd -Command 'kubectl get nodes -o=json -l' -Arguments $args }
function kgnsojsonl { Invoke-WriteExecCmd -Command 'kubectl get namespaces -o=json -l' -Arguments $args }
function kgsll { Invoke-WriteExecCmd -Command 'kubectl get --show-labels -l' -Arguments $args }
function ksysgsll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --show-labels -l' -Arguments $args }
function kgposll { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels -l' -Arguments $args }
function ksysgposll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --show-labels -l' -Arguments $args }
function kgdepsll { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels -l' -Arguments $args }
function ksysgdepsll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --show-labels -l' -Arguments $args }
function kgwl { Invoke-WriteExecCmd -Command 'kubectl get --watch -l' -Arguments $args }
function ksysgwl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch -l' -Arguments $args }
function kgpowl { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -l' -Arguments $args }
function ksysgpowl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch -l' -Arguments $args }
function kgdepwl { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -l' -Arguments $args }
function ksysgdepwl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch -l' -Arguments $args }
function kgsvcwl { Invoke-WriteExecCmd -Command 'kubectl get service --watch -l' -Arguments $args }
function ksysgsvcwl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service --watch -l' -Arguments $args }
function kgingwl { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -l' -Arguments $args }
function ksysgingwl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress --watch -l' -Arguments $args }
function kgcmwl { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -l' -Arguments $args }
function ksysgcmwl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap --watch -l' -Arguments $args }
function kgsecwl { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -l' -Arguments $args }
function ksysgsecwl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret --watch -l' -Arguments $args }
function kgnowl { Invoke-WriteExecCmd -Command 'kubectl get nodes --watch -l' -Arguments $args }
function kgnswl { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch -l' -Arguments $args }
function kgwoyamll { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=yaml -l' -Arguments $args }
function ksysgwoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch -o=yaml -l' -Arguments $args }
function kgpowoyamll { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=yaml -l' -Arguments $args }
function ksysgpowoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch -o=yaml -l' -Arguments $args }
function kgdepwoyamll { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=yaml -l' -Arguments $args }
function ksysgdepwoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch -o=yaml -l' -Arguments $args }
function kgsvcwoyamll { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=yaml -l' -Arguments $args }
function ksysgsvcwoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service --watch -o=yaml -l' -Arguments $args }
function kgingwoyamll { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=yaml -l' -Arguments $args }
function ksysgingwoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress --watch -o=yaml -l' -Arguments $args }
function kgcmwoyamll { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=yaml -l' -Arguments $args }
function ksysgcmwoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap --watch -o=yaml -l' -Arguments $args }
function kgsecwoyamll { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=yaml -l' -Arguments $args }
function ksysgsecwoyamll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret --watch -o=yaml -l' -Arguments $args }
function kgnowoyamll { Invoke-WriteExecCmd -Command 'kubectl get nodes --watch -o=yaml -l' -Arguments $args }
function kgnswoyamll { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch -o=yaml -l' -Arguments $args }
function kgowidesll { Invoke-WriteExecCmd -Command 'kubectl get -o=wide --show-labels -l' -Arguments $args }
function ksysgowidesll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get -o=wide --show-labels -l' -Arguments $args }
function kgpoowidesll { Invoke-WriteExecCmd -Command 'kubectl get pods -o=wide --show-labels -l' -Arguments $args }
function ksysgpoowidesll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods -o=wide --show-labels -l' -Arguments $args }
function kgdepowidesll { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=wide --show-labels -l' -Arguments $args }
function ksysgdepowidesll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment -o=wide --show-labels -l' -Arguments $args }
function kgslowidel { Invoke-WriteExecCmd -Command 'kubectl get --show-labels -o=wide -l' -Arguments $args }
function ksysgslowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --show-labels -o=wide -l' -Arguments $args }
function kgposlowidel { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels -o=wide -l' -Arguments $args }
function ksysgposlowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --show-labels -o=wide -l' -Arguments $args }
function kgdepslowidel { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels -o=wide -l' -Arguments $args }
function ksysgdepslowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --show-labels -o=wide -l' -Arguments $args }
function kgwowidel { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=wide -l' -Arguments $args }
function ksysgwowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch -o=wide -l' -Arguments $args }
function kgpowowidel { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=wide -l' -Arguments $args }
function ksysgpowowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch -o=wide -l' -Arguments $args }
function kgdepwowidel { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=wide -l' -Arguments $args }
function ksysgdepwowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch -o=wide -l' -Arguments $args }
function kgsvcwowidel { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=wide -l' -Arguments $args }
function ksysgsvcwowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service --watch -o=wide -l' -Arguments $args }
function kgingwowidel { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=wide -l' -Arguments $args }
function ksysgingwowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress --watch -o=wide -l' -Arguments $args }
function kgcmwowidel { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=wide -l' -Arguments $args }
function ksysgcmwowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap --watch -o=wide -l' -Arguments $args }
function kgsecwowidel { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=wide -l' -Arguments $args }
function ksysgsecwowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret --watch -o=wide -l' -Arguments $args }
function kgnowowidel { Invoke-WriteExecCmd -Command 'kubectl get nodes --watch -o=wide -l' -Arguments $args }
function kgnswowidel { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch -o=wide -l' -Arguments $args }
function kgwojsonl { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=json -l' -Arguments $args }
function ksysgwojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch -o=json -l' -Arguments $args }
function kgpowojsonl { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=json -l' -Arguments $args }
function ksysgpowojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch -o=json -l' -Arguments $args }
function kgdepwojsonl { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=json -l' -Arguments $args }
function ksysgdepwojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch -o=json -l' -Arguments $args }
function kgsvcwojsonl { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=json -l' -Arguments $args }
function ksysgsvcwojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get service --watch -o=json -l' -Arguments $args }
function kgingwojsonl { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=json -l' -Arguments $args }
function ksysgingwojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get ingress --watch -o=json -l' -Arguments $args }
function kgcmwojsonl { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=json -l' -Arguments $args }
function ksysgcmwojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get configmap --watch -o=json -l' -Arguments $args }
function kgsecwojsonl { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=json -l' -Arguments $args }
function ksysgsecwojsonl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get secret --watch -o=json -l' -Arguments $args }
function kgnowojsonl { Invoke-WriteExecCmd -Command 'kubectl get nodes --watch -o=json -l' -Arguments $args }
function kgnswojsonl { Invoke-WriteExecCmd -Command 'kubectl get namespaces --watch -o=json -l' -Arguments $args }
function kgslwl { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --watch -l' -Arguments $args }
function ksysgslwl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --show-labels --watch -l' -Arguments $args }
function kgposlwl { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --watch -l' -Arguments $args }
function ksysgposlwl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --show-labels --watch -l' -Arguments $args }
function kgdepslwl { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --watch -l' -Arguments $args }
function ksysgdepslwl { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --show-labels --watch -l' -Arguments $args }
function kgwsll { Invoke-WriteExecCmd -Command 'kubectl get --watch --show-labels -l' -Arguments $args }
function ksysgwsll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch --show-labels -l' -Arguments $args }
function kgpowsll { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --show-labels -l' -Arguments $args }
function ksysgpowsll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch --show-labels -l' -Arguments $args }
function kgdepwsll { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --show-labels -l' -Arguments $args }
function ksysgdepwsll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch --show-labels -l' -Arguments $args }
function kgslwowidel { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --watch -o=wide -l' -Arguments $args }
function ksysgslwowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --show-labels --watch -o=wide -l' -Arguments $args }
function kgposlwowidel { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --watch -o=wide -l' -Arguments $args }
function ksysgposlwowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --show-labels --watch -o=wide -l' -Arguments $args }
function kgdepslwowidel { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --watch -o=wide -l' -Arguments $args }
function ksysgdepslwowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide -l' -Arguments $args }
function kgwowidesll { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=wide --show-labels -l' -Arguments $args }
function ksysgwowidesll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch -o=wide --show-labels -l' -Arguments $args }
function kgpowowidesll { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=wide --show-labels -l' -Arguments $args }
function ksysgpowowidesll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch -o=wide --show-labels -l' -Arguments $args }
function kgdepwowidesll { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=wide --show-labels -l' -Arguments $args }
function ksysgdepwowidesll { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels -l' -Arguments $args }
function kgwslowidel { Invoke-WriteExecCmd -Command 'kubectl get --watch --show-labels -o=wide -l' -Arguments $args }
function ksysgwslowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get --watch --show-labels -o=wide -l' -Arguments $args }
function kgpowslowidel { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --show-labels -o=wide -l' -Arguments $args }
function ksysgpowslowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get pods --watch --show-labels -o=wide -l' -Arguments $args }
function kgdepwslowidel { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --show-labels -o=wide -l' -Arguments $args }
function ksysgdepwslowidel { Invoke-WriteExecCmd -Command 'kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide -l' -Arguments $args }
function kexn { Invoke-WriteExecCmd -Command 'kubectl exec -i -t --namespace' -Arguments $args }
function klon { Invoke-WriteExecCmd -Command 'kubectl logs -f --namespace' -Arguments $args }
function kpfn { Invoke-WriteExecCmd -Command 'kubectl port-forward --namespace' -Arguments $args }
function kgn { Invoke-WriteExecCmd -Command 'kubectl get --namespace' -Arguments $args }
function kdn { Invoke-WriteExecCmd -Command 'kubectl describe --namespace' -Arguments $args }
function krmn { Invoke-WriteExecCmd -Command 'kubectl delete --namespace' -Arguments $args }
function kgpon { Invoke-WriteExecCmd -Command 'kubectl get pods --namespace' -Arguments $args }
function kdpon { Invoke-WriteExecCmd -Command 'kubectl describe pods --namespace' -Arguments $args }
function krmpon { Invoke-WriteExecCmd -Command 'kubectl delete pods --namespace' -Arguments $args }
function kgdepn { Invoke-WriteExecCmd -Command 'kubectl get deployment --namespace' -Arguments $args }
function kddepn { Invoke-WriteExecCmd -Command 'kubectl describe deployment --namespace' -Arguments $args }
function krmdepn { Invoke-WriteExecCmd -Command 'kubectl delete deployment --namespace' -Arguments $args }
function kgsvcn { Invoke-WriteExecCmd -Command 'kubectl get service --namespace' -Arguments $args }
function kdsvcn { Invoke-WriteExecCmd -Command 'kubectl describe service --namespace' -Arguments $args }
function krmsvcn { Invoke-WriteExecCmd -Command 'kubectl delete service --namespace' -Arguments $args }
function kgingn { Invoke-WriteExecCmd -Command 'kubectl get ingress --namespace' -Arguments $args }
function kdingn { Invoke-WriteExecCmd -Command 'kubectl describe ingress --namespace' -Arguments $args }
function krmingn { Invoke-WriteExecCmd -Command 'kubectl delete ingress --namespace' -Arguments $args }
function kgcmn { Invoke-WriteExecCmd -Command 'kubectl get configmap --namespace' -Arguments $args }
function kdcmn { Invoke-WriteExecCmd -Command 'kubectl describe configmap --namespace' -Arguments $args }
function krmcmn { Invoke-WriteExecCmd -Command 'kubectl delete configmap --namespace' -Arguments $args }
function kgsecn { Invoke-WriteExecCmd -Command 'kubectl get secret --namespace' -Arguments $args }
function kdsecn { Invoke-WriteExecCmd -Command 'kubectl describe secret --namespace' -Arguments $args }
function krmsecn { Invoke-WriteExecCmd -Command 'kubectl delete secret --namespace' -Arguments $args }
function kgoyamln { Invoke-WriteExecCmd -Command 'kubectl get -o=yaml --namespace' -Arguments $args }
function kgpooyamln { Invoke-WriteExecCmd -Command 'kubectl get pods -o=yaml --namespace' -Arguments $args }
function kgdepoyamln { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=yaml --namespace' -Arguments $args }
function kgsvcoyamln { Invoke-WriteExecCmd -Command 'kubectl get service -o=yaml --namespace' -Arguments $args }
function kgingoyamln { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=yaml --namespace' -Arguments $args }
function kgcmoyamln { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=yaml --namespace' -Arguments $args }
function kgsecoyamln { Invoke-WriteExecCmd -Command 'kubectl get secret -o=yaml --namespace' -Arguments $args }
function kgowiden { Invoke-WriteExecCmd -Command 'kubectl get -o=wide --namespace' -Arguments $args }
function kgpoowiden { Invoke-WriteExecCmd -Command 'kubectl get pods -o=wide --namespace' -Arguments $args }
function kgdepowiden { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=wide --namespace' -Arguments $args }
function kgsvcowiden { Invoke-WriteExecCmd -Command 'kubectl get service -o=wide --namespace' -Arguments $args }
function kgingowiden { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=wide --namespace' -Arguments $args }
function kgcmowiden { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=wide --namespace' -Arguments $args }
function kgsecowiden { Invoke-WriteExecCmd -Command 'kubectl get secret -o=wide --namespace' -Arguments $args }
function kgojsonn { Invoke-WriteExecCmd -Command 'kubectl get -o=json --namespace' -Arguments $args }
function kgpoojsonn { Invoke-WriteExecCmd -Command 'kubectl get pods -o=json --namespace' -Arguments $args }
function kgdepojsonn { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=json --namespace' -Arguments $args }
function kgsvcojsonn { Invoke-WriteExecCmd -Command 'kubectl get service -o=json --namespace' -Arguments $args }
function kgingojsonn { Invoke-WriteExecCmd -Command 'kubectl get ingress -o=json --namespace' -Arguments $args }
function kgcmojsonn { Invoke-WriteExecCmd -Command 'kubectl get configmap -o=json --namespace' -Arguments $args }
function kgsecojsonn { Invoke-WriteExecCmd -Command 'kubectl get secret -o=json --namespace' -Arguments $args }
function kgsln { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --namespace' -Arguments $args }
function kgposln { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --namespace' -Arguments $args }
function kgdepsln { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --namespace' -Arguments $args }
function kgwn { Invoke-WriteExecCmd -Command 'kubectl get --watch --namespace' -Arguments $args }
function kgpown { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --namespace' -Arguments $args }
function kgdepwn { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --namespace' -Arguments $args }
function kgsvcwn { Invoke-WriteExecCmd -Command 'kubectl get service --watch --namespace' -Arguments $args }
function kgingwn { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch --namespace' -Arguments $args }
function kgcmwn { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch --namespace' -Arguments $args }
function kgsecwn { Invoke-WriteExecCmd -Command 'kubectl get secret --watch --namespace' -Arguments $args }
function kgwoyamln { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=yaml --namespace' -Arguments $args }
function kgpowoyamln { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=yaml --namespace' -Arguments $args }
function kgdepwoyamln { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=yaml --namespace' -Arguments $args }
function kgsvcwoyamln { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=yaml --namespace' -Arguments $args }
function kgingwoyamln { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=yaml --namespace' -Arguments $args }
function kgcmwoyamln { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=yaml --namespace' -Arguments $args }
function kgsecwoyamln { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=yaml --namespace' -Arguments $args }
function kgowidesln { Invoke-WriteExecCmd -Command 'kubectl get -o=wide --show-labels --namespace' -Arguments $args }
function kgpoowidesln { Invoke-WriteExecCmd -Command 'kubectl get pods -o=wide --show-labels --namespace' -Arguments $args }
function kgdepowidesln { Invoke-WriteExecCmd -Command 'kubectl get deployment -o=wide --show-labels --namespace' -Arguments $args }
function kgslowiden { Invoke-WriteExecCmd -Command 'kubectl get --show-labels -o=wide --namespace' -Arguments $args }
function kgposlowiden { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels -o=wide --namespace' -Arguments $args }
function kgdepslowiden { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels -o=wide --namespace' -Arguments $args }
function kgwowiden { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=wide --namespace' -Arguments $args }
function kgpowowiden { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=wide --namespace' -Arguments $args }
function kgdepwowiden { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=wide --namespace' -Arguments $args }
function kgsvcwowiden { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=wide --namespace' -Arguments $args }
function kgingwowiden { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=wide --namespace' -Arguments $args }
function kgcmwowiden { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=wide --namespace' -Arguments $args }
function kgsecwowiden { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=wide --namespace' -Arguments $args }
function kgwojsonn { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=json --namespace' -Arguments $args }
function kgpowojsonn { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=json --namespace' -Arguments $args }
function kgdepwojsonn { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=json --namespace' -Arguments $args }
function kgsvcwojsonn { Invoke-WriteExecCmd -Command 'kubectl get service --watch -o=json --namespace' -Arguments $args }
function kgingwojsonn { Invoke-WriteExecCmd -Command 'kubectl get ingress --watch -o=json --namespace' -Arguments $args }
function kgcmwojsonn { Invoke-WriteExecCmd -Command 'kubectl get configmap --watch -o=json --namespace' -Arguments $args }
function kgsecwojsonn { Invoke-WriteExecCmd -Command 'kubectl get secret --watch -o=json --namespace' -Arguments $args }
function kgslwn { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --watch --namespace' -Arguments $args }
function kgposlwn { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --watch --namespace' -Arguments $args }
function kgdepslwn { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --watch --namespace' -Arguments $args }
function kgwsln { Invoke-WriteExecCmd -Command 'kubectl get --watch --show-labels --namespace' -Arguments $args }
function kgpowsln { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --show-labels --namespace' -Arguments $args }
function kgdepwsln { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --show-labels --namespace' -Arguments $args }
function kgslwowiden { Invoke-WriteExecCmd -Command 'kubectl get --show-labels --watch -o=wide --namespace' -Arguments $args }
function kgposlwowiden { Invoke-WriteExecCmd -Command 'kubectl get pods --show-labels --watch -o=wide --namespace' -Arguments $args }
function kgdepslwowiden { Invoke-WriteExecCmd -Command 'kubectl get deployment --show-labels --watch -o=wide --namespace' -Arguments $args }
function kgwowidesln { Invoke-WriteExecCmd -Command 'kubectl get --watch -o=wide --show-labels --namespace' -Arguments $args }
function kgpowowidesln { Invoke-WriteExecCmd -Command 'kubectl get pods --watch -o=wide --show-labels --namespace' -Arguments $args }
function kgdepwowidesln { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch -o=wide --show-labels --namespace' -Arguments $args }
function kgwslowiden { Invoke-WriteExecCmd -Command 'kubectl get --watch --show-labels -o=wide --namespace' -Arguments $args }
function kgpowslowiden { Invoke-WriteExecCmd -Command 'kubectl get pods --watch --show-labels -o=wide --namespace' -Arguments $args }
function kgdepwslowiden { Invoke-WriteExecCmd -Command 'kubectl get deployment --watch --show-labels -o=wide --namespace' -Arguments $args }
#endregion
