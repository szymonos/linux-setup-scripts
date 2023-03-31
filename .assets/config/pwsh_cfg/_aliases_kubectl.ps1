# helper function
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
        Write-Warning "Server not available."
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
Change kubernetes context and sets the corresponding kubectl client version.
#>
function Set-KubectlUseContext {
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
Set-Alias -Name kcuctx -Value Set-KubectlUseContext
#endregion

function ktop { Invoke-WriteExecuteCommand -Command 'kubectl top pod --use-protocol-buffers' -Arguments $args }
function ktopcntr { Invoke-WriteExecuteCommand -Command 'kubectl top pod --use-protocol-buffers --containers' -Arguments $args }
function kinf { Invoke-WriteExecuteCommand -Command 'kubectl cluster-info' -Arguments $args }
function kav { Invoke-WriteExecuteCommand -Command 'kubectl api-versions' -Arguments $args }
function kcv { Invoke-WriteExecuteCommand -Command 'kubectl config view' -Arguments $args }
function kcgctx { Invoke-WriteExecuteCommand -Command 'kubectl config get-contexts' -Arguments $args }
function kcsctxcns { Invoke-WriteExecuteCommand -Command 'kubectl config set-context --current --namespace' -Arguments $args }
function ksys { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system' -Arguments $args }
function ka { Invoke-WriteExecuteCommand -Command 'kubectl apply --recursive -f' -Arguments $args }
function ksysa { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system apply --recursive -f' -Arguments $args }
function kak { Invoke-WriteExecuteCommand -Command 'kubectl apply -k' -Arguments $args }
function kk { Invoke-WriteExecuteCommand -Command 'kubectl kustomize' -Arguments $args }
function krmk { Invoke-WriteExecuteCommand -Command 'kubectl delete -k' -Arguments $args }
function kex { Invoke-WriteExecuteCommand -Command 'kubectl exec -i -t' -Arguments $args }
function kexsh { Invoke-WriteExecuteCommand -Command "kubectl exec -i -t $($args.Where({ $_ -notin $('-WhatIf', '-Quiet') })) -- sh" -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line  }
function kexbash { Invoke-WriteExecuteCommand -Command "kubectl exec -i -t $($args.Where({ $_ -notin $('-WhatIf', '-Quiet') })) -- bash" -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line  }
function kexpwsh { Invoke-WriteExecuteCommand -Command "kubectl exec -i -t $($args.Where({ $_ -notin $('-WhatIf', '-Quiet') })) -- pwsh" -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line  }
function kexpy { Invoke-WriteExecuteCommand -Command "kubectl exec -i -t $($args.Where({ $_ -notin $('-WhatIf', '-Quiet') })) -- python" -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line  }
function kexipy { Invoke-WriteExecuteCommand -Command "kubectl exec -i -t $($args.Where({ $_ -notin $('-WhatIf', '-Quiet') })) -- ipython" -Arguments ($args | Select-String '^-WhatIf$|^-Quiet$').Line  }
function kre { Invoke-WriteExecuteCommand -Command 'kubectl replace' -Arguments $args }
function kre! { Invoke-WriteExecuteCommand -Command 'kubectl replace --force' -Arguments $args }
function kref { Invoke-WriteExecuteCommand -Command 'kubectl replace -f' -Arguments $args }
function kref! { Invoke-WriteExecuteCommand -Command 'kubectl replace --force -f' -Arguments $args }
function ksysex { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system exec -i -t' -Arguments $args }
function klo { Invoke-WriteExecuteCommand -Command 'kubectl logs -f' -Arguments $args }
function ksyslo { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system logs -f' -Arguments $args }
function klop { Invoke-WriteExecuteCommand -Command 'kubectl logs -f -p' -Arguments $args }
function ksyslop { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system logs -f -p' -Arguments $args }
function kp { Invoke-WriteExecuteCommand -Command 'kubectl proxy' -Arguments $args }
function kpf { Invoke-WriteExecuteCommand -Command 'kubectl port-forward' -Arguments $args }
function kg { Invoke-WriteExecuteCommand -Command 'kubectl get' -Arguments $args }
function ksysg { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get' -Arguments $args }
function kd { Invoke-WriteExecuteCommand -Command 'kubectl describe' -Arguments $args }
function ksysd { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe' -Arguments $args }
function krm { Invoke-WriteExecuteCommand -Command 'kubectl delete' -Arguments $args }
function ksysrm { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete' -Arguments $args }
function krun { Invoke-WriteExecuteCommand -Command 'kubectl run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t' -Arguments $args }
function ksysrun { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t' -Arguments $args }
function kgpo { Invoke-WriteExecuteCommand -Command 'kubectl get pods' -Arguments $args }
function ksysgpo { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods' -Arguments $args }
function kdpo { Invoke-WriteExecuteCommand -Command 'kubectl describe pods' -Arguments $args }
function ksysdpo { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe pods' -Arguments $args }
function krmpo { Invoke-WriteExecuteCommand -Command 'kubectl delete pods' -Arguments $args }
function ksysrmpo { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete pods' -Arguments $args }
function kgdep { Invoke-WriteExecuteCommand -Command 'kubectl get deployment' -Arguments $args }
function ksysgdep { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment' -Arguments $args }
function kddep { Invoke-WriteExecuteCommand -Command 'kubectl describe deployment' -Arguments $args }
function ksysddep { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe deployment' -Arguments $args }
function krmdep { Invoke-WriteExecuteCommand -Command 'kubectl delete deployment' -Arguments $args }
function ksysrmdep { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete deployment' -Arguments $args }
function kgsvc { Invoke-WriteExecuteCommand -Command 'kubectl get service' -Arguments $args }
function ksysgsvc { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service' -Arguments $args }
function kdsvc { Invoke-WriteExecuteCommand -Command 'kubectl describe service' -Arguments $args }
function ksysdsvc { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe service' -Arguments $args }
function krmsvc { Invoke-WriteExecuteCommand -Command 'kubectl delete service' -Arguments $args }
function ksysrmsvc { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete service' -Arguments $args }
function kging { Invoke-WriteExecuteCommand -Command 'kubectl get ingress' -Arguments $args }
function ksysging { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress' -Arguments $args }
function kding { Invoke-WriteExecuteCommand -Command 'kubectl describe ingress' -Arguments $args }
function ksysding { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe ingress' -Arguments $args }
function krming { Invoke-WriteExecuteCommand -Command 'kubectl delete ingress' -Arguments $args }
function ksysrming { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete ingress' -Arguments $args }
function kgcm { Invoke-WriteExecuteCommand -Command 'kubectl get configmap' -Arguments $args }
function ksysgcm { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap' -Arguments $args }
function kdcm { Invoke-WriteExecuteCommand -Command 'kubectl describe configmap' -Arguments $args }
function ksysdcm { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe configmap' -Arguments $args }
function krmcm { Invoke-WriteExecuteCommand -Command 'kubectl delete configmap' -Arguments $args }
function ksysrmcm { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete configmap' -Arguments $args }
function kgsec { Invoke-WriteExecuteCommand -Command 'kubectl get secret' -Arguments $args }
function ksysgsec { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret' -Arguments $args }
function kdsec { Invoke-WriteExecuteCommand -Command 'kubectl describe secret' -Arguments $args }
function ksysdsec { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe secret' -Arguments $args }
function krmsec { Invoke-WriteExecuteCommand -Command 'kubectl delete secret' -Arguments $args }
function ksysrmsec { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete secret' -Arguments $args }
function kgno { Invoke-WriteExecuteCommand -Command 'kubectl get nodes' -Arguments $args }
function kdno { Invoke-WriteExecuteCommand -Command 'kubectl describe nodes' -Arguments $args }
function kgns { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces' -Arguments $args }
function kdns { Invoke-WriteExecuteCommand -Command 'kubectl describe namespaces' -Arguments $args }
function krmns { Invoke-WriteExecuteCommand -Command 'kubectl delete namespaces' -Arguments $args }
function kgoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get -o=yaml' -Arguments $args }
function ksysgoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get -o=yaml' -Arguments $args }
function kgpooyaml { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=yaml' -Arguments $args }
function ksysgpooyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods -o=yaml' -Arguments $args }
function kgdepoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=yaml' -Arguments $args }
function ksysgdepoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment -o=yaml' -Arguments $args }
function kgsvcoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=yaml' -Arguments $args }
function ksysgsvcoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service -o=yaml' -Arguments $args }
function kgingoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=yaml' -Arguments $args }
function ksysgingoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress -o=yaml' -Arguments $args }
function kgcmoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=yaml' -Arguments $args }
function ksysgcmoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap -o=yaml' -Arguments $args }
function kgsecoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=yaml' -Arguments $args }
function ksysgsecoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret -o=yaml' -Arguments $args }
function kgnooyaml { Invoke-WriteExecuteCommand -Command 'kubectl get nodes -o=yaml' -Arguments $args }
function kgnsoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces -o=yaml' -Arguments $args }
function kgowide { Invoke-WriteExecuteCommand -Command 'kubectl get -o=wide' -Arguments $args }
function ksysgowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get -o=wide' -Arguments $args }
function kgpoowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=wide' -Arguments $args }
function ksysgpoowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods -o=wide' -Arguments $args }
function kgdepowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=wide' -Arguments $args }
function ksysgdepowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment -o=wide' -Arguments $args }
function kgsvcowide { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=wide' -Arguments $args }
function ksysgsvcowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service -o=wide' -Arguments $args }
function kgingowide { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=wide' -Arguments $args }
function ksysgingowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress -o=wide' -Arguments $args }
function kgcmowide { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=wide' -Arguments $args }
function ksysgcmowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap -o=wide' -Arguments $args }
function kgsecowide { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=wide' -Arguments $args }
function ksysgsecowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret -o=wide' -Arguments $args }
function kgnoowide { Invoke-WriteExecuteCommand -Command 'kubectl get nodes -o=wide' -Arguments $args }
function kgnsowide { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces -o=wide' -Arguments $args }
function kgojson { Invoke-WriteExecuteCommand -Command 'kubectl get -o=json' -Arguments $args }
function ksysgojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get -o=json' -Arguments $args }
function kgpoojson { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=json' -Arguments $args }
function ksysgpoojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods -o=json' -Arguments $args }
function kgdepojson { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=json' -Arguments $args }
function ksysgdepojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment -o=json' -Arguments $args }
function kgsvcojson { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=json' -Arguments $args }
function ksysgsvcojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service -o=json' -Arguments $args }
function kgingojson { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=json' -Arguments $args }
function ksysgingojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress -o=json' -Arguments $args }
function kgcmojson { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=json' -Arguments $args }
function ksysgcmojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap -o=json' -Arguments $args }
function kgsecojson { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=json' -Arguments $args }
function ksysgsecojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret -o=json' -Arguments $args }
function kgnoojson { Invoke-WriteExecuteCommand -Command 'kubectl get nodes -o=json' -Arguments $args }
function kgnsojson { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces -o=json' -Arguments $args }
function kgall { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces' -Arguments $args }
function kdall { Invoke-WriteExecuteCommand -Command 'kubectl describe --all-namespaces' -Arguments $args }
function kgpoall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces' -Arguments $args }
function kdpoall { Invoke-WriteExecuteCommand -Command 'kubectl describe pods --all-namespaces' -Arguments $args }
function kgdepall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces' -Arguments $args }
function kddepall { Invoke-WriteExecuteCommand -Command 'kubectl describe deployment --all-namespaces' -Arguments $args }
function kgsvcall { Invoke-WriteExecuteCommand -Command 'kubectl get service --all-namespaces' -Arguments $args }
function kdsvcall { Invoke-WriteExecuteCommand -Command 'kubectl describe service --all-namespaces' -Arguments $args }
function kgingall { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --all-namespaces' -Arguments $args }
function kdingall { Invoke-WriteExecuteCommand -Command 'kubectl describe ingress --all-namespaces' -Arguments $args }
function kgcmall { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --all-namespaces' -Arguments $args }
function kdcmall { Invoke-WriteExecuteCommand -Command 'kubectl describe configmap --all-namespaces' -Arguments $args }
function kgsecall { Invoke-WriteExecuteCommand -Command 'kubectl get secret --all-namespaces' -Arguments $args }
function kdsecall { Invoke-WriteExecuteCommand -Command 'kubectl describe secret --all-namespaces' -Arguments $args }
function kgnsall { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --all-namespaces' -Arguments $args }
function kdnsall { Invoke-WriteExecuteCommand -Command 'kubectl describe namespaces --all-namespaces' -Arguments $args }
function kgsl { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels' -Arguments $args }
function ksysgsl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --show-labels' -Arguments $args }
function kgposl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels' -Arguments $args }
function ksysgposl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --show-labels' -Arguments $args }
function kgdepsl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels' -Arguments $args }
function ksysgdepsl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --show-labels' -Arguments $args }
function krmall { Invoke-WriteExecuteCommand -Command 'kubectl delete --all' -Arguments $args }
function ksysrmall { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete --all' -Arguments $args }
function krmpoall { Invoke-WriteExecuteCommand -Command 'kubectl delete pods --all' -Arguments $args }
function ksysrmpoall { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete pods --all' -Arguments $args }
function krmdepall { Invoke-WriteExecuteCommand -Command 'kubectl delete deployment --all' -Arguments $args }
function ksysrmdepall { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete deployment --all' -Arguments $args }
function krmsvcall { Invoke-WriteExecuteCommand -Command 'kubectl delete service --all' -Arguments $args }
function ksysrmsvcall { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete service --all' -Arguments $args }
function krmingall { Invoke-WriteExecuteCommand -Command 'kubectl delete ingress --all' -Arguments $args }
function ksysrmingall { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete ingress --all' -Arguments $args }
function krmcmall { Invoke-WriteExecuteCommand -Command 'kubectl delete configmap --all' -Arguments $args }
function ksysrmcmall { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete configmap --all' -Arguments $args }
function krmsecall { Invoke-WriteExecuteCommand -Command 'kubectl delete secret --all' -Arguments $args }
function ksysrmsecall { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete secret --all' -Arguments $args }
function krmnsall { Invoke-WriteExecuteCommand -Command 'kubectl delete namespaces --all' -Arguments $args }
function kgw { Invoke-WriteExecuteCommand -Command 'kubectl get --watch' -Arguments $args }
function ksysgw { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch' -Arguments $args }
function kgpow { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch' -Arguments $args }
function ksysgpow { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch' -Arguments $args }
function kgdepw { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch' -Arguments $args }
function ksysgdepw { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch' -Arguments $args }
function kgsvcw { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch' -Arguments $args }
function ksysgsvcw { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service --watch' -Arguments $args }
function kgingw { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch' -Arguments $args }
function ksysgingw { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress --watch' -Arguments $args }
function kgcmw { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch' -Arguments $args }
function ksysgcmw { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap --watch' -Arguments $args }
function kgsecw { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch' -Arguments $args }
function ksysgsecw { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret --watch' -Arguments $args }
function kgnow { Invoke-WriteExecuteCommand -Command 'kubectl get nodes --watch' -Arguments $args }
function kgnsw { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch' -Arguments $args }
function kgoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get -o=yaml --all-namespaces' -Arguments $args }
function kgpooyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=yaml --all-namespaces' -Arguments $args }
function kgdepoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=yaml --all-namespaces' -Arguments $args }
function kgsvcoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=yaml --all-namespaces' -Arguments $args }
function kgingoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=yaml --all-namespaces' -Arguments $args }
function kgcmoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=yaml --all-namespaces' -Arguments $args }
function kgsecoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=yaml --all-namespaces' -Arguments $args }
function kgnsoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces -o=yaml --all-namespaces' -Arguments $args }
function kgalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces -o=yaml' -Arguments $args }
function kgpoalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces -o=yaml' -Arguments $args }
function kgdepalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces -o=yaml' -Arguments $args }
function kgsvcalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get service --all-namespaces -o=yaml' -Arguments $args }
function kgingalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --all-namespaces -o=yaml' -Arguments $args }
function kgcmalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --all-namespaces -o=yaml' -Arguments $args }
function kgsecalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get secret --all-namespaces -o=yaml' -Arguments $args }
function kgnsalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --all-namespaces -o=yaml' -Arguments $args }
function kgwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=yaml' -Arguments $args }
function ksysgwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch -o=yaml' -Arguments $args }
function kgpowoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=yaml' -Arguments $args }
function ksysgpowoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch -o=yaml' -Arguments $args }
function kgdepwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=yaml' -Arguments $args }
function ksysgdepwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch -o=yaml' -Arguments $args }
function kgsvcwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=yaml' -Arguments $args }
function ksysgsvcwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service --watch -o=yaml' -Arguments $args }
function kgingwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=yaml' -Arguments $args }
function ksysgingwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress --watch -o=yaml' -Arguments $args }
function kgcmwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=yaml' -Arguments $args }
function ksysgcmwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap --watch -o=yaml' -Arguments $args }
function kgsecwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=yaml' -Arguments $args }
function ksysgsecwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret --watch -o=yaml' -Arguments $args }
function kgnowoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get nodes --watch -o=yaml' -Arguments $args }
function kgnswoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch -o=yaml' -Arguments $args }
function kgowideall { Invoke-WriteExecuteCommand -Command 'kubectl get -o=wide --all-namespaces' -Arguments $args }
function kgpoowideall { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=wide --all-namespaces' -Arguments $args }
function kgdepowideall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=wide --all-namespaces' -Arguments $args }
function kgsvcowideall { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=wide --all-namespaces' -Arguments $args }
function kgingowideall { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=wide --all-namespaces' -Arguments $args }
function kgcmowideall { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=wide --all-namespaces' -Arguments $args }
function kgsecowideall { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=wide --all-namespaces' -Arguments $args }
function kgnsowideall { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces -o=wide --all-namespaces' -Arguments $args }
function kgallowide { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces -o=wide' -Arguments $args }
function kgpoallowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces -o=wide' -Arguments $args }
function kgdepallowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces -o=wide' -Arguments $args }
function kgsvcallowide { Invoke-WriteExecuteCommand -Command 'kubectl get service --all-namespaces -o=wide' -Arguments $args }
function kgingallowide { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --all-namespaces -o=wide' -Arguments $args }
function kgcmallowide { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --all-namespaces -o=wide' -Arguments $args }
function kgsecallowide { Invoke-WriteExecuteCommand -Command 'kubectl get secret --all-namespaces -o=wide' -Arguments $args }
function kgnsallowide { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --all-namespaces -o=wide' -Arguments $args }
function kgowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get -o=wide --show-labels' -Arguments $args }
function ksysgowidesl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get -o=wide --show-labels' -Arguments $args }
function kgpoowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=wide --show-labels' -Arguments $args }
function ksysgpoowidesl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods -o=wide --show-labels' -Arguments $args }
function kgdepowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=wide --show-labels' -Arguments $args }
function ksysgdepowidesl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment -o=wide --show-labels' -Arguments $args }
function kgslowide { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels -o=wide' -Arguments $args }
function ksysgslowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --show-labels -o=wide' -Arguments $args }
function kgposlowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels -o=wide' -Arguments $args }
function ksysgposlowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --show-labels -o=wide' -Arguments $args }
function kgdepslowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels -o=wide' -Arguments $args }
function ksysgdepslowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --show-labels -o=wide' -Arguments $args }
function kgwowide { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=wide' -Arguments $args }
function ksysgwowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch -o=wide' -Arguments $args }
function kgpowowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=wide' -Arguments $args }
function ksysgpowowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch -o=wide' -Arguments $args }
function kgdepwowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=wide' -Arguments $args }
function ksysgdepwowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch -o=wide' -Arguments $args }
function kgsvcwowide { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=wide' -Arguments $args }
function ksysgsvcwowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service --watch -o=wide' -Arguments $args }
function kgingwowide { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=wide' -Arguments $args }
function ksysgingwowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress --watch -o=wide' -Arguments $args }
function kgcmwowide { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=wide' -Arguments $args }
function ksysgcmwowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap --watch -o=wide' -Arguments $args }
function kgsecwowide { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=wide' -Arguments $args }
function ksysgsecwowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret --watch -o=wide' -Arguments $args }
function kgnowowide { Invoke-WriteExecuteCommand -Command 'kubectl get nodes --watch -o=wide' -Arguments $args }
function kgnswowide { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch -o=wide' -Arguments $args }
function kgojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get -o=json --all-namespaces' -Arguments $args }
function kgpoojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=json --all-namespaces' -Arguments $args }
function kgdepojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=json --all-namespaces' -Arguments $args }
function kgsvcojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=json --all-namespaces' -Arguments $args }
function kgingojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=json --all-namespaces' -Arguments $args }
function kgcmojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=json --all-namespaces' -Arguments $args }
function kgsecojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=json --all-namespaces' -Arguments $args }
function kgnsojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces -o=json --all-namespaces' -Arguments $args }
function kgallojson { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces -o=json' -Arguments $args }
function kgpoallojson { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces -o=json' -Arguments $args }
function kgdepallojson { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces -o=json' -Arguments $args }
function kgsvcallojson { Invoke-WriteExecuteCommand -Command 'kubectl get service --all-namespaces -o=json' -Arguments $args }
function kgingallojson { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --all-namespaces -o=json' -Arguments $args }
function kgcmallojson { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --all-namespaces -o=json' -Arguments $args }
function kgsecallojson { Invoke-WriteExecuteCommand -Command 'kubectl get secret --all-namespaces -o=json' -Arguments $args }
function kgnsallojson { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --all-namespaces -o=json' -Arguments $args }
function kgwojson { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=json' -Arguments $args }
function ksysgwojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch -o=json' -Arguments $args }
function kgpowojson { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=json' -Arguments $args }
function ksysgpowojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch -o=json' -Arguments $args }
function kgdepwojson { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=json' -Arguments $args }
function ksysgdepwojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch -o=json' -Arguments $args }
function kgsvcwojson { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=json' -Arguments $args }
function ksysgsvcwojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service --watch -o=json' -Arguments $args }
function kgingwojson { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=json' -Arguments $args }
function ksysgingwojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress --watch -o=json' -Arguments $args }
function kgcmwojson { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=json' -Arguments $args }
function ksysgcmwojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap --watch -o=json' -Arguments $args }
function kgsecwojson { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=json' -Arguments $args }
function ksysgsecwojson { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret --watch -o=json' -Arguments $args }
function kgnowojson { Invoke-WriteExecuteCommand -Command 'kubectl get nodes --watch -o=json' -Arguments $args }
function kgnswojson { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch -o=json' -Arguments $args }
function kgallsl { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces --show-labels' -Arguments $args }
function kgpoallsl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces --show-labels' -Arguments $args }
function kgdepallsl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces --show-labels' -Arguments $args }
function kgslall { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --all-namespaces' -Arguments $args }
function kgposlall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --all-namespaces' -Arguments $args }
function kgdepslall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --all-namespaces' -Arguments $args }
function kgallw { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces --watch' -Arguments $args }
function kgpoallw { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces --watch' -Arguments $args }
function kgdepallw { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces --watch' -Arguments $args }
function kgsvcallw { Invoke-WriteExecuteCommand -Command 'kubectl get service --all-namespaces --watch' -Arguments $args }
function kgingallw { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --all-namespaces --watch' -Arguments $args }
function kgcmallw { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --all-namespaces --watch' -Arguments $args }
function kgsecallw { Invoke-WriteExecuteCommand -Command 'kubectl get secret --all-namespaces --watch' -Arguments $args }
function kgnsallw { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --all-namespaces --watch' -Arguments $args }
function kgwall { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --all-namespaces' -Arguments $args }
function kgpowall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --all-namespaces' -Arguments $args }
function kgdepwall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --all-namespaces' -Arguments $args }
function kgsvcwall { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch --all-namespaces' -Arguments $args }
function kgingwall { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch --all-namespaces' -Arguments $args }
function kgcmwall { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch --all-namespaces' -Arguments $args }
function kgsecwall { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch --all-namespaces' -Arguments $args }
function kgnswall { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch --all-namespaces' -Arguments $args }
function kgslw { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --watch' -Arguments $args }
function ksysgslw { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --show-labels --watch' -Arguments $args }
function kgposlw { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --watch' -Arguments $args }
function ksysgposlw { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --show-labels --watch' -Arguments $args }
function kgdepslw { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --watch' -Arguments $args }
function ksysgdepslw { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --show-labels --watch' -Arguments $args }
function kgwsl { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --show-labels' -Arguments $args }
function ksysgwsl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch --show-labels' -Arguments $args }
function kgpowsl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --show-labels' -Arguments $args }
function ksysgpowsl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch --show-labels' -Arguments $args }
function kgdepwsl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --show-labels' -Arguments $args }
function ksysgdepwsl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch --show-labels' -Arguments $args }
function kgallwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces --watch -o=yaml' -Arguments $args }
function kgpoallwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces --watch -o=yaml' -Arguments $args }
function kgdepallwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces --watch -o=yaml' -Arguments $args }
function kgsvcallwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get service --all-namespaces --watch -o=yaml' -Arguments $args }
function kgingallwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --all-namespaces --watch -o=yaml' -Arguments $args }
function kgcmallwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --all-namespaces --watch -o=yaml' -Arguments $args }
function kgsecallwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get secret --all-namespaces --watch -o=yaml' -Arguments $args }
function kgnsallwoyaml { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --all-namespaces --watch -o=yaml' -Arguments $args }
function kgwoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=yaml --all-namespaces' -Arguments $args }
function kgpowoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=yaml --all-namespaces' -Arguments $args }
function kgdepwoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=yaml --all-namespaces' -Arguments $args }
function kgsvcwoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=yaml --all-namespaces' -Arguments $args }
function kgingwoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=yaml --all-namespaces' -Arguments $args }
function kgcmwoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=yaml --all-namespaces' -Arguments $args }
function kgsecwoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=yaml --all-namespaces' -Arguments $args }
function kgnswoyamlall { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch -o=yaml --all-namespaces' -Arguments $args }
function kgwalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --all-namespaces -o=yaml' -Arguments $args }
function kgpowalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --all-namespaces -o=yaml' -Arguments $args }
function kgdepwalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --all-namespaces -o=yaml' -Arguments $args }
function kgsvcwalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch --all-namespaces -o=yaml' -Arguments $args }
function kgingwalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch --all-namespaces -o=yaml' -Arguments $args }
function kgcmwalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch --all-namespaces -o=yaml' -Arguments $args }
function kgsecwalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch --all-namespaces -o=yaml' -Arguments $args }
function kgnswalloyaml { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch --all-namespaces -o=yaml' -Arguments $args }
function kgowideallsl { Invoke-WriteExecuteCommand -Command 'kubectl get -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgpoowideallsl { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgdepowideallsl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgowideslall { Invoke-WriteExecuteCommand -Command 'kubectl get -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgpoowideslall { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgdepowideslall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgallowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgpoallowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgdepallowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgallslowide { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgpoallslowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgdepallslowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgslowideall { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgposlowideall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgdepslowideall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgslallowide { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgposlallowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgdepslallowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgallwowide { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces --watch -o=wide' -Arguments $args }
function kgpoallwowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces --watch -o=wide' -Arguments $args }
function kgdepallwowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces --watch -o=wide' -Arguments $args }
function kgsvcallwowide { Invoke-WriteExecuteCommand -Command 'kubectl get service --all-namespaces --watch -o=wide' -Arguments $args }
function kgingallwowide { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --all-namespaces --watch -o=wide' -Arguments $args }
function kgcmallwowide { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --all-namespaces --watch -o=wide' -Arguments $args }
function kgsecallwowide { Invoke-WriteExecuteCommand -Command 'kubectl get secret --all-namespaces --watch -o=wide' -Arguments $args }
function kgnsallwowide { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --all-namespaces --watch -o=wide' -Arguments $args }
function kgwowideall { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=wide --all-namespaces' -Arguments $args }
function kgpowowideall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=wide --all-namespaces' -Arguments $args }
function kgdepwowideall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=wide --all-namespaces' -Arguments $args }
function kgsvcwowideall { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=wide --all-namespaces' -Arguments $args }
function kgingwowideall { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=wide --all-namespaces' -Arguments $args }
function kgcmwowideall { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=wide --all-namespaces' -Arguments $args }
function kgsecwowideall { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=wide --all-namespaces' -Arguments $args }
function kgnswowideall { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch -o=wide --all-namespaces' -Arguments $args }
function kgwallowide { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --all-namespaces -o=wide' -Arguments $args }
function kgpowallowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --all-namespaces -o=wide' -Arguments $args }
function kgdepwallowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --all-namespaces -o=wide' -Arguments $args }
function kgsvcwallowide { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch --all-namespaces -o=wide' -Arguments $args }
function kgingwallowide { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch --all-namespaces -o=wide' -Arguments $args }
function kgcmwallowide { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch --all-namespaces -o=wide' -Arguments $args }
function kgsecwallowide { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch --all-namespaces -o=wide' -Arguments $args }
function kgnswallowide { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch --all-namespaces -o=wide' -Arguments $args }
function kgslwowide { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --watch -o=wide' -Arguments $args }
function ksysgslwowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --show-labels --watch -o=wide' -Arguments $args }
function kgposlwowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --watch -o=wide' -Arguments $args }
function ksysgposlwowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --show-labels --watch -o=wide' -Arguments $args }
function kgdepslwowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --watch -o=wide' -Arguments $args }
function ksysgdepslwowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide' -Arguments $args }
function kgwowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=wide --show-labels' -Arguments $args }
function ksysgwowidesl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch -o=wide --show-labels' -Arguments $args }
function kgpowowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=wide --show-labels' -Arguments $args }
function ksysgpowowidesl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch -o=wide --show-labels' -Arguments $args }
function kgdepwowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=wide --show-labels' -Arguments $args }
function ksysgdepwowidesl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels' -Arguments $args }
function kgwslowide { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --show-labels -o=wide' -Arguments $args }
function ksysgwslowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch --show-labels -o=wide' -Arguments $args }
function kgpowslowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --show-labels -o=wide' -Arguments $args }
function ksysgpowslowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch --show-labels -o=wide' -Arguments $args }
function kgdepwslowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --show-labels -o=wide' -Arguments $args }
function ksysgdepwslowide { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide' -Arguments $args }
function kgallwojson { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces --watch -o=json' -Arguments $args }
function kgpoallwojson { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces --watch -o=json' -Arguments $args }
function kgdepallwojson { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces --watch -o=json' -Arguments $args }
function kgsvcallwojson { Invoke-WriteExecuteCommand -Command 'kubectl get service --all-namespaces --watch -o=json' -Arguments $args }
function kgingallwojson { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --all-namespaces --watch -o=json' -Arguments $args }
function kgcmallwojson { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --all-namespaces --watch -o=json' -Arguments $args }
function kgsecallwojson { Invoke-WriteExecuteCommand -Command 'kubectl get secret --all-namespaces --watch -o=json' -Arguments $args }
function kgnsallwojson { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --all-namespaces --watch -o=json' -Arguments $args }
function kgwojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=json --all-namespaces' -Arguments $args }
function kgpowojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=json --all-namespaces' -Arguments $args }
function kgdepwojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=json --all-namespaces' -Arguments $args }
function kgsvcwojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=json --all-namespaces' -Arguments $args }
function kgingwojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=json --all-namespaces' -Arguments $args }
function kgcmwojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=json --all-namespaces' -Arguments $args }
function kgsecwojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=json --all-namespaces' -Arguments $args }
function kgnswojsonall { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch -o=json --all-namespaces' -Arguments $args }
function kgwallojson { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --all-namespaces -o=json' -Arguments $args }
function kgpowallojson { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --all-namespaces -o=json' -Arguments $args }
function kgdepwallojson { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --all-namespaces -o=json' -Arguments $args }
function kgsvcwallojson { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch --all-namespaces -o=json' -Arguments $args }
function kgingwallojson { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch --all-namespaces -o=json' -Arguments $args }
function kgcmwallojson { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch --all-namespaces -o=json' -Arguments $args }
function kgsecwallojson { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch --all-namespaces -o=json' -Arguments $args }
function kgnswallojson { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch --all-namespaces -o=json' -Arguments $args }
function kgallslw { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces --show-labels --watch' -Arguments $args }
function kgpoallslw { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces --show-labels --watch' -Arguments $args }
function kgdepallslw { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces --show-labels --watch' -Arguments $args }
function kgallwsl { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces --watch --show-labels' -Arguments $args }
function kgpoallwsl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces --watch --show-labels' -Arguments $args }
function kgdepallwsl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces --watch --show-labels' -Arguments $args }
function kgslallw { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --all-namespaces --watch' -Arguments $args }
function kgposlallw { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --all-namespaces --watch' -Arguments $args }
function kgdepslallw { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --all-namespaces --watch' -Arguments $args }
function kgslwall { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --watch --all-namespaces' -Arguments $args }
function kgposlwall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --watch --all-namespaces' -Arguments $args }
function kgdepslwall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --watch --all-namespaces' -Arguments $args }
function kgwallsl { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --all-namespaces --show-labels' -Arguments $args }
function kgpowallsl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --all-namespaces --show-labels' -Arguments $args }
function kgdepwallsl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --all-namespaces --show-labels' -Arguments $args }
function kgwslall { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --show-labels --all-namespaces' -Arguments $args }
function kgpowslall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --show-labels --all-namespaces' -Arguments $args }
function kgdepwslall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --show-labels --all-namespaces' -Arguments $args }
function kgallslwowide { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces --show-labels --watch -o=wide' -Arguments $args }
function kgpoallslwowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces --show-labels --watch -o=wide' -Arguments $args }
function kgdepallslwowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces --show-labels --watch -o=wide' -Arguments $args }
function kgallwowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces --watch -o=wide --show-labels' -Arguments $args }
function kgpoallwowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces --watch -o=wide --show-labels' -Arguments $args }
function kgdepallwowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces --watch -o=wide --show-labels' -Arguments $args }
function kgallwslowide { Invoke-WriteExecuteCommand -Command 'kubectl get --all-namespaces --watch --show-labels -o=wide' -Arguments $args }
function kgpoallwslowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --all-namespaces --watch --show-labels -o=wide' -Arguments $args }
function kgdepallwslowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --all-namespaces --watch --show-labels -o=wide' -Arguments $args }
function kgslallwowide { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --all-namespaces --watch -o=wide' -Arguments $args }
function kgposlallwowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --all-namespaces --watch -o=wide' -Arguments $args }
function kgdepslallwowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --all-namespaces --watch -o=wide' -Arguments $args }
function kgslwowideall { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --watch -o=wide --all-namespaces' -Arguments $args }
function kgposlwowideall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --watch -o=wide --all-namespaces' -Arguments $args }
function kgdepslwowideall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --watch -o=wide --all-namespaces' -Arguments $args }
function kgslwallowide { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --watch --all-namespaces -o=wide' -Arguments $args }
function kgposlwallowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --watch --all-namespaces -o=wide' -Arguments $args }
function kgdepslwallowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --watch --all-namespaces -o=wide' -Arguments $args }
function kgwowideallsl { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgpowowideallsl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgdepwowideallsl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=wide --all-namespaces --show-labels' -Arguments $args }
function kgwowideslall { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgpowowideslall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgdepwowideslall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=wide --show-labels --all-namespaces' -Arguments $args }
function kgwallowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgpowallowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgdepwallowidesl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --all-namespaces -o=wide --show-labels' -Arguments $args }
function kgwallslowide { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgpowallslowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgdepwallslowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --all-namespaces --show-labels -o=wide' -Arguments $args }
function kgwslowideall { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgpowslowideall { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgdepwslowideall { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --show-labels -o=wide --all-namespaces' -Arguments $args }
function kgwslallowide { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgpowslallowide { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgdepwslallowide { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --show-labels --all-namespaces -o=wide' -Arguments $args }
function kgf { Invoke-WriteExecuteCommand -Command 'kubectl get --recursive -f' -Arguments $args }
function kdf { Invoke-WriteExecuteCommand -Command 'kubectl describe --recursive -f' -Arguments $args }
function krmf { Invoke-WriteExecuteCommand -Command 'kubectl delete --recursive -f' -Arguments $args }
function kgoyamlf { Invoke-WriteExecuteCommand -Command 'kubectl get -o=yaml --recursive -f' -Arguments $args }
function kgowidef { Invoke-WriteExecuteCommand -Command 'kubectl get -o=wide --recursive -f' -Arguments $args }
function kgojsonf { Invoke-WriteExecuteCommand -Command 'kubectl get -o=json --recursive -f' -Arguments $args }
function kgslf { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --recursive -f' -Arguments $args }
function kgwf { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --recursive -f' -Arguments $args }
function kgwoyamlf { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=yaml --recursive -f' -Arguments $args }
function kgowideslf { Invoke-WriteExecuteCommand -Command 'kubectl get -o=wide --show-labels --recursive -f' -Arguments $args }
function kgslowidef { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels -o=wide --recursive -f' -Arguments $args }
function kgwowidef { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=wide --recursive -f' -Arguments $args }
function kgwojsonf { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=json --recursive -f' -Arguments $args }
function kgslwf { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --watch --recursive -f' -Arguments $args }
function kgwslf { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --show-labels --recursive -f' -Arguments $args }
function kgslwowidef { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --watch -o=wide --recursive -f' -Arguments $args }
function kgwowideslf { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=wide --show-labels --recursive -f' -Arguments $args }
function kgwslowidef { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --show-labels -o=wide --recursive -f' -Arguments $args }
function kgl { Invoke-WriteExecuteCommand -Command 'kubectl get -l' -Arguments $args }
function ksysgl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get -l' -Arguments $args }
function kdl { Invoke-WriteExecuteCommand -Command 'kubectl describe -l' -Arguments $args }
function ksysdl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe -l' -Arguments $args }
function krml { Invoke-WriteExecuteCommand -Command 'kubectl delete -l' -Arguments $args }
function ksysrml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete -l' -Arguments $args }
function kgpol { Invoke-WriteExecuteCommand -Command 'kubectl get pods -l' -Arguments $args }
function ksysgpol { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods -l' -Arguments $args }
function kdpol { Invoke-WriteExecuteCommand -Command 'kubectl describe pods -l' -Arguments $args }
function ksysdpol { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe pods -l' -Arguments $args }
function krmpol { Invoke-WriteExecuteCommand -Command 'kubectl delete pods -l' -Arguments $args }
function ksysrmpol { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete pods -l' -Arguments $args }
function kgdepl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -l' -Arguments $args }
function ksysgdepl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment -l' -Arguments $args }
function kddepl { Invoke-WriteExecuteCommand -Command 'kubectl describe deployment -l' -Arguments $args }
function ksysddepl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe deployment -l' -Arguments $args }
function krmdepl { Invoke-WriteExecuteCommand -Command 'kubectl delete deployment -l' -Arguments $args }
function ksysrmdepl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete deployment -l' -Arguments $args }
function kgsvcl { Invoke-WriteExecuteCommand -Command 'kubectl get service -l' -Arguments $args }
function ksysgsvcl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service -l' -Arguments $args }
function kdsvcl { Invoke-WriteExecuteCommand -Command 'kubectl describe service -l' -Arguments $args }
function ksysdsvcl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe service -l' -Arguments $args }
function krmsvcl { Invoke-WriteExecuteCommand -Command 'kubectl delete service -l' -Arguments $args }
function ksysrmsvcl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete service -l' -Arguments $args }
function kgingl { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -l' -Arguments $args }
function ksysgingl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress -l' -Arguments $args }
function kdingl { Invoke-WriteExecuteCommand -Command 'kubectl describe ingress -l' -Arguments $args }
function ksysdingl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe ingress -l' -Arguments $args }
function krmingl { Invoke-WriteExecuteCommand -Command 'kubectl delete ingress -l' -Arguments $args }
function ksysrmingl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete ingress -l' -Arguments $args }
function kgcml { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -l' -Arguments $args }
function ksysgcml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap -l' -Arguments $args }
function kdcml { Invoke-WriteExecuteCommand -Command 'kubectl describe configmap -l' -Arguments $args }
function ksysdcml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe configmap -l' -Arguments $args }
function krmcml { Invoke-WriteExecuteCommand -Command 'kubectl delete configmap -l' -Arguments $args }
function ksysrmcml { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete configmap -l' -Arguments $args }
function kgsecl { Invoke-WriteExecuteCommand -Command 'kubectl get secret -l' -Arguments $args }
function ksysgsecl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret -l' -Arguments $args }
function kdsecl { Invoke-WriteExecuteCommand -Command 'kubectl describe secret -l' -Arguments $args }
function ksysdsecl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system describe secret -l' -Arguments $args }
function krmsecl { Invoke-WriteExecuteCommand -Command 'kubectl delete secret -l' -Arguments $args }
function ksysrmsecl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system delete secret -l' -Arguments $args }
function kgnol { Invoke-WriteExecuteCommand -Command 'kubectl get nodes -l' -Arguments $args }
function kdnol { Invoke-WriteExecuteCommand -Command 'kubectl describe nodes -l' -Arguments $args }
function kgnsl { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces -l' -Arguments $args }
function kdnsl { Invoke-WriteExecuteCommand -Command 'kubectl describe namespaces -l' -Arguments $args }
function krmnsl { Invoke-WriteExecuteCommand -Command 'kubectl delete namespaces -l' -Arguments $args }
function kgoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get -o=yaml -l' -Arguments $args }
function ksysgoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get -o=yaml -l' -Arguments $args }
function kgpooyamll { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=yaml -l' -Arguments $args }
function ksysgpooyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods -o=yaml -l' -Arguments $args }
function kgdepoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=yaml -l' -Arguments $args }
function ksysgdepoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment -o=yaml -l' -Arguments $args }
function kgsvcoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=yaml -l' -Arguments $args }
function ksysgsvcoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service -o=yaml -l' -Arguments $args }
function kgingoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=yaml -l' -Arguments $args }
function ksysgingoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress -o=yaml -l' -Arguments $args }
function kgcmoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=yaml -l' -Arguments $args }
function ksysgcmoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap -o=yaml -l' -Arguments $args }
function kgsecoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=yaml -l' -Arguments $args }
function ksysgsecoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret -o=yaml -l' -Arguments $args }
function kgnooyamll { Invoke-WriteExecuteCommand -Command 'kubectl get nodes -o=yaml -l' -Arguments $args }
function kgnsoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces -o=yaml -l' -Arguments $args }
function kgowidel { Invoke-WriteExecuteCommand -Command 'kubectl get -o=wide -l' -Arguments $args }
function ksysgowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get -o=wide -l' -Arguments $args }
function kgpoowidel { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=wide -l' -Arguments $args }
function ksysgpoowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods -o=wide -l' -Arguments $args }
function kgdepowidel { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=wide -l' -Arguments $args }
function ksysgdepowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment -o=wide -l' -Arguments $args }
function kgsvcowidel { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=wide -l' -Arguments $args }
function ksysgsvcowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service -o=wide -l' -Arguments $args }
function kgingowidel { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=wide -l' -Arguments $args }
function ksysgingowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress -o=wide -l' -Arguments $args }
function kgcmowidel { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=wide -l' -Arguments $args }
function ksysgcmowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap -o=wide -l' -Arguments $args }
function kgsecowidel { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=wide -l' -Arguments $args }
function ksysgsecowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret -o=wide -l' -Arguments $args }
function kgnoowidel { Invoke-WriteExecuteCommand -Command 'kubectl get nodes -o=wide -l' -Arguments $args }
function kgnsowidel { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces -o=wide -l' -Arguments $args }
function kgojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get -o=json -l' -Arguments $args }
function ksysgojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get -o=json -l' -Arguments $args }
function kgpoojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=json -l' -Arguments $args }
function ksysgpoojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods -o=json -l' -Arguments $args }
function kgdepojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=json -l' -Arguments $args }
function ksysgdepojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment -o=json -l' -Arguments $args }
function kgsvcojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=json -l' -Arguments $args }
function ksysgsvcojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service -o=json -l' -Arguments $args }
function kgingojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=json -l' -Arguments $args }
function ksysgingojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress -o=json -l' -Arguments $args }
function kgcmojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=json -l' -Arguments $args }
function ksysgcmojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap -o=json -l' -Arguments $args }
function kgsecojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=json -l' -Arguments $args }
function ksysgsecojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret -o=json -l' -Arguments $args }
function kgnoojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get nodes -o=json -l' -Arguments $args }
function kgnsojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces -o=json -l' -Arguments $args }
function kgsll { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels -l' -Arguments $args }
function ksysgsll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --show-labels -l' -Arguments $args }
function kgposll { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels -l' -Arguments $args }
function ksysgposll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --show-labels -l' -Arguments $args }
function kgdepsll { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels -l' -Arguments $args }
function ksysgdepsll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --show-labels -l' -Arguments $args }
function kgwl { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -l' -Arguments $args }
function ksysgwl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch -l' -Arguments $args }
function kgpowl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -l' -Arguments $args }
function ksysgpowl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch -l' -Arguments $args }
function kgdepwl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -l' -Arguments $args }
function ksysgdepwl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch -l' -Arguments $args }
function kgsvcwl { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -l' -Arguments $args }
function ksysgsvcwl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service --watch -l' -Arguments $args }
function kgingwl { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -l' -Arguments $args }
function ksysgingwl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress --watch -l' -Arguments $args }
function kgcmwl { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -l' -Arguments $args }
function ksysgcmwl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap --watch -l' -Arguments $args }
function kgsecwl { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -l' -Arguments $args }
function ksysgsecwl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret --watch -l' -Arguments $args }
function kgnowl { Invoke-WriteExecuteCommand -Command 'kubectl get nodes --watch -l' -Arguments $args }
function kgnswl { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch -l' -Arguments $args }
function kgwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=yaml -l' -Arguments $args }
function ksysgwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch -o=yaml -l' -Arguments $args }
function kgpowoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=yaml -l' -Arguments $args }
function ksysgpowoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch -o=yaml -l' -Arguments $args }
function kgdepwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=yaml -l' -Arguments $args }
function ksysgdepwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch -o=yaml -l' -Arguments $args }
function kgsvcwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=yaml -l' -Arguments $args }
function ksysgsvcwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service --watch -o=yaml -l' -Arguments $args }
function kgingwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=yaml -l' -Arguments $args }
function ksysgingwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress --watch -o=yaml -l' -Arguments $args }
function kgcmwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=yaml -l' -Arguments $args }
function ksysgcmwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap --watch -o=yaml -l' -Arguments $args }
function kgsecwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=yaml -l' -Arguments $args }
function ksysgsecwoyamll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret --watch -o=yaml -l' -Arguments $args }
function kgnowoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get nodes --watch -o=yaml -l' -Arguments $args }
function kgnswoyamll { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch -o=yaml -l' -Arguments $args }
function kgowidesll { Invoke-WriteExecuteCommand -Command 'kubectl get -o=wide --show-labels -l' -Arguments $args }
function ksysgowidesll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get -o=wide --show-labels -l' -Arguments $args }
function kgpoowidesll { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=wide --show-labels -l' -Arguments $args }
function ksysgpoowidesll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods -o=wide --show-labels -l' -Arguments $args }
function kgdepowidesll { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=wide --show-labels -l' -Arguments $args }
function ksysgdepowidesll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment -o=wide --show-labels -l' -Arguments $args }
function kgslowidel { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels -o=wide -l' -Arguments $args }
function ksysgslowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --show-labels -o=wide -l' -Arguments $args }
function kgposlowidel { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels -o=wide -l' -Arguments $args }
function ksysgposlowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --show-labels -o=wide -l' -Arguments $args }
function kgdepslowidel { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels -o=wide -l' -Arguments $args }
function ksysgdepslowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --show-labels -o=wide -l' -Arguments $args }
function kgwowidel { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=wide -l' -Arguments $args }
function ksysgwowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch -o=wide -l' -Arguments $args }
function kgpowowidel { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=wide -l' -Arguments $args }
function ksysgpowowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch -o=wide -l' -Arguments $args }
function kgdepwowidel { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=wide -l' -Arguments $args }
function ksysgdepwowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch -o=wide -l' -Arguments $args }
function kgsvcwowidel { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=wide -l' -Arguments $args }
function ksysgsvcwowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service --watch -o=wide -l' -Arguments $args }
function kgingwowidel { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=wide -l' -Arguments $args }
function ksysgingwowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress --watch -o=wide -l' -Arguments $args }
function kgcmwowidel { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=wide -l' -Arguments $args }
function ksysgcmwowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap --watch -o=wide -l' -Arguments $args }
function kgsecwowidel { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=wide -l' -Arguments $args }
function ksysgsecwowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret --watch -o=wide -l' -Arguments $args }
function kgnowowidel { Invoke-WriteExecuteCommand -Command 'kubectl get nodes --watch -o=wide -l' -Arguments $args }
function kgnswowidel { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch -o=wide -l' -Arguments $args }
function kgwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=json -l' -Arguments $args }
function ksysgwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch -o=json -l' -Arguments $args }
function kgpowojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=json -l' -Arguments $args }
function ksysgpowojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch -o=json -l' -Arguments $args }
function kgdepwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=json -l' -Arguments $args }
function ksysgdepwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch -o=json -l' -Arguments $args }
function kgsvcwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=json -l' -Arguments $args }
function ksysgsvcwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get service --watch -o=json -l' -Arguments $args }
function kgingwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=json -l' -Arguments $args }
function ksysgingwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get ingress --watch -o=json -l' -Arguments $args }
function kgcmwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=json -l' -Arguments $args }
function ksysgcmwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get configmap --watch -o=json -l' -Arguments $args }
function kgsecwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=json -l' -Arguments $args }
function ksysgsecwojsonl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get secret --watch -o=json -l' -Arguments $args }
function kgnowojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get nodes --watch -o=json -l' -Arguments $args }
function kgnswojsonl { Invoke-WriteExecuteCommand -Command 'kubectl get namespaces --watch -o=json -l' -Arguments $args }
function kgslwl { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --watch -l' -Arguments $args }
function ksysgslwl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --show-labels --watch -l' -Arguments $args }
function kgposlwl { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --watch -l' -Arguments $args }
function ksysgposlwl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --show-labels --watch -l' -Arguments $args }
function kgdepslwl { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --watch -l' -Arguments $args }
function ksysgdepslwl { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --show-labels --watch -l' -Arguments $args }
function kgwsll { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --show-labels -l' -Arguments $args }
function ksysgwsll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch --show-labels -l' -Arguments $args }
function kgpowsll { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --show-labels -l' -Arguments $args }
function ksysgpowsll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch --show-labels -l' -Arguments $args }
function kgdepwsll { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --show-labels -l' -Arguments $args }
function ksysgdepwsll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch --show-labels -l' -Arguments $args }
function kgslwowidel { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --watch -o=wide -l' -Arguments $args }
function ksysgslwowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --show-labels --watch -o=wide -l' -Arguments $args }
function kgposlwowidel { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --watch -o=wide -l' -Arguments $args }
function ksysgposlwowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --show-labels --watch -o=wide -l' -Arguments $args }
function kgdepslwowidel { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --watch -o=wide -l' -Arguments $args }
function ksysgdepslwowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide -l' -Arguments $args }
function kgwowidesll { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=wide --show-labels -l' -Arguments $args }
function ksysgwowidesll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch -o=wide --show-labels -l' -Arguments $args }
function kgpowowidesll { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=wide --show-labels -l' -Arguments $args }
function ksysgpowowidesll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch -o=wide --show-labels -l' -Arguments $args }
function kgdepwowidesll { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=wide --show-labels -l' -Arguments $args }
function ksysgdepwowidesll { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels -l' -Arguments $args }
function kgwslowidel { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --show-labels -o=wide -l' -Arguments $args }
function ksysgwslowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get --watch --show-labels -o=wide -l' -Arguments $args }
function kgpowslowidel { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --show-labels -o=wide -l' -Arguments $args }
function ksysgpowslowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get pods --watch --show-labels -o=wide -l' -Arguments $args }
function kgdepwslowidel { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --show-labels -o=wide -l' -Arguments $args }
function ksysgdepwslowidel { Invoke-WriteExecuteCommand -Command 'kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide -l' -Arguments $args }
function kexn { Invoke-WriteExecuteCommand -Command 'kubectl exec -i -t --namespace' -Arguments $args }
function klon { Invoke-WriteExecuteCommand -Command 'kubectl logs -f --namespace' -Arguments $args }
function kpfn { Invoke-WriteExecuteCommand -Command 'kubectl port-forward --namespace' -Arguments $args }
function kgn { Invoke-WriteExecuteCommand -Command 'kubectl get --namespace' -Arguments $args }
function kdn { Invoke-WriteExecuteCommand -Command 'kubectl describe --namespace' -Arguments $args }
function krmn { Invoke-WriteExecuteCommand -Command 'kubectl delete --namespace' -Arguments $args }
function kgpon { Invoke-WriteExecuteCommand -Command 'kubectl get pods --namespace' -Arguments $args }
function kdpon { Invoke-WriteExecuteCommand -Command 'kubectl describe pods --namespace' -Arguments $args }
function krmpon { Invoke-WriteExecuteCommand -Command 'kubectl delete pods --namespace' -Arguments $args }
function kgdepn { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --namespace' -Arguments $args }
function kddepn { Invoke-WriteExecuteCommand -Command 'kubectl describe deployment --namespace' -Arguments $args }
function krmdepn { Invoke-WriteExecuteCommand -Command 'kubectl delete deployment --namespace' -Arguments $args }
function kgsvcn { Invoke-WriteExecuteCommand -Command 'kubectl get service --namespace' -Arguments $args }
function kdsvcn { Invoke-WriteExecuteCommand -Command 'kubectl describe service --namespace' -Arguments $args }
function krmsvcn { Invoke-WriteExecuteCommand -Command 'kubectl delete service --namespace' -Arguments $args }
function kgingn { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --namespace' -Arguments $args }
function kdingn { Invoke-WriteExecuteCommand -Command 'kubectl describe ingress --namespace' -Arguments $args }
function krmingn { Invoke-WriteExecuteCommand -Command 'kubectl delete ingress --namespace' -Arguments $args }
function kgcmn { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --namespace' -Arguments $args }
function kdcmn { Invoke-WriteExecuteCommand -Command 'kubectl describe configmap --namespace' -Arguments $args }
function krmcmn { Invoke-WriteExecuteCommand -Command 'kubectl delete configmap --namespace' -Arguments $args }
function kgsecn { Invoke-WriteExecuteCommand -Command 'kubectl get secret --namespace' -Arguments $args }
function kdsecn { Invoke-WriteExecuteCommand -Command 'kubectl describe secret --namespace' -Arguments $args }
function krmsecn { Invoke-WriteExecuteCommand -Command 'kubectl delete secret --namespace' -Arguments $args }
function kgoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get -o=yaml --namespace' -Arguments $args }
function kgpooyamln { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=yaml --namespace' -Arguments $args }
function kgdepoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=yaml --namespace' -Arguments $args }
function kgsvcoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=yaml --namespace' -Arguments $args }
function kgingoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=yaml --namespace' -Arguments $args }
function kgcmoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=yaml --namespace' -Arguments $args }
function kgsecoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=yaml --namespace' -Arguments $args }
function kgowiden { Invoke-WriteExecuteCommand -Command 'kubectl get -o=wide --namespace' -Arguments $args }
function kgpoowiden { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=wide --namespace' -Arguments $args }
function kgdepowiden { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=wide --namespace' -Arguments $args }
function kgsvcowiden { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=wide --namespace' -Arguments $args }
function kgingowiden { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=wide --namespace' -Arguments $args }
function kgcmowiden { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=wide --namespace' -Arguments $args }
function kgsecowiden { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=wide --namespace' -Arguments $args }
function kgojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get -o=json --namespace' -Arguments $args }
function kgpoojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=json --namespace' -Arguments $args }
function kgdepojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=json --namespace' -Arguments $args }
function kgsvcojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get service -o=json --namespace' -Arguments $args }
function kgingojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get ingress -o=json --namespace' -Arguments $args }
function kgcmojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get configmap -o=json --namespace' -Arguments $args }
function kgsecojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get secret -o=json --namespace' -Arguments $args }
function kgsln { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --namespace' -Arguments $args }
function kgposln { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --namespace' -Arguments $args }
function kgdepsln { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --namespace' -Arguments $args }
function kgwn { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --namespace' -Arguments $args }
function kgpown { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --namespace' -Arguments $args }
function kgdepwn { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --namespace' -Arguments $args }
function kgsvcwn { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch --namespace' -Arguments $args }
function kgingwn { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch --namespace' -Arguments $args }
function kgcmwn { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch --namespace' -Arguments $args }
function kgsecwn { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch --namespace' -Arguments $args }
function kgwoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=yaml --namespace' -Arguments $args }
function kgpowoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=yaml --namespace' -Arguments $args }
function kgdepwoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=yaml --namespace' -Arguments $args }
function kgsvcwoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=yaml --namespace' -Arguments $args }
function kgingwoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=yaml --namespace' -Arguments $args }
function kgcmwoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=yaml --namespace' -Arguments $args }
function kgsecwoyamln { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=yaml --namespace' -Arguments $args }
function kgowidesln { Invoke-WriteExecuteCommand -Command 'kubectl get -o=wide --show-labels --namespace' -Arguments $args }
function kgpoowidesln { Invoke-WriteExecuteCommand -Command 'kubectl get pods -o=wide --show-labels --namespace' -Arguments $args }
function kgdepowidesln { Invoke-WriteExecuteCommand -Command 'kubectl get deployment -o=wide --show-labels --namespace' -Arguments $args }
function kgslowiden { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels -o=wide --namespace' -Arguments $args }
function kgposlowiden { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels -o=wide --namespace' -Arguments $args }
function kgdepslowiden { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels -o=wide --namespace' -Arguments $args }
function kgwowiden { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=wide --namespace' -Arguments $args }
function kgpowowiden { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=wide --namespace' -Arguments $args }
function kgdepwowiden { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=wide --namespace' -Arguments $args }
function kgsvcwowiden { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=wide --namespace' -Arguments $args }
function kgingwowiden { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=wide --namespace' -Arguments $args }
function kgcmwowiden { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=wide --namespace' -Arguments $args }
function kgsecwowiden { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=wide --namespace' -Arguments $args }
function kgwojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=json --namespace' -Arguments $args }
function kgpowojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=json --namespace' -Arguments $args }
function kgdepwojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=json --namespace' -Arguments $args }
function kgsvcwojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get service --watch -o=json --namespace' -Arguments $args }
function kgingwojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get ingress --watch -o=json --namespace' -Arguments $args }
function kgcmwojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get configmap --watch -o=json --namespace' -Arguments $args }
function kgsecwojsonn { Invoke-WriteExecuteCommand -Command 'kubectl get secret --watch -o=json --namespace' -Arguments $args }
function kgslwn { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --watch --namespace' -Arguments $args }
function kgposlwn { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --watch --namespace' -Arguments $args }
function kgdepslwn { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --watch --namespace' -Arguments $args }
function kgwsln { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --show-labels --namespace' -Arguments $args }
function kgpowsln { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --show-labels --namespace' -Arguments $args }
function kgdepwsln { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --show-labels --namespace' -Arguments $args }
function kgslwowiden { Invoke-WriteExecuteCommand -Command 'kubectl get --show-labels --watch -o=wide --namespace' -Arguments $args }
function kgposlwowiden { Invoke-WriteExecuteCommand -Command 'kubectl get pods --show-labels --watch -o=wide --namespace' -Arguments $args }
function kgdepslwowiden { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --show-labels --watch -o=wide --namespace' -Arguments $args }
function kgwowidesln { Invoke-WriteExecuteCommand -Command 'kubectl get --watch -o=wide --show-labels --namespace' -Arguments $args }
function kgpowowidesln { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch -o=wide --show-labels --namespace' -Arguments $args }
function kgdepwowidesln { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch -o=wide --show-labels --namespace' -Arguments $args }
function kgwslowiden { Invoke-WriteExecuteCommand -Command 'kubectl get --watch --show-labels -o=wide --namespace' -Arguments $args }
function kgpowslowiden { Invoke-WriteExecuteCommand -Command 'kubectl get pods --watch --show-labels -o=wide --namespace' -Arguments $args }
function kgdepwslowiden { Invoke-WriteExecuteCommand -Command 'kubectl get deployment --watch --show-labels -o=wide --namespace' -Arguments $args }
