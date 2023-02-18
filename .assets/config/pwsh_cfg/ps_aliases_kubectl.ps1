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

function ktop { Write-Host "kubectl top pod --use-protocol-buffers $args" -ForegroundColor Magenta; k top pod --use-protocol-buffers @args }
function ktopcntr { Write-Host "kubectl top pod --use-protocol-buffers --containers $args" -ForegroundColor Magenta; k top pod --use-protocol-buffers --containers @args }
function kinf { Write-Host "kubectl cluster-info $args" -ForegroundColor Magenta; k cluster-info @args }
function kav { Write-Host "kubectl api-versions $args" -ForegroundColor Magenta; k api-versions @args }
function kcv { Write-Host "kubectl config view $args" -ForegroundColor Magenta; k config view @args }
function kcgctx { Write-Host "kubectl config get-contexts $args" -ForegroundColor Magenta; (k config get-contexts @args) -replace ' +', ',' | ConvertFrom-Csv -Delimiter ',' | Select-Object -ExcludeProperty AUTHINFO }
function kcsctxcns { Write-Host "kubectl config set-context --current --namespace $args" -ForegroundColor Magenta; k config set-context --current --namespace @args }
function ksys { Write-Host "kubectl --namespace=kube-system $args" -ForegroundColor Magenta; k --namespace=kube-system @args }
function ka { Write-Host "kubectl apply --recursive -f $args" -ForegroundColor Magenta; k apply --recursive -f @args }
function ksysa { Write-Host "kubectl --namespace=kube-system apply --recursive -f $args" -ForegroundColor Magenta; k --namespace=kube-system apply --recursive -f @args }
function kak { Write-Host "kubectl apply -k $args" -ForegroundColor Magenta; k apply -k @args }
function kk { Write-Host "kubectl kustomize $args" -ForegroundColor Magenta; k kustomize @args }
function krmk { Write-Host "kubectl delete -k $args" -ForegroundColor Magenta; k delete -k @args }
function kex { Write-Host "kubectl exec -i -t $args" -ForegroundColor Magenta; k exec -i -t @args }
function kexsh { Write-Host "kubectl exec -i -t $args -- sh" -ForegroundColor Magenta; k exec -i -t @args -- sh }
function kexbash { Write-Host "kubectl exec -i -t $args -- bash" -ForegroundColor Magenta; k exec -i -t @args -- bash }
function kexpwsh { Write-Host "kubectl exec -i -t $args -- pwsh" -ForegroundColor Magenta; k exec -i -t @args -- pwsh }
function kexpy { Write-Host "kubectl exec -i -t $args -- python" -ForegroundColor Magenta; k exec -i -t @args -- python }
function kexipy { Write-Host "kubectl exec -i -t $args -- ipython" -ForegroundColor Magenta; k exec -i -t @args -- ipython }
function kre { Write-Host "kubectl replace $args" -ForegroundColor Magenta; k replace @args }
function kre! { Write-Host "kubectl replace --force $args" -ForegroundColor Magenta; k replace --force @args }
function kref { Write-Host "kubectl replace -f $args" -ForegroundColor Magenta; k replace -f @args }
function kref! { Write-Host "kubectl replace --force -f $args" -ForegroundColor Magenta; k replace --force -f @args }
function ksysex { Write-Host "kubectl --namespace=kube-system exec -i -t $args" -ForegroundColor Magenta; k --namespace=kube-system exec -i -t @args }
function klo { Write-Host "kubectl logs -f $args" -ForegroundColor Magenta; k logs -f @args }
function ksyslo { Write-Host "kubectl --namespace=kube-system logs -f $args" -ForegroundColor Magenta; k --namespace=kube-system logs -f @args }
function klop { Write-Host "kubectl logs -f -p $args" -ForegroundColor Magenta; k logs -f -p @args }
function ksyslop { Write-Host "kubectl --namespace=kube-system logs -f -p $args" -ForegroundColor Magenta; k --namespace=kube-system logs -f -p @args }
function kp { Write-Host "kubectl proxy $args" -ForegroundColor Magenta; k proxy @args }
function kpf { Write-Host "kubectl port-forward $args" -ForegroundColor Magenta; k port-forward @args }
function kg { Write-Host "kubectl get $args" -ForegroundColor Magenta; k get @args }
function ksysg { Write-Host "kubectl --namespace=kube-system get $args" -ForegroundColor Magenta; k --namespace=kube-system get @args }
function kd { Write-Host "kubectl describe $args" -ForegroundColor Magenta; k describe @args }
function ksysd { Write-Host "kubectl --namespace=kube-system describe $args" -ForegroundColor Magenta; k --namespace=kube-system describe @args }
function krm { Write-Host "kubectl delete $args" -ForegroundColor Magenta; k delete @args }
function ksysrm { Write-Host "kubectl --namespace=kube-system delete $args" -ForegroundColor Magenta; k --namespace=kube-system delete @args }
function krun { Write-Host "kubectl run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t $args" -ForegroundColor Magenta; k run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t @args }
function ksysrun { Write-Host "kubectl --namespace=kube-system run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t $args" -ForegroundColor Magenta; k --namespace=kube-system run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t @args }
function kgpo { Write-Host "kubectl get pods $args" -ForegroundColor Magenta; k get pods @args }
function ksysgpo { Write-Host "kubectl --namespace=kube-system get pods $args" -ForegroundColor Magenta; k --namespace=kube-system get pods @args }
function kdpo { Write-Host "kubectl describe pods $args" -ForegroundColor Magenta; k describe pods @args }
function ksysdpo { Write-Host "kubectl --namespace=kube-system describe pods $args" -ForegroundColor Magenta; k --namespace=kube-system describe pods @args }
function krmpo { Write-Host "kubectl delete pods $args" -ForegroundColor Magenta; k delete pods @args }
function ksysrmpo { Write-Host "kubectl --namespace=kube-system delete pods $args" -ForegroundColor Magenta; k --namespace=kube-system delete pods @args }
function kgdep { Write-Host "kubectl get deployment $args" -ForegroundColor Magenta; k get deployment @args }
function ksysgdep { Write-Host "kubectl --namespace=kube-system get deployment $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment @args }
function kddep { Write-Host "kubectl describe deployment $args" -ForegroundColor Magenta; k describe deployment @args }
function ksysddep { Write-Host "kubectl --namespace=kube-system describe deployment $args" -ForegroundColor Magenta; k --namespace=kube-system describe deployment @args }
function krmdep { Write-Host "kubectl delete deployment $args" -ForegroundColor Magenta; k delete deployment @args }
function ksysrmdep { Write-Host "kubectl --namespace=kube-system delete deployment $args" -ForegroundColor Magenta; k --namespace=kube-system delete deployment @args }
function kgsvc { Write-Host "kubectl get service $args" -ForegroundColor Magenta; k get service @args }
function ksysgsvc { Write-Host "kubectl --namespace=kube-system get service $args" -ForegroundColor Magenta; k --namespace=kube-system get service @args }
function kdsvc { Write-Host "kubectl describe service $args" -ForegroundColor Magenta; k describe service @args }
function ksysdsvc { Write-Host "kubectl --namespace=kube-system describe service $args" -ForegroundColor Magenta; k --namespace=kube-system describe service @args }
function krmsvc { Write-Host "kubectl delete service $args" -ForegroundColor Magenta; k delete service @args }
function ksysrmsvc { Write-Host "kubectl --namespace=kube-system delete service $args" -ForegroundColor Magenta; k --namespace=kube-system delete service @args }
function kging { Write-Host "kubectl get ingress $args" -ForegroundColor Magenta; k get ingress @args }
function ksysging { Write-Host "kubectl --namespace=kube-system get ingress $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress @args }
function kding { Write-Host "kubectl describe ingress $args" -ForegroundColor Magenta; k describe ingress @args }
function ksysding { Write-Host "kubectl --namespace=kube-system describe ingress $args" -ForegroundColor Magenta; k --namespace=kube-system describe ingress @args }
function krming { Write-Host "kubectl delete ingress $args" -ForegroundColor Magenta; k delete ingress @args }
function ksysrming { Write-Host "kubectl --namespace=kube-system delete ingress $args" -ForegroundColor Magenta; k --namespace=kube-system delete ingress @args }
function kgcm { Write-Host "kubectl get configmap $args" -ForegroundColor Magenta; k get configmap @args }
function ksysgcm { Write-Host "kubectl --namespace=kube-system get configmap $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap @args }
function kdcm { Write-Host "kubectl describe configmap $args" -ForegroundColor Magenta; k describe configmap @args }
function ksysdcm { Write-Host "kubectl --namespace=kube-system describe configmap $args" -ForegroundColor Magenta; k --namespace=kube-system describe configmap @args }
function krmcm { Write-Host "kubectl delete configmap $args" -ForegroundColor Magenta; k delete configmap @args }
function ksysrmcm { Write-Host "kubectl --namespace=kube-system delete configmap $args" -ForegroundColor Magenta; k --namespace=kube-system delete configmap @args }
function kgsec { Write-Host "kubectl get secret $args" -ForegroundColor Magenta; k get secret @args }
function ksysgsec { Write-Host "kubectl --namespace=kube-system get secret $args" -ForegroundColor Magenta; k --namespace=kube-system get secret @args }
function kdsec { Write-Host "kubectl describe secret $args" -ForegroundColor Magenta; k describe secret @args }
function ksysdsec { Write-Host "kubectl --namespace=kube-system describe secret $args" -ForegroundColor Magenta; k --namespace=kube-system describe secret @args }
function krmsec { Write-Host "kubectl delete secret $args" -ForegroundColor Magenta; k delete secret @args }
function ksysrmsec { Write-Host "kubectl --namespace=kube-system delete secret $args" -ForegroundColor Magenta; k --namespace=kube-system delete secret @args }
function kgno { Write-Host "kubectl get nodes $args" -ForegroundColor Magenta; k get nodes @args }
function kdno { Write-Host "kubectl describe nodes $args" -ForegroundColor Magenta; k describe nodes @args }
function kgns { Write-Host "kubectl get namespaces $args" -ForegroundColor Magenta; k get namespaces @args }
function kdns { Write-Host "kubectl describe namespaces $args" -ForegroundColor Magenta; k describe namespaces @args }
function krmns { Write-Host "kubectl delete namespaces $args" -ForegroundColor Magenta; k delete namespaces @args }
function kgoyaml { Write-Host "kubectl get -o=yaml $args" -ForegroundColor Magenta; k get -o=yaml @args }
function ksysgoyaml { Write-Host "kubectl --namespace=kube-system get -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get -o=yaml @args }
function kgpooyaml { Write-Host "kubectl get pods -o=yaml $args" -ForegroundColor Magenta; k get pods -o=yaml @args }
function ksysgpooyaml { Write-Host "kubectl --namespace=kube-system get pods -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get pods -o=yaml @args }
function kgdepoyaml { Write-Host "kubectl get deployment -o=yaml $args" -ForegroundColor Magenta; k get deployment -o=yaml @args }
function ksysgdepoyaml { Write-Host "kubectl --namespace=kube-system get deployment -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment -o=yaml @args }
function kgsvcoyaml { Write-Host "kubectl get service -o=yaml $args" -ForegroundColor Magenta; k get service -o=yaml @args }
function ksysgsvcoyaml { Write-Host "kubectl --namespace=kube-system get service -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get service -o=yaml @args }
function kgingoyaml { Write-Host "kubectl get ingress -o=yaml $args" -ForegroundColor Magenta; k get ingress -o=yaml @args }
function ksysgingoyaml { Write-Host "kubectl --namespace=kube-system get ingress -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress -o=yaml @args }
function kgcmoyaml { Write-Host "kubectl get configmap -o=yaml $args" -ForegroundColor Magenta; k get configmap -o=yaml @args }
function ksysgcmoyaml { Write-Host "kubectl --namespace=kube-system get configmap -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap -o=yaml @args }
function kgsecoyaml { Write-Host "kubectl get secret -o=yaml $args" -ForegroundColor Magenta; k get secret -o=yaml @args }
function ksysgsecoyaml { Write-Host "kubectl --namespace=kube-system get secret -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get secret -o=yaml @args }
function kgnooyaml { Write-Host "kubectl get nodes -o=yaml $args" -ForegroundColor Magenta; k get nodes -o=yaml @args }
function kgnsoyaml { Write-Host "kubectl get namespaces -o=yaml $args" -ForegroundColor Magenta; k get namespaces -o=yaml @args }
function kgowide { Write-Host "kubectl get -o=wide $args" -ForegroundColor Magenta; k get -o=wide @args }
function ksysgowide { Write-Host "kubectl --namespace=kube-system get -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get -o=wide @args }
function kgpoowide { Write-Host "kubectl get pods -o=wide $args" -ForegroundColor Magenta; k get pods -o=wide @args }
function ksysgpoowide { Write-Host "kubectl --namespace=kube-system get pods -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get pods -o=wide @args }
function kgdepowide { Write-Host "kubectl get deployment -o=wide $args" -ForegroundColor Magenta; k get deployment -o=wide @args }
function ksysgdepowide { Write-Host "kubectl --namespace=kube-system get deployment -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment -o=wide @args }
function kgsvcowide { Write-Host "kubectl get service -o=wide $args" -ForegroundColor Magenta; k get service -o=wide @args }
function ksysgsvcowide { Write-Host "kubectl --namespace=kube-system get service -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get service -o=wide @args }
function kgingowide { Write-Host "kubectl get ingress -o=wide $args" -ForegroundColor Magenta; k get ingress -o=wide @args }
function ksysgingowide { Write-Host "kubectl --namespace=kube-system get ingress -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress -o=wide @args }
function kgcmowide { Write-Host "kubectl get configmap -o=wide $args" -ForegroundColor Magenta; k get configmap -o=wide @args }
function ksysgcmowide { Write-Host "kubectl --namespace=kube-system get configmap -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap -o=wide @args }
function kgsecowide { Write-Host "kubectl get secret -o=wide $args" -ForegroundColor Magenta; k get secret -o=wide @args }
function ksysgsecowide { Write-Host "kubectl --namespace=kube-system get secret -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get secret -o=wide @args }
function kgnoowide { Write-Host "kubectl get nodes -o=wide $args" -ForegroundColor Magenta; k get nodes -o=wide @args }
function kgnsowide { Write-Host "kubectl get namespaces -o=wide $args" -ForegroundColor Magenta; k get namespaces -o=wide @args }
function kgojson { Write-Host "kubectl get -o=json $args" -ForegroundColor Magenta; k get -o=json @args }
function ksysgojson { Write-Host "kubectl --namespace=kube-system get -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get -o=json @args }
function kgpoojson { Write-Host "kubectl get pods -o=json $args" -ForegroundColor Magenta; k get pods -o=json @args }
function ksysgpoojson { Write-Host "kubectl --namespace=kube-system get pods -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get pods -o=json @args }
function kgdepojson { Write-Host "kubectl get deployment -o=json $args" -ForegroundColor Magenta; k get deployment -o=json @args }
function ksysgdepojson { Write-Host "kubectl --namespace=kube-system get deployment -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment -o=json @args }
function kgsvcojson { Write-Host "kubectl get service -o=json $args" -ForegroundColor Magenta; k get service -o=json @args }
function ksysgsvcojson { Write-Host "kubectl --namespace=kube-system get service -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get service -o=json @args }
function kgingojson { Write-Host "kubectl get ingress -o=json $args" -ForegroundColor Magenta; k get ingress -o=json @args }
function ksysgingojson { Write-Host "kubectl --namespace=kube-system get ingress -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress -o=json @args }
function kgcmojson { Write-Host "kubectl get configmap -o=json $args" -ForegroundColor Magenta; k get configmap -o=json @args }
function ksysgcmojson { Write-Host "kubectl --namespace=kube-system get configmap -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap -o=json @args }
function kgsecojson { Write-Host "kubectl get secret -o=json $args" -ForegroundColor Magenta; k get secret -o=json @args }
function ksysgsecojson { Write-Host "kubectl --namespace=kube-system get secret -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get secret -o=json @args }
function kgnoojson { Write-Host "kubectl get nodes -o=json $args" -ForegroundColor Magenta; k get nodes -o=json @args }
function kgnsojson { Write-Host "kubectl get namespaces -o=json $args" -ForegroundColor Magenta; k get namespaces -o=json @args }
function kgall { Write-Host "kubectl get --all-namespaces $args" -ForegroundColor Magenta; k get --all-namespaces @args }
function kdall { Write-Host "kubectl describe --all-namespaces $args" -ForegroundColor Magenta; k describe --all-namespaces @args }
function kgpoall { Write-Host "kubectl get pods --all-namespaces $args" -ForegroundColor Magenta; k get pods --all-namespaces @args }
function kdpoall { Write-Host "kubectl describe pods --all-namespaces $args" -ForegroundColor Magenta; k describe pods --all-namespaces @args }
function kgdepall { Write-Host "kubectl get deployment --all-namespaces $args" -ForegroundColor Magenta; k get deployment --all-namespaces @args }
function kddepall { Write-Host "kubectl describe deployment --all-namespaces $args" -ForegroundColor Magenta; k describe deployment --all-namespaces @args }
function kgsvcall { Write-Host "kubectl get service --all-namespaces $args" -ForegroundColor Magenta; k get service --all-namespaces @args }
function kdsvcall { Write-Host "kubectl describe service --all-namespaces $args" -ForegroundColor Magenta; k describe service --all-namespaces @args }
function kgingall { Write-Host "kubectl get ingress --all-namespaces $args" -ForegroundColor Magenta; k get ingress --all-namespaces @args }
function kdingall { Write-Host "kubectl describe ingress --all-namespaces $args" -ForegroundColor Magenta; k describe ingress --all-namespaces @args }
function kgcmall { Write-Host "kubectl get configmap --all-namespaces $args" -ForegroundColor Magenta; k get configmap --all-namespaces @args }
function kdcmall { Write-Host "kubectl describe configmap --all-namespaces $args" -ForegroundColor Magenta; k describe configmap --all-namespaces @args }
function kgsecall { Write-Host "kubectl get secret --all-namespaces $args" -ForegroundColor Magenta; k get secret --all-namespaces @args }
function kdsecall { Write-Host "kubectl describe secret --all-namespaces $args" -ForegroundColor Magenta; k describe secret --all-namespaces @args }
function kgnsall { Write-Host "kubectl get namespaces --all-namespaces $args" -ForegroundColor Magenta; k get namespaces --all-namespaces @args }
function kdnsall { Write-Host "kubectl describe namespaces --all-namespaces $args" -ForegroundColor Magenta; k describe namespaces --all-namespaces @args }
function kgsl { Write-Host "kubectl get --show-labels $args" -ForegroundColor Magenta; k get --show-labels @args }
function ksysgsl { Write-Host "kubectl --namespace=kube-system get --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get --show-labels @args }
function kgposl { Write-Host "kubectl get pods --show-labels $args" -ForegroundColor Magenta; k get pods --show-labels @args }
function ksysgposl { Write-Host "kubectl --namespace=kube-system get pods --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --show-labels @args }
function kgdepsl { Write-Host "kubectl get deployment --show-labels $args" -ForegroundColor Magenta; k get deployment --show-labels @args }
function ksysgdepsl { Write-Host "kubectl --namespace=kube-system get deployment --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --show-labels @args }
function krmall { Write-Host "kubectl delete --all $args" -ForegroundColor Magenta; k delete --all @args }
function ksysrmall { Write-Host "kubectl --namespace=kube-system delete --all $args" -ForegroundColor Magenta; k --namespace=kube-system delete --all @args }
function krmpoall { Write-Host "kubectl delete pods --all $args" -ForegroundColor Magenta; k delete pods --all @args }
function ksysrmpoall { Write-Host "kubectl --namespace=kube-system delete pods --all $args" -ForegroundColor Magenta; k --namespace=kube-system delete pods --all @args }
function krmdepall { Write-Host "kubectl delete deployment --all $args" -ForegroundColor Magenta; k delete deployment --all @args }
function ksysrmdepall { Write-Host "kubectl --namespace=kube-system delete deployment --all $args" -ForegroundColor Magenta; k --namespace=kube-system delete deployment --all @args }
function krmsvcall { Write-Host "kubectl delete service --all $args" -ForegroundColor Magenta; k delete service --all @args }
function ksysrmsvcall { Write-Host "kubectl --namespace=kube-system delete service --all $args" -ForegroundColor Magenta; k --namespace=kube-system delete service --all @args }
function krmingall { Write-Host "kubectl delete ingress --all $args" -ForegroundColor Magenta; k delete ingress --all @args }
function ksysrmingall { Write-Host "kubectl --namespace=kube-system delete ingress --all $args" -ForegroundColor Magenta; k --namespace=kube-system delete ingress --all @args }
function krmcmall { Write-Host "kubectl delete configmap --all $args" -ForegroundColor Magenta; k delete configmap --all @args }
function ksysrmcmall { Write-Host "kubectl --namespace=kube-system delete configmap --all $args" -ForegroundColor Magenta; k --namespace=kube-system delete configmap --all @args }
function krmsecall { Write-Host "kubectl delete secret --all $args" -ForegroundColor Magenta; k delete secret --all @args }
function ksysrmsecall { Write-Host "kubectl --namespace=kube-system delete secret --all $args" -ForegroundColor Magenta; k --namespace=kube-system delete secret --all @args }
function krmnsall { Write-Host "kubectl delete namespaces --all $args" -ForegroundColor Magenta; k delete namespaces --all @args }
function kgw { Write-Host "kubectl get --watch $args" -ForegroundColor Magenta; k get --watch @args }
function ksysgw { Write-Host "kubectl --namespace=kube-system get --watch $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch @args }
function kgpow { Write-Host "kubectl get pods --watch $args" -ForegroundColor Magenta; k get pods --watch @args }
function ksysgpow { Write-Host "kubectl --namespace=kube-system get pods --watch $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch @args }
function kgdepw { Write-Host "kubectl get deployment --watch $args" -ForegroundColor Magenta; k get deployment --watch @args }
function ksysgdepw { Write-Host "kubectl --namespace=kube-system get deployment --watch $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch @args }
function kgsvcw { Write-Host "kubectl get service --watch $args" -ForegroundColor Magenta; k get service --watch @args }
function ksysgsvcw { Write-Host "kubectl --namespace=kube-system get service --watch $args" -ForegroundColor Magenta; k --namespace=kube-system get service --watch @args }
function kgingw { Write-Host "kubectl get ingress --watch $args" -ForegroundColor Magenta; k get ingress --watch @args }
function ksysgingw { Write-Host "kubectl --namespace=kube-system get ingress --watch $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress --watch @args }
function kgcmw { Write-Host "kubectl get configmap --watch $args" -ForegroundColor Magenta; k get configmap --watch @args }
function ksysgcmw { Write-Host "kubectl --namespace=kube-system get configmap --watch $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap --watch @args }
function kgsecw { Write-Host "kubectl get secret --watch $args" -ForegroundColor Magenta; k get secret --watch @args }
function ksysgsecw { Write-Host "kubectl --namespace=kube-system get secret --watch $args" -ForegroundColor Magenta; k --namespace=kube-system get secret --watch @args }
function kgnow { Write-Host "kubectl get nodes --watch $args" -ForegroundColor Magenta; k get nodes --watch @args }
function kgnsw { Write-Host "kubectl get namespaces --watch $args" -ForegroundColor Magenta; k get namespaces --watch @args }
function kgoyamlall { Write-Host "kubectl get -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get -o=yaml --all-namespaces @args }
function kgpooyamlall { Write-Host "kubectl get pods -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get pods -o=yaml --all-namespaces @args }
function kgdepoyamlall { Write-Host "kubectl get deployment -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get deployment -o=yaml --all-namespaces @args }
function kgsvcoyamlall { Write-Host "kubectl get service -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get service -o=yaml --all-namespaces @args }
function kgingoyamlall { Write-Host "kubectl get ingress -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get ingress -o=yaml --all-namespaces @args }
function kgcmoyamlall { Write-Host "kubectl get configmap -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get configmap -o=yaml --all-namespaces @args }
function kgsecoyamlall { Write-Host "kubectl get secret -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get secret -o=yaml --all-namespaces @args }
function kgnsoyamlall { Write-Host "kubectl get namespaces -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get namespaces -o=yaml --all-namespaces @args }
function kgalloyaml { Write-Host "kubectl get --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get --all-namespaces -o=yaml @args }
function kgpoalloyaml { Write-Host "kubectl get pods --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get pods --all-namespaces -o=yaml @args }
function kgdepalloyaml { Write-Host "kubectl get deployment --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get deployment --all-namespaces -o=yaml @args }
function kgsvcalloyaml { Write-Host "kubectl get service --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get service --all-namespaces -o=yaml @args }
function kgingalloyaml { Write-Host "kubectl get ingress --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get ingress --all-namespaces -o=yaml @args }
function kgcmalloyaml { Write-Host "kubectl get configmap --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get configmap --all-namespaces -o=yaml @args }
function kgsecalloyaml { Write-Host "kubectl get secret --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get secret --all-namespaces -o=yaml @args }
function kgnsalloyaml { Write-Host "kubectl get namespaces --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get namespaces --all-namespaces -o=yaml @args }
function kgwoyaml { Write-Host "kubectl get --watch -o=yaml $args" -ForegroundColor Magenta; k get --watch -o=yaml @args }
function ksysgwoyaml { Write-Host "kubectl --namespace=kube-system get --watch -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch -o=yaml @args }
function kgpowoyaml { Write-Host "kubectl get pods --watch -o=yaml $args" -ForegroundColor Magenta; k get pods --watch -o=yaml @args }
function ksysgpowoyaml { Write-Host "kubectl --namespace=kube-system get pods --watch -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch -o=yaml @args }
function kgdepwoyaml { Write-Host "kubectl get deployment --watch -o=yaml $args" -ForegroundColor Magenta; k get deployment --watch -o=yaml @args }
function ksysgdepwoyaml { Write-Host "kubectl --namespace=kube-system get deployment --watch -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch -o=yaml @args }
function kgsvcwoyaml { Write-Host "kubectl get service --watch -o=yaml $args" -ForegroundColor Magenta; k get service --watch -o=yaml @args }
function ksysgsvcwoyaml { Write-Host "kubectl --namespace=kube-system get service --watch -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get service --watch -o=yaml @args }
function kgingwoyaml { Write-Host "kubectl get ingress --watch -o=yaml $args" -ForegroundColor Magenta; k get ingress --watch -o=yaml @args }
function ksysgingwoyaml { Write-Host "kubectl --namespace=kube-system get ingress --watch -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress --watch -o=yaml @args }
function kgcmwoyaml { Write-Host "kubectl get configmap --watch -o=yaml $args" -ForegroundColor Magenta; k get configmap --watch -o=yaml @args }
function ksysgcmwoyaml { Write-Host "kubectl --namespace=kube-system get configmap --watch -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap --watch -o=yaml @args }
function kgsecwoyaml { Write-Host "kubectl get secret --watch -o=yaml $args" -ForegroundColor Magenta; k get secret --watch -o=yaml @args }
function ksysgsecwoyaml { Write-Host "kubectl --namespace=kube-system get secret --watch -o=yaml $args" -ForegroundColor Magenta; k --namespace=kube-system get secret --watch -o=yaml @args }
function kgnowoyaml { Write-Host "kubectl get nodes --watch -o=yaml $args" -ForegroundColor Magenta; k get nodes --watch -o=yaml @args }
function kgnswoyaml { Write-Host "kubectl get namespaces --watch -o=yaml $args" -ForegroundColor Magenta; k get namespaces --watch -o=yaml @args }
function kgowideall { Write-Host "kubectl get -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get -o=wide --all-namespaces @args }
function kgpoowideall { Write-Host "kubectl get pods -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get pods -o=wide --all-namespaces @args }
function kgdepowideall { Write-Host "kubectl get deployment -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get deployment -o=wide --all-namespaces @args }
function kgsvcowideall { Write-Host "kubectl get service -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get service -o=wide --all-namespaces @args }
function kgingowideall { Write-Host "kubectl get ingress -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get ingress -o=wide --all-namespaces @args }
function kgcmowideall { Write-Host "kubectl get configmap -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get configmap -o=wide --all-namespaces @args }
function kgsecowideall { Write-Host "kubectl get secret -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get secret -o=wide --all-namespaces @args }
function kgnsowideall { Write-Host "kubectl get namespaces -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get namespaces -o=wide --all-namespaces @args }
function kgallowide { Write-Host "kubectl get --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get --all-namespaces -o=wide @args }
function kgpoallowide { Write-Host "kubectl get pods --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get pods --all-namespaces -o=wide @args }
function kgdepallowide { Write-Host "kubectl get deployment --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get deployment --all-namespaces -o=wide @args }
function kgsvcallowide { Write-Host "kubectl get service --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get service --all-namespaces -o=wide @args }
function kgingallowide { Write-Host "kubectl get ingress --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get ingress --all-namespaces -o=wide @args }
function kgcmallowide { Write-Host "kubectl get configmap --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get configmap --all-namespaces -o=wide @args }
function kgsecallowide { Write-Host "kubectl get secret --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get secret --all-namespaces -o=wide @args }
function kgnsallowide { Write-Host "kubectl get namespaces --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get namespaces --all-namespaces -o=wide @args }
function kgowidesl { Write-Host "kubectl get -o=wide --show-labels $args" -ForegroundColor Magenta; k get -o=wide --show-labels @args }
function ksysgowidesl { Write-Host "kubectl --namespace=kube-system get -o=wide --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get -o=wide --show-labels @args }
function kgpoowidesl { Write-Host "kubectl get pods -o=wide --show-labels $args" -ForegroundColor Magenta; k get pods -o=wide --show-labels @args }
function ksysgpoowidesl { Write-Host "kubectl --namespace=kube-system get pods -o=wide --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get pods -o=wide --show-labels @args }
function kgdepowidesl { Write-Host "kubectl get deployment -o=wide --show-labels $args" -ForegroundColor Magenta; k get deployment -o=wide --show-labels @args }
function ksysgdepowidesl { Write-Host "kubectl --namespace=kube-system get deployment -o=wide --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment -o=wide --show-labels @args }
function kgslowide { Write-Host "kubectl get --show-labels -o=wide $args" -ForegroundColor Magenta; k get --show-labels -o=wide @args }
function ksysgslowide { Write-Host "kubectl --namespace=kube-system get --show-labels -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get --show-labels -o=wide @args }
function kgposlowide { Write-Host "kubectl get pods --show-labels -o=wide $args" -ForegroundColor Magenta; k get pods --show-labels -o=wide @args }
function ksysgposlowide { Write-Host "kubectl --namespace=kube-system get pods --show-labels -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --show-labels -o=wide @args }
function kgdepslowide { Write-Host "kubectl get deployment --show-labels -o=wide $args" -ForegroundColor Magenta; k get deployment --show-labels -o=wide @args }
function ksysgdepslowide { Write-Host "kubectl --namespace=kube-system get deployment --show-labels -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --show-labels -o=wide @args }
function kgwowide { Write-Host "kubectl get --watch -o=wide $args" -ForegroundColor Magenta; k get --watch -o=wide @args }
function ksysgwowide { Write-Host "kubectl --namespace=kube-system get --watch -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch -o=wide @args }
function kgpowowide { Write-Host "kubectl get pods --watch -o=wide $args" -ForegroundColor Magenta; k get pods --watch -o=wide @args }
function ksysgpowowide { Write-Host "kubectl --namespace=kube-system get pods --watch -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch -o=wide @args }
function kgdepwowide { Write-Host "kubectl get deployment --watch -o=wide $args" -ForegroundColor Magenta; k get deployment --watch -o=wide @args }
function ksysgdepwowide { Write-Host "kubectl --namespace=kube-system get deployment --watch -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch -o=wide @args }
function kgsvcwowide { Write-Host "kubectl get service --watch -o=wide $args" -ForegroundColor Magenta; k get service --watch -o=wide @args }
function ksysgsvcwowide { Write-Host "kubectl --namespace=kube-system get service --watch -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get service --watch -o=wide @args }
function kgingwowide { Write-Host "kubectl get ingress --watch -o=wide $args" -ForegroundColor Magenta; k get ingress --watch -o=wide @args }
function ksysgingwowide { Write-Host "kubectl --namespace=kube-system get ingress --watch -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress --watch -o=wide @args }
function kgcmwowide { Write-Host "kubectl get configmap --watch -o=wide $args" -ForegroundColor Magenta; k get configmap --watch -o=wide @args }
function ksysgcmwowide { Write-Host "kubectl --namespace=kube-system get configmap --watch -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap --watch -o=wide @args }
function kgsecwowide { Write-Host "kubectl get secret --watch -o=wide $args" -ForegroundColor Magenta; k get secret --watch -o=wide @args }
function ksysgsecwowide { Write-Host "kubectl --namespace=kube-system get secret --watch -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get secret --watch -o=wide @args }
function kgnowowide { Write-Host "kubectl get nodes --watch -o=wide $args" -ForegroundColor Magenta; k get nodes --watch -o=wide @args }
function kgnswowide { Write-Host "kubectl get namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get namespaces --watch -o=wide @args }
function kgojsonall { Write-Host "kubectl get -o=json --all-namespaces $args" -ForegroundColor Magenta; k get -o=json --all-namespaces @args }
function kgpoojsonall { Write-Host "kubectl get pods -o=json --all-namespaces $args" -ForegroundColor Magenta; k get pods -o=json --all-namespaces @args }
function kgdepojsonall { Write-Host "kubectl get deployment -o=json --all-namespaces $args" -ForegroundColor Magenta; k get deployment -o=json --all-namespaces @args }
function kgsvcojsonall { Write-Host "kubectl get service -o=json --all-namespaces $args" -ForegroundColor Magenta; k get service -o=json --all-namespaces @args }
function kgingojsonall { Write-Host "kubectl get ingress -o=json --all-namespaces $args" -ForegroundColor Magenta; k get ingress -o=json --all-namespaces @args }
function kgcmojsonall { Write-Host "kubectl get configmap -o=json --all-namespaces $args" -ForegroundColor Magenta; k get configmap -o=json --all-namespaces @args }
function kgsecojsonall { Write-Host "kubectl get secret -o=json --all-namespaces $args" -ForegroundColor Magenta; k get secret -o=json --all-namespaces @args }
function kgnsojsonall { Write-Host "kubectl get namespaces -o=json --all-namespaces $args" -ForegroundColor Magenta; k get namespaces -o=json --all-namespaces @args }
function kgallojson { Write-Host "kubectl get --all-namespaces -o=json $args" -ForegroundColor Magenta; k get --all-namespaces -o=json @args }
function kgpoallojson { Write-Host "kubectl get pods --all-namespaces -o=json $args" -ForegroundColor Magenta; k get pods --all-namespaces -o=json @args }
function kgdepallojson { Write-Host "kubectl get deployment --all-namespaces -o=json $args" -ForegroundColor Magenta; k get deployment --all-namespaces -o=json @args }
function kgsvcallojson { Write-Host "kubectl get service --all-namespaces -o=json $args" -ForegroundColor Magenta; k get service --all-namespaces -o=json @args }
function kgingallojson { Write-Host "kubectl get ingress --all-namespaces -o=json $args" -ForegroundColor Magenta; k get ingress --all-namespaces -o=json @args }
function kgcmallojson { Write-Host "kubectl get configmap --all-namespaces -o=json $args" -ForegroundColor Magenta; k get configmap --all-namespaces -o=json @args }
function kgsecallojson { Write-Host "kubectl get secret --all-namespaces -o=json $args" -ForegroundColor Magenta; k get secret --all-namespaces -o=json @args }
function kgnsallojson { Write-Host "kubectl get namespaces --all-namespaces -o=json $args" -ForegroundColor Magenta; k get namespaces --all-namespaces -o=json @args }
function kgwojson { Write-Host "kubectl get --watch -o=json $args" -ForegroundColor Magenta; k get --watch -o=json @args }
function ksysgwojson { Write-Host "kubectl --namespace=kube-system get --watch -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch -o=json @args }
function kgpowojson { Write-Host "kubectl get pods --watch -o=json $args" -ForegroundColor Magenta; k get pods --watch -o=json @args }
function ksysgpowojson { Write-Host "kubectl --namespace=kube-system get pods --watch -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch -o=json @args }
function kgdepwojson { Write-Host "kubectl get deployment --watch -o=json $args" -ForegroundColor Magenta; k get deployment --watch -o=json @args }
function ksysgdepwojson { Write-Host "kubectl --namespace=kube-system get deployment --watch -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch -o=json @args }
function kgsvcwojson { Write-Host "kubectl get service --watch -o=json $args" -ForegroundColor Magenta; k get service --watch -o=json @args }
function ksysgsvcwojson { Write-Host "kubectl --namespace=kube-system get service --watch -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get service --watch -o=json @args }
function kgingwojson { Write-Host "kubectl get ingress --watch -o=json $args" -ForegroundColor Magenta; k get ingress --watch -o=json @args }
function ksysgingwojson { Write-Host "kubectl --namespace=kube-system get ingress --watch -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress --watch -o=json @args }
function kgcmwojson { Write-Host "kubectl get configmap --watch -o=json $args" -ForegroundColor Magenta; k get configmap --watch -o=json @args }
function ksysgcmwojson { Write-Host "kubectl --namespace=kube-system get configmap --watch -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap --watch -o=json @args }
function kgsecwojson { Write-Host "kubectl get secret --watch -o=json $args" -ForegroundColor Magenta; k get secret --watch -o=json @args }
function ksysgsecwojson { Write-Host "kubectl --namespace=kube-system get secret --watch -o=json $args" -ForegroundColor Magenta; k --namespace=kube-system get secret --watch -o=json @args }
function kgnowojson { Write-Host "kubectl get nodes --watch -o=json $args" -ForegroundColor Magenta; k get nodes --watch -o=json @args }
function kgnswojson { Write-Host "kubectl get namespaces --watch -o=json $args" -ForegroundColor Magenta; k get namespaces --watch -o=json @args }
function kgallsl { Write-Host "kubectl get --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get --all-namespaces --show-labels @args }
function kgpoallsl { Write-Host "kubectl get pods --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get pods --all-namespaces --show-labels @args }
function kgdepallsl { Write-Host "kubectl get deployment --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get deployment --all-namespaces --show-labels @args }
function kgslall { Write-Host "kubectl get --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get --show-labels --all-namespaces @args }
function kgposlall { Write-Host "kubectl get pods --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get pods --show-labels --all-namespaces @args }
function kgdepslall { Write-Host "kubectl get deployment --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get deployment --show-labels --all-namespaces @args }
function kgallw { Write-Host "kubectl get --all-namespaces --watch $args" -ForegroundColor Magenta; k get --all-namespaces --watch @args }
function kgpoallw { Write-Host "kubectl get pods --all-namespaces --watch $args" -ForegroundColor Magenta; k get pods --all-namespaces --watch @args }
function kgdepallw { Write-Host "kubectl get deployment --all-namespaces --watch $args" -ForegroundColor Magenta; k get deployment --all-namespaces --watch @args }
function kgsvcallw { Write-Host "kubectl get service --all-namespaces --watch $args" -ForegroundColor Magenta; k get service --all-namespaces --watch @args }
function kgingallw { Write-Host "kubectl get ingress --all-namespaces --watch $args" -ForegroundColor Magenta; k get ingress --all-namespaces --watch @args }
function kgcmallw { Write-Host "kubectl get configmap --all-namespaces --watch $args" -ForegroundColor Magenta; k get configmap --all-namespaces --watch @args }
function kgsecallw { Write-Host "kubectl get secret --all-namespaces --watch $args" -ForegroundColor Magenta; k get secret --all-namespaces --watch @args }
function kgnsallw { Write-Host "kubectl get namespaces --all-namespaces --watch $args" -ForegroundColor Magenta; k get namespaces --all-namespaces --watch @args }
function kgwall { Write-Host "kubectl get --watch --all-namespaces $args" -ForegroundColor Magenta; k get --watch --all-namespaces @args }
function kgpowall { Write-Host "kubectl get pods --watch --all-namespaces $args" -ForegroundColor Magenta; k get pods --watch --all-namespaces @args }
function kgdepwall { Write-Host "kubectl get deployment --watch --all-namespaces $args" -ForegroundColor Magenta; k get deployment --watch --all-namespaces @args }
function kgsvcwall { Write-Host "kubectl get service --watch --all-namespaces $args" -ForegroundColor Magenta; k get service --watch --all-namespaces @args }
function kgingwall { Write-Host "kubectl get ingress --watch --all-namespaces $args" -ForegroundColor Magenta; k get ingress --watch --all-namespaces @args }
function kgcmwall { Write-Host "kubectl get configmap --watch --all-namespaces $args" -ForegroundColor Magenta; k get configmap --watch --all-namespaces @args }
function kgsecwall { Write-Host "kubectl get secret --watch --all-namespaces $args" -ForegroundColor Magenta; k get secret --watch --all-namespaces @args }
function kgnswall { Write-Host "kubectl get namespaces --watch --all-namespaces $args" -ForegroundColor Magenta; k get namespaces --watch --all-namespaces @args }
function kgslw { Write-Host "kubectl get --show-labels --watch $args" -ForegroundColor Magenta; k get --show-labels --watch @args }
function ksysgslw { Write-Host "kubectl --namespace=kube-system get --show-labels --watch $args" -ForegroundColor Magenta; k --namespace=kube-system get --show-labels --watch @args }
function kgposlw { Write-Host "kubectl get pods --show-labels --watch $args" -ForegroundColor Magenta; k get pods --show-labels --watch @args }
function ksysgposlw { Write-Host "kubectl --namespace=kube-system get pods --show-labels --watch $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --show-labels --watch @args }
function kgdepslw { Write-Host "kubectl get deployment --show-labels --watch $args" -ForegroundColor Magenta; k get deployment --show-labels --watch @args }
function ksysgdepslw { Write-Host "kubectl --namespace=kube-system get deployment --show-labels --watch $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --show-labels --watch @args }
function kgwsl { Write-Host "kubectl get --watch --show-labels $args" -ForegroundColor Magenta; k get --watch --show-labels @args }
function ksysgwsl { Write-Host "kubectl --namespace=kube-system get --watch --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch --show-labels @args }
function kgpowsl { Write-Host "kubectl get pods --watch --show-labels $args" -ForegroundColor Magenta; k get pods --watch --show-labels @args }
function ksysgpowsl { Write-Host "kubectl --namespace=kube-system get pods --watch --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch --show-labels @args }
function kgdepwsl { Write-Host "kubectl get deployment --watch --show-labels $args" -ForegroundColor Magenta; k get deployment --watch --show-labels @args }
function ksysgdepwsl { Write-Host "kubectl --namespace=kube-system get deployment --watch --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch --show-labels @args }
function kgallwoyaml { Write-Host "kubectl get --all-namespaces --watch -o=yaml $args" -ForegroundColor Magenta; k get --all-namespaces --watch -o=yaml @args }
function kgpoallwoyaml { Write-Host "kubectl get pods --all-namespaces --watch -o=yaml $args" -ForegroundColor Magenta; k get pods --all-namespaces --watch -o=yaml @args }
function kgdepallwoyaml { Write-Host "kubectl get deployment --all-namespaces --watch -o=yaml $args" -ForegroundColor Magenta; k get deployment --all-namespaces --watch -o=yaml @args }
function kgsvcallwoyaml { Write-Host "kubectl get service --all-namespaces --watch -o=yaml $args" -ForegroundColor Magenta; k get service --all-namespaces --watch -o=yaml @args }
function kgingallwoyaml { Write-Host "kubectl get ingress --all-namespaces --watch -o=yaml $args" -ForegroundColor Magenta; k get ingress --all-namespaces --watch -o=yaml @args }
function kgcmallwoyaml { Write-Host "kubectl get configmap --all-namespaces --watch -o=yaml $args" -ForegroundColor Magenta; k get configmap --all-namespaces --watch -o=yaml @args }
function kgsecallwoyaml { Write-Host "kubectl get secret --all-namespaces --watch -o=yaml $args" -ForegroundColor Magenta; k get secret --all-namespaces --watch -o=yaml @args }
function kgnsallwoyaml { Write-Host "kubectl get namespaces --all-namespaces --watch -o=yaml $args" -ForegroundColor Magenta; k get namespaces --all-namespaces --watch -o=yaml @args }
function kgwoyamlall { Write-Host "kubectl get --watch -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get --watch -o=yaml --all-namespaces @args }
function kgpowoyamlall { Write-Host "kubectl get pods --watch -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get pods --watch -o=yaml --all-namespaces @args }
function kgdepwoyamlall { Write-Host "kubectl get deployment --watch -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get deployment --watch -o=yaml --all-namespaces @args }
function kgsvcwoyamlall { Write-Host "kubectl get service --watch -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get service --watch -o=yaml --all-namespaces @args }
function kgingwoyamlall { Write-Host "kubectl get ingress --watch -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get ingress --watch -o=yaml --all-namespaces @args }
function kgcmwoyamlall { Write-Host "kubectl get configmap --watch -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get configmap --watch -o=yaml --all-namespaces @args }
function kgsecwoyamlall { Write-Host "kubectl get secret --watch -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get secret --watch -o=yaml --all-namespaces @args }
function kgnswoyamlall { Write-Host "kubectl get namespaces --watch -o=yaml --all-namespaces $args" -ForegroundColor Magenta; k get namespaces --watch -o=yaml --all-namespaces @args }
function kgwalloyaml { Write-Host "kubectl get --watch --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get --watch --all-namespaces -o=yaml @args }
function kgpowalloyaml { Write-Host "kubectl get pods --watch --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get pods --watch --all-namespaces -o=yaml @args }
function kgdepwalloyaml { Write-Host "kubectl get deployment --watch --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get deployment --watch --all-namespaces -o=yaml @args }
function kgsvcwalloyaml { Write-Host "kubectl get service --watch --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get service --watch --all-namespaces -o=yaml @args }
function kgingwalloyaml { Write-Host "kubectl get ingress --watch --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get ingress --watch --all-namespaces -o=yaml @args }
function kgcmwalloyaml { Write-Host "kubectl get configmap --watch --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get configmap --watch --all-namespaces -o=yaml @args }
function kgsecwalloyaml { Write-Host "kubectl get secret --watch --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get secret --watch --all-namespaces -o=yaml @args }
function kgnswalloyaml { Write-Host "kubectl get namespaces --watch --all-namespaces -o=yaml $args" -ForegroundColor Magenta; k get namespaces --watch --all-namespaces -o=yaml @args }
function kgowideallsl { Write-Host "kubectl get -o=wide --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get -o=wide --all-namespaces --show-labels @args }
function kgpoowideallsl { Write-Host "kubectl get pods -o=wide --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get pods -o=wide --all-namespaces --show-labels @args }
function kgdepowideallsl { Write-Host "kubectl get deployment -o=wide --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get deployment -o=wide --all-namespaces --show-labels @args }
function kgowideslall { Write-Host "kubectl get -o=wide --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get -o=wide --show-labels --all-namespaces @args }
function kgpoowideslall { Write-Host "kubectl get pods -o=wide --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get pods -o=wide --show-labels --all-namespaces @args }
function kgdepowideslall { Write-Host "kubectl get deployment -o=wide --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get deployment -o=wide --show-labels --all-namespaces @args }
function kgallowidesl { Write-Host "kubectl get --all-namespaces -o=wide --show-labels $args" -ForegroundColor Magenta; k get --all-namespaces -o=wide --show-labels @args }
function kgpoallowidesl { Write-Host "kubectl get pods --all-namespaces -o=wide --show-labels $args" -ForegroundColor Magenta; k get pods --all-namespaces -o=wide --show-labels @args }
function kgdepallowidesl { Write-Host "kubectl get deployment --all-namespaces -o=wide --show-labels $args" -ForegroundColor Magenta; k get deployment --all-namespaces -o=wide --show-labels @args }
function kgallslowide { Write-Host "kubectl get --all-namespaces --show-labels -o=wide $args" -ForegroundColor Magenta; k get --all-namespaces --show-labels -o=wide @args }
function kgpoallslowide { Write-Host "kubectl get pods --all-namespaces --show-labels -o=wide $args" -ForegroundColor Magenta; k get pods --all-namespaces --show-labels -o=wide @args }
function kgdepallslowide { Write-Host "kubectl get deployment --all-namespaces --show-labels -o=wide $args" -ForegroundColor Magenta; k get deployment --all-namespaces --show-labels -o=wide @args }
function kgslowideall { Write-Host "kubectl get --show-labels -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get --show-labels -o=wide --all-namespaces @args }
function kgposlowideall { Write-Host "kubectl get pods --show-labels -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get pods --show-labels -o=wide --all-namespaces @args }
function kgdepslowideall { Write-Host "kubectl get deployment --show-labels -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get deployment --show-labels -o=wide --all-namespaces @args }
function kgslallowide { Write-Host "kubectl get --show-labels --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get --show-labels --all-namespaces -o=wide @args }
function kgposlallowide { Write-Host "kubectl get pods --show-labels --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get pods --show-labels --all-namespaces -o=wide @args }
function kgdepslallowide { Write-Host "kubectl get deployment --show-labels --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get deployment --show-labels --all-namespaces -o=wide @args }
function kgallwowide { Write-Host "kubectl get --all-namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get --all-namespaces --watch -o=wide @args }
function kgpoallwowide { Write-Host "kubectl get pods --all-namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get pods --all-namespaces --watch -o=wide @args }
function kgdepallwowide { Write-Host "kubectl get deployment --all-namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get deployment --all-namespaces --watch -o=wide @args }
function kgsvcallwowide { Write-Host "kubectl get service --all-namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get service --all-namespaces --watch -o=wide @args }
function kgingallwowide { Write-Host "kubectl get ingress --all-namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get ingress --all-namespaces --watch -o=wide @args }
function kgcmallwowide { Write-Host "kubectl get configmap --all-namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get configmap --all-namespaces --watch -o=wide @args }
function kgsecallwowide { Write-Host "kubectl get secret --all-namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get secret --all-namespaces --watch -o=wide @args }
function kgnsallwowide { Write-Host "kubectl get namespaces --all-namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get namespaces --all-namespaces --watch -o=wide @args }
function kgwowideall { Write-Host "kubectl get --watch -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get --watch -o=wide --all-namespaces @args }
function kgpowowideall { Write-Host "kubectl get pods --watch -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get pods --watch -o=wide --all-namespaces @args }
function kgdepwowideall { Write-Host "kubectl get deployment --watch -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get deployment --watch -o=wide --all-namespaces @args }
function kgsvcwowideall { Write-Host "kubectl get service --watch -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get service --watch -o=wide --all-namespaces @args }
function kgingwowideall { Write-Host "kubectl get ingress --watch -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get ingress --watch -o=wide --all-namespaces @args }
function kgcmwowideall { Write-Host "kubectl get configmap --watch -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get configmap --watch -o=wide --all-namespaces @args }
function kgsecwowideall { Write-Host "kubectl get secret --watch -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get secret --watch -o=wide --all-namespaces @args }
function kgnswowideall { Write-Host "kubectl get namespaces --watch -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get namespaces --watch -o=wide --all-namespaces @args }
function kgwallowide { Write-Host "kubectl get --watch --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get --watch --all-namespaces -o=wide @args }
function kgpowallowide { Write-Host "kubectl get pods --watch --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get pods --watch --all-namespaces -o=wide @args }
function kgdepwallowide { Write-Host "kubectl get deployment --watch --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get deployment --watch --all-namespaces -o=wide @args }
function kgsvcwallowide { Write-Host "kubectl get service --watch --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get service --watch --all-namespaces -o=wide @args }
function kgingwallowide { Write-Host "kubectl get ingress --watch --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get ingress --watch --all-namespaces -o=wide @args }
function kgcmwallowide { Write-Host "kubectl get configmap --watch --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get configmap --watch --all-namespaces -o=wide @args }
function kgsecwallowide { Write-Host "kubectl get secret --watch --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get secret --watch --all-namespaces -o=wide @args }
function kgnswallowide { Write-Host "kubectl get namespaces --watch --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get namespaces --watch --all-namespaces -o=wide @args }
function kgslwowide { Write-Host "kubectl get --show-labels --watch -o=wide $args" -ForegroundColor Magenta; k get --show-labels --watch -o=wide @args }
function ksysgslwowide { Write-Host "kubectl --namespace=kube-system get --show-labels --watch -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get --show-labels --watch -o=wide @args }
function kgposlwowide { Write-Host "kubectl get pods --show-labels --watch -o=wide $args" -ForegroundColor Magenta; k get pods --show-labels --watch -o=wide @args }
function ksysgposlwowide { Write-Host "kubectl --namespace=kube-system get pods --show-labels --watch -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --show-labels --watch -o=wide @args }
function kgdepslwowide { Write-Host "kubectl get deployment --show-labels --watch -o=wide $args" -ForegroundColor Magenta; k get deployment --show-labels --watch -o=wide @args }
function ksysgdepslwowide { Write-Host "kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --show-labels --watch -o=wide @args }
function kgwowidesl { Write-Host "kubectl get --watch -o=wide --show-labels $args" -ForegroundColor Magenta; k get --watch -o=wide --show-labels @args }
function ksysgwowidesl { Write-Host "kubectl --namespace=kube-system get --watch -o=wide --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch -o=wide --show-labels @args }
function kgpowowidesl { Write-Host "kubectl get pods --watch -o=wide --show-labels $args" -ForegroundColor Magenta; k get pods --watch -o=wide --show-labels @args }
function ksysgpowowidesl { Write-Host "kubectl --namespace=kube-system get pods --watch -o=wide --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch -o=wide --show-labels @args }
function kgdepwowidesl { Write-Host "kubectl get deployment --watch -o=wide --show-labels $args" -ForegroundColor Magenta; k get deployment --watch -o=wide --show-labels @args }
function ksysgdepwowidesl { Write-Host "kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch -o=wide --show-labels @args }
function kgwslowide { Write-Host "kubectl get --watch --show-labels -o=wide $args" -ForegroundColor Magenta; k get --watch --show-labels -o=wide @args }
function ksysgwslowide { Write-Host "kubectl --namespace=kube-system get --watch --show-labels -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch --show-labels -o=wide @args }
function kgpowslowide { Write-Host "kubectl get pods --watch --show-labels -o=wide $args" -ForegroundColor Magenta; k get pods --watch --show-labels -o=wide @args }
function ksysgpowslowide { Write-Host "kubectl --namespace=kube-system get pods --watch --show-labels -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch --show-labels -o=wide @args }
function kgdepwslowide { Write-Host "kubectl get deployment --watch --show-labels -o=wide $args" -ForegroundColor Magenta; k get deployment --watch --show-labels -o=wide @args }
function ksysgdepwslowide { Write-Host "kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch --show-labels -o=wide @args }
function kgallwojson { Write-Host "kubectl get --all-namespaces --watch -o=json $args" -ForegroundColor Magenta; k get --all-namespaces --watch -o=json @args }
function kgpoallwojson { Write-Host "kubectl get pods --all-namespaces --watch -o=json $args" -ForegroundColor Magenta; k get pods --all-namespaces --watch -o=json @args }
function kgdepallwojson { Write-Host "kubectl get deployment --all-namespaces --watch -o=json $args" -ForegroundColor Magenta; k get deployment --all-namespaces --watch -o=json @args }
function kgsvcallwojson { Write-Host "kubectl get service --all-namespaces --watch -o=json $args" -ForegroundColor Magenta; k get service --all-namespaces --watch -o=json @args }
function kgingallwojson { Write-Host "kubectl get ingress --all-namespaces --watch -o=json $args" -ForegroundColor Magenta; k get ingress --all-namespaces --watch -o=json @args }
function kgcmallwojson { Write-Host "kubectl get configmap --all-namespaces --watch -o=json $args" -ForegroundColor Magenta; k get configmap --all-namespaces --watch -o=json @args }
function kgsecallwojson { Write-Host "kubectl get secret --all-namespaces --watch -o=json $args" -ForegroundColor Magenta; k get secret --all-namespaces --watch -o=json @args }
function kgnsallwojson { Write-Host "kubectl get namespaces --all-namespaces --watch -o=json $args" -ForegroundColor Magenta; k get namespaces --all-namespaces --watch -o=json @args }
function kgwojsonall { Write-Host "kubectl get --watch -o=json --all-namespaces $args" -ForegroundColor Magenta; k get --watch -o=json --all-namespaces @args }
function kgpowojsonall { Write-Host "kubectl get pods --watch -o=json --all-namespaces $args" -ForegroundColor Magenta; k get pods --watch -o=json --all-namespaces @args }
function kgdepwojsonall { Write-Host "kubectl get deployment --watch -o=json --all-namespaces $args" -ForegroundColor Magenta; k get deployment --watch -o=json --all-namespaces @args }
function kgsvcwojsonall { Write-Host "kubectl get service --watch -o=json --all-namespaces $args" -ForegroundColor Magenta; k get service --watch -o=json --all-namespaces @args }
function kgingwojsonall { Write-Host "kubectl get ingress --watch -o=json --all-namespaces $args" -ForegroundColor Magenta; k get ingress --watch -o=json --all-namespaces @args }
function kgcmwojsonall { Write-Host "kubectl get configmap --watch -o=json --all-namespaces $args" -ForegroundColor Magenta; k get configmap --watch -o=json --all-namespaces @args }
function kgsecwojsonall { Write-Host "kubectl get secret --watch -o=json --all-namespaces $args" -ForegroundColor Magenta; k get secret --watch -o=json --all-namespaces @args }
function kgnswojsonall { Write-Host "kubectl get namespaces --watch -o=json --all-namespaces $args" -ForegroundColor Magenta; k get namespaces --watch -o=json --all-namespaces @args }
function kgwallojson { Write-Host "kubectl get --watch --all-namespaces -o=json $args" -ForegroundColor Magenta; k get --watch --all-namespaces -o=json @args }
function kgpowallojson { Write-Host "kubectl get pods --watch --all-namespaces -o=json $args" -ForegroundColor Magenta; k get pods --watch --all-namespaces -o=json @args }
function kgdepwallojson { Write-Host "kubectl get deployment --watch --all-namespaces -o=json $args" -ForegroundColor Magenta; k get deployment --watch --all-namespaces -o=json @args }
function kgsvcwallojson { Write-Host "kubectl get service --watch --all-namespaces -o=json $args" -ForegroundColor Magenta; k get service --watch --all-namespaces -o=json @args }
function kgingwallojson { Write-Host "kubectl get ingress --watch --all-namespaces -o=json $args" -ForegroundColor Magenta; k get ingress --watch --all-namespaces -o=json @args }
function kgcmwallojson { Write-Host "kubectl get configmap --watch --all-namespaces -o=json $args" -ForegroundColor Magenta; k get configmap --watch --all-namespaces -o=json @args }
function kgsecwallojson { Write-Host "kubectl get secret --watch --all-namespaces -o=json $args" -ForegroundColor Magenta; k get secret --watch --all-namespaces -o=json @args }
function kgnswallojson { Write-Host "kubectl get namespaces --watch --all-namespaces -o=json $args" -ForegroundColor Magenta; k get namespaces --watch --all-namespaces -o=json @args }
function kgallslw { Write-Host "kubectl get --all-namespaces --show-labels --watch $args" -ForegroundColor Magenta; k get --all-namespaces --show-labels --watch @args }
function kgpoallslw { Write-Host "kubectl get pods --all-namespaces --show-labels --watch $args" -ForegroundColor Magenta; k get pods --all-namespaces --show-labels --watch @args }
function kgdepallslw { Write-Host "kubectl get deployment --all-namespaces --show-labels --watch $args" -ForegroundColor Magenta; k get deployment --all-namespaces --show-labels --watch @args }
function kgallwsl { Write-Host "kubectl get --all-namespaces --watch --show-labels $args" -ForegroundColor Magenta; k get --all-namespaces --watch --show-labels @args }
function kgpoallwsl { Write-Host "kubectl get pods --all-namespaces --watch --show-labels $args" -ForegroundColor Magenta; k get pods --all-namespaces --watch --show-labels @args }
function kgdepallwsl { Write-Host "kubectl get deployment --all-namespaces --watch --show-labels $args" -ForegroundColor Magenta; k get deployment --all-namespaces --watch --show-labels @args }
function kgslallw { Write-Host "kubectl get --show-labels --all-namespaces --watch $args" -ForegroundColor Magenta; k get --show-labels --all-namespaces --watch @args }
function kgposlallw { Write-Host "kubectl get pods --show-labels --all-namespaces --watch $args" -ForegroundColor Magenta; k get pods --show-labels --all-namespaces --watch @args }
function kgdepslallw { Write-Host "kubectl get deployment --show-labels --all-namespaces --watch $args" -ForegroundColor Magenta; k get deployment --show-labels --all-namespaces --watch @args }
function kgslwall { Write-Host "kubectl get --show-labels --watch --all-namespaces $args" -ForegroundColor Magenta; k get --show-labels --watch --all-namespaces @args }
function kgposlwall { Write-Host "kubectl get pods --show-labels --watch --all-namespaces $args" -ForegroundColor Magenta; k get pods --show-labels --watch --all-namespaces @args }
function kgdepslwall { Write-Host "kubectl get deployment --show-labels --watch --all-namespaces $args" -ForegroundColor Magenta; k get deployment --show-labels --watch --all-namespaces @args }
function kgwallsl { Write-Host "kubectl get --watch --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get --watch --all-namespaces --show-labels @args }
function kgpowallsl { Write-Host "kubectl get pods --watch --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get pods --watch --all-namespaces --show-labels @args }
function kgdepwallsl { Write-Host "kubectl get deployment --watch --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get deployment --watch --all-namespaces --show-labels @args }
function kgwslall { Write-Host "kubectl get --watch --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get --watch --show-labels --all-namespaces @args }
function kgpowslall { Write-Host "kubectl get pods --watch --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get pods --watch --show-labels --all-namespaces @args }
function kgdepwslall { Write-Host "kubectl get deployment --watch --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get deployment --watch --show-labels --all-namespaces @args }
function kgallslwowide { Write-Host "kubectl get --all-namespaces --show-labels --watch -o=wide $args" -ForegroundColor Magenta; k get --all-namespaces --show-labels --watch -o=wide @args }
function kgpoallslwowide { Write-Host "kubectl get pods --all-namespaces --show-labels --watch -o=wide $args" -ForegroundColor Magenta; k get pods --all-namespaces --show-labels --watch -o=wide @args }
function kgdepallslwowide { Write-Host "kubectl get deployment --all-namespaces --show-labels --watch -o=wide $args" -ForegroundColor Magenta; k get deployment --all-namespaces --show-labels --watch -o=wide @args }
function kgallwowidesl { Write-Host "kubectl get --all-namespaces --watch -o=wide --show-labels $args" -ForegroundColor Magenta; k get --all-namespaces --watch -o=wide --show-labels @args }
function kgpoallwowidesl { Write-Host "kubectl get pods --all-namespaces --watch -o=wide --show-labels $args" -ForegroundColor Magenta; k get pods --all-namespaces --watch -o=wide --show-labels @args }
function kgdepallwowidesl { Write-Host "kubectl get deployment --all-namespaces --watch -o=wide --show-labels $args" -ForegroundColor Magenta; k get deployment --all-namespaces --watch -o=wide --show-labels @args }
function kgallwslowide { Write-Host "kubectl get --all-namespaces --watch --show-labels -o=wide $args" -ForegroundColor Magenta; k get --all-namespaces --watch --show-labels -o=wide @args }
function kgpoallwslowide { Write-Host "kubectl get pods --all-namespaces --watch --show-labels -o=wide $args" -ForegroundColor Magenta; k get pods --all-namespaces --watch --show-labels -o=wide @args }
function kgdepallwslowide { Write-Host "kubectl get deployment --all-namespaces --watch --show-labels -o=wide $args" -ForegroundColor Magenta; k get deployment --all-namespaces --watch --show-labels -o=wide @args }
function kgslallwowide { Write-Host "kubectl get --show-labels --all-namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get --show-labels --all-namespaces --watch -o=wide @args }
function kgposlallwowide { Write-Host "kubectl get pods --show-labels --all-namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get pods --show-labels --all-namespaces --watch -o=wide @args }
function kgdepslallwowide { Write-Host "kubectl get deployment --show-labels --all-namespaces --watch -o=wide $args" -ForegroundColor Magenta; k get deployment --show-labels --all-namespaces --watch -o=wide @args }
function kgslwowideall { Write-Host "kubectl get --show-labels --watch -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get --show-labels --watch -o=wide --all-namespaces @args }
function kgposlwowideall { Write-Host "kubectl get pods --show-labels --watch -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get pods --show-labels --watch -o=wide --all-namespaces @args }
function kgdepslwowideall { Write-Host "kubectl get deployment --show-labels --watch -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get deployment --show-labels --watch -o=wide --all-namespaces @args }
function kgslwallowide { Write-Host "kubectl get --show-labels --watch --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get --show-labels --watch --all-namespaces -o=wide @args }
function kgposlwallowide { Write-Host "kubectl get pods --show-labels --watch --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get pods --show-labels --watch --all-namespaces -o=wide @args }
function kgdepslwallowide { Write-Host "kubectl get deployment --show-labels --watch --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get deployment --show-labels --watch --all-namespaces -o=wide @args }
function kgwowideallsl { Write-Host "kubectl get --watch -o=wide --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get --watch -o=wide --all-namespaces --show-labels @args }
function kgpowowideallsl { Write-Host "kubectl get pods --watch -o=wide --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get pods --watch -o=wide --all-namespaces --show-labels @args }
function kgdepwowideallsl { Write-Host "kubectl get deployment --watch -o=wide --all-namespaces --show-labels $args" -ForegroundColor Magenta; k get deployment --watch -o=wide --all-namespaces --show-labels @args }
function kgwowideslall { Write-Host "kubectl get --watch -o=wide --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get --watch -o=wide --show-labels --all-namespaces @args }
function kgpowowideslall { Write-Host "kubectl get pods --watch -o=wide --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get pods --watch -o=wide --show-labels --all-namespaces @args }
function kgdepwowideslall { Write-Host "kubectl get deployment --watch -o=wide --show-labels --all-namespaces $args" -ForegroundColor Magenta; k get deployment --watch -o=wide --show-labels --all-namespaces @args }
function kgwallowidesl { Write-Host "kubectl get --watch --all-namespaces -o=wide --show-labels $args" -ForegroundColor Magenta; k get --watch --all-namespaces -o=wide --show-labels @args }
function kgpowallowidesl { Write-Host "kubectl get pods --watch --all-namespaces -o=wide --show-labels $args" -ForegroundColor Magenta; k get pods --watch --all-namespaces -o=wide --show-labels @args }
function kgdepwallowidesl { Write-Host "kubectl get deployment --watch --all-namespaces -o=wide --show-labels $args" -ForegroundColor Magenta; k get deployment --watch --all-namespaces -o=wide --show-labels @args }
function kgwallslowide { Write-Host "kubectl get --watch --all-namespaces --show-labels -o=wide $args" -ForegroundColor Magenta; k get --watch --all-namespaces --show-labels -o=wide @args }
function kgpowallslowide { Write-Host "kubectl get pods --watch --all-namespaces --show-labels -o=wide $args" -ForegroundColor Magenta; k get pods --watch --all-namespaces --show-labels -o=wide @args }
function kgdepwallslowide { Write-Host "kubectl get deployment --watch --all-namespaces --show-labels -o=wide $args" -ForegroundColor Magenta; k get deployment --watch --all-namespaces --show-labels -o=wide @args }
function kgwslowideall { Write-Host "kubectl get --watch --show-labels -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get --watch --show-labels -o=wide --all-namespaces @args }
function kgpowslowideall { Write-Host "kubectl get pods --watch --show-labels -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get pods --watch --show-labels -o=wide --all-namespaces @args }
function kgdepwslowideall { Write-Host "kubectl get deployment --watch --show-labels -o=wide --all-namespaces $args" -ForegroundColor Magenta; k get deployment --watch --show-labels -o=wide --all-namespaces @args }
function kgwslallowide { Write-Host "kubectl get --watch --show-labels --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get --watch --show-labels --all-namespaces -o=wide @args }
function kgpowslallowide { Write-Host "kubectl get pods --watch --show-labels --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get pods --watch --show-labels --all-namespaces -o=wide @args }
function kgdepwslallowide { Write-Host "kubectl get deployment --watch --show-labels --all-namespaces -o=wide $args" -ForegroundColor Magenta; k get deployment --watch --show-labels --all-namespaces -o=wide @args }
function kgf { Write-Host "kubectl get --recursive -f $args" -ForegroundColor Magenta; k get --recursive -f @args }
function kdf { Write-Host "kubectl describe --recursive -f $args" -ForegroundColor Magenta; k describe --recursive -f @args }
function krmf { Write-Host "kubectl delete --recursive -f $args" -ForegroundColor Magenta; k delete --recursive -f @args }
function kgoyamlf { Write-Host "kubectl get -o=yaml --recursive -f $args" -ForegroundColor Magenta; k get -o=yaml --recursive -f @args }
function kgowidef { Write-Host "kubectl get -o=wide --recursive -f $args" -ForegroundColor Magenta; k get -o=wide --recursive -f @args }
function kgojsonf { Write-Host "kubectl get -o=json --recursive -f $args" -ForegroundColor Magenta; k get -o=json --recursive -f @args }
function kgslf { Write-Host "kubectl get --show-labels --recursive -f $args" -ForegroundColor Magenta; k get --show-labels --recursive -f @args }
function kgwf { Write-Host "kubectl get --watch --recursive -f $args" -ForegroundColor Magenta; k get --watch --recursive -f @args }
function kgwoyamlf { Write-Host "kubectl get --watch -o=yaml --recursive -f $args" -ForegroundColor Magenta; k get --watch -o=yaml --recursive -f @args }
function kgowideslf { Write-Host "kubectl get -o=wide --show-labels --recursive -f $args" -ForegroundColor Magenta; k get -o=wide --show-labels --recursive -f @args }
function kgslowidef { Write-Host "kubectl get --show-labels -o=wide --recursive -f $args" -ForegroundColor Magenta; k get --show-labels -o=wide --recursive -f @args }
function kgwowidef { Write-Host "kubectl get --watch -o=wide --recursive -f $args" -ForegroundColor Magenta; k get --watch -o=wide --recursive -f @args }
function kgwojsonf { Write-Host "kubectl get --watch -o=json --recursive -f $args" -ForegroundColor Magenta; k get --watch -o=json --recursive -f @args }
function kgslwf { Write-Host "kubectl get --show-labels --watch --recursive -f $args" -ForegroundColor Magenta; k get --show-labels --watch --recursive -f @args }
function kgwslf { Write-Host "kubectl get --watch --show-labels --recursive -f $args" -ForegroundColor Magenta; k get --watch --show-labels --recursive -f @args }
function kgslwowidef { Write-Host "kubectl get --show-labels --watch -o=wide --recursive -f $args" -ForegroundColor Magenta; k get --show-labels --watch -o=wide --recursive -f @args }
function kgwowideslf { Write-Host "kubectl get --watch -o=wide --show-labels --recursive -f $args" -ForegroundColor Magenta; k get --watch -o=wide --show-labels --recursive -f @args }
function kgwslowidef { Write-Host "kubectl get --watch --show-labels -o=wide --recursive -f $args" -ForegroundColor Magenta; k get --watch --show-labels -o=wide --recursive -f @args }
function kgl { Write-Host "kubectl get -l $args" -ForegroundColor Magenta; k get -l @args }
function ksysgl { Write-Host "kubectl --namespace=kube-system get -l $args" -ForegroundColor Magenta; k --namespace=kube-system get -l @args }
function kdl { Write-Host "kubectl describe -l $args" -ForegroundColor Magenta; k describe -l @args }
function ksysdl { Write-Host "kubectl --namespace=kube-system describe -l $args" -ForegroundColor Magenta; k --namespace=kube-system describe -l @args }
function krml { Write-Host "kubectl delete -l $args" -ForegroundColor Magenta; k delete -l @args }
function ksysrml { Write-Host "kubectl --namespace=kube-system delete -l $args" -ForegroundColor Magenta; k --namespace=kube-system delete -l @args }
function kgpol { Write-Host "kubectl get pods -l $args" -ForegroundColor Magenta; k get pods -l @args }
function ksysgpol { Write-Host "kubectl --namespace=kube-system get pods -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods -l @args }
function kdpol { Write-Host "kubectl describe pods -l $args" -ForegroundColor Magenta; k describe pods -l @args }
function ksysdpol { Write-Host "kubectl --namespace=kube-system describe pods -l $args" -ForegroundColor Magenta; k --namespace=kube-system describe pods -l @args }
function krmpol { Write-Host "kubectl delete pods -l $args" -ForegroundColor Magenta; k delete pods -l @args }
function ksysrmpol { Write-Host "kubectl --namespace=kube-system delete pods -l $args" -ForegroundColor Magenta; k --namespace=kube-system delete pods -l @args }
function kgdepl { Write-Host "kubectl get deployment -l $args" -ForegroundColor Magenta; k get deployment -l @args }
function ksysgdepl { Write-Host "kubectl --namespace=kube-system get deployment -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment -l @args }
function kddepl { Write-Host "kubectl describe deployment -l $args" -ForegroundColor Magenta; k describe deployment -l @args }
function ksysddepl { Write-Host "kubectl --namespace=kube-system describe deployment -l $args" -ForegroundColor Magenta; k --namespace=kube-system describe deployment -l @args }
function krmdepl { Write-Host "kubectl delete deployment -l $args" -ForegroundColor Magenta; k delete deployment -l @args }
function ksysrmdepl { Write-Host "kubectl --namespace=kube-system delete deployment -l $args" -ForegroundColor Magenta; k --namespace=kube-system delete deployment -l @args }
function kgsvcl { Write-Host "kubectl get service -l $args" -ForegroundColor Magenta; k get service -l @args }
function ksysgsvcl { Write-Host "kubectl --namespace=kube-system get service -l $args" -ForegroundColor Magenta; k --namespace=kube-system get service -l @args }
function kdsvcl { Write-Host "kubectl describe service -l $args" -ForegroundColor Magenta; k describe service -l @args }
function ksysdsvcl { Write-Host "kubectl --namespace=kube-system describe service -l $args" -ForegroundColor Magenta; k --namespace=kube-system describe service -l @args }
function krmsvcl { Write-Host "kubectl delete service -l $args" -ForegroundColor Magenta; k delete service -l @args }
function ksysrmsvcl { Write-Host "kubectl --namespace=kube-system delete service -l $args" -ForegroundColor Magenta; k --namespace=kube-system delete service -l @args }
function kgingl { Write-Host "kubectl get ingress -l $args" -ForegroundColor Magenta; k get ingress -l @args }
function ksysgingl { Write-Host "kubectl --namespace=kube-system get ingress -l $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress -l @args }
function kdingl { Write-Host "kubectl describe ingress -l $args" -ForegroundColor Magenta; k describe ingress -l @args }
function ksysdingl { Write-Host "kubectl --namespace=kube-system describe ingress -l $args" -ForegroundColor Magenta; k --namespace=kube-system describe ingress -l @args }
function krmingl { Write-Host "kubectl delete ingress -l $args" -ForegroundColor Magenta; k delete ingress -l @args }
function ksysrmingl { Write-Host "kubectl --namespace=kube-system delete ingress -l $args" -ForegroundColor Magenta; k --namespace=kube-system delete ingress -l @args }
function kgcml { Write-Host "kubectl get configmap -l $args" -ForegroundColor Magenta; k get configmap -l @args }
function ksysgcml { Write-Host "kubectl --namespace=kube-system get configmap -l $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap -l @args }
function kdcml { Write-Host "kubectl describe configmap -l $args" -ForegroundColor Magenta; k describe configmap -l @args }
function ksysdcml { Write-Host "kubectl --namespace=kube-system describe configmap -l $args" -ForegroundColor Magenta; k --namespace=kube-system describe configmap -l @args }
function krmcml { Write-Host "kubectl delete configmap -l $args" -ForegroundColor Magenta; k delete configmap -l @args }
function ksysrmcml { Write-Host "kubectl --namespace=kube-system delete configmap -l $args" -ForegroundColor Magenta; k --namespace=kube-system delete configmap -l @args }
function kgsecl { Write-Host "kubectl get secret -l $args" -ForegroundColor Magenta; k get secret -l @args }
function ksysgsecl { Write-Host "kubectl --namespace=kube-system get secret -l $args" -ForegroundColor Magenta; k --namespace=kube-system get secret -l @args }
function kdsecl { Write-Host "kubectl describe secret -l $args" -ForegroundColor Magenta; k describe secret -l @args }
function ksysdsecl { Write-Host "kubectl --namespace=kube-system describe secret -l $args" -ForegroundColor Magenta; k --namespace=kube-system describe secret -l @args }
function krmsecl { Write-Host "kubectl delete secret -l $args" -ForegroundColor Magenta; k delete secret -l @args }
function ksysrmsecl { Write-Host "kubectl --namespace=kube-system delete secret -l $args" -ForegroundColor Magenta; k --namespace=kube-system delete secret -l @args }
function kgnol { Write-Host "kubectl get nodes -l $args" -ForegroundColor Magenta; k get nodes -l @args }
function kdnol { Write-Host "kubectl describe nodes -l $args" -ForegroundColor Magenta; k describe nodes -l @args }
function kgnsl { Write-Host "kubectl get namespaces -l $args" -ForegroundColor Magenta; k get namespaces -l @args }
function kdnsl { Write-Host "kubectl describe namespaces -l $args" -ForegroundColor Magenta; k describe namespaces -l @args }
function krmnsl { Write-Host "kubectl delete namespaces -l $args" -ForegroundColor Magenta; k delete namespaces -l @args }
function kgoyamll { Write-Host "kubectl get -o=yaml -l $args" -ForegroundColor Magenta; k get -o=yaml -l @args }
function ksysgoyamll { Write-Host "kubectl --namespace=kube-system get -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get -o=yaml -l @args }
function kgpooyamll { Write-Host "kubectl get pods -o=yaml -l $args" -ForegroundColor Magenta; k get pods -o=yaml -l @args }
function ksysgpooyamll { Write-Host "kubectl --namespace=kube-system get pods -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods -o=yaml -l @args }
function kgdepoyamll { Write-Host "kubectl get deployment -o=yaml -l $args" -ForegroundColor Magenta; k get deployment -o=yaml -l @args }
function ksysgdepoyamll { Write-Host "kubectl --namespace=kube-system get deployment -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment -o=yaml -l @args }
function kgsvcoyamll { Write-Host "kubectl get service -o=yaml -l $args" -ForegroundColor Magenta; k get service -o=yaml -l @args }
function ksysgsvcoyamll { Write-Host "kubectl --namespace=kube-system get service -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get service -o=yaml -l @args }
function kgingoyamll { Write-Host "kubectl get ingress -o=yaml -l $args" -ForegroundColor Magenta; k get ingress -o=yaml -l @args }
function ksysgingoyamll { Write-Host "kubectl --namespace=kube-system get ingress -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress -o=yaml -l @args }
function kgcmoyamll { Write-Host "kubectl get configmap -o=yaml -l $args" -ForegroundColor Magenta; k get configmap -o=yaml -l @args }
function ksysgcmoyamll { Write-Host "kubectl --namespace=kube-system get configmap -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap -o=yaml -l @args }
function kgsecoyamll { Write-Host "kubectl get secret -o=yaml -l $args" -ForegroundColor Magenta; k get secret -o=yaml -l @args }
function ksysgsecoyamll { Write-Host "kubectl --namespace=kube-system get secret -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get secret -o=yaml -l @args }
function kgnooyamll { Write-Host "kubectl get nodes -o=yaml -l $args" -ForegroundColor Magenta; k get nodes -o=yaml -l @args }
function kgnsoyamll { Write-Host "kubectl get namespaces -o=yaml -l $args" -ForegroundColor Magenta; k get namespaces -o=yaml -l @args }
function kgowidel { Write-Host "kubectl get -o=wide -l $args" -ForegroundColor Magenta; k get -o=wide -l @args }
function ksysgowidel { Write-Host "kubectl --namespace=kube-system get -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get -o=wide -l @args }
function kgpoowidel { Write-Host "kubectl get pods -o=wide -l $args" -ForegroundColor Magenta; k get pods -o=wide -l @args }
function ksysgpoowidel { Write-Host "kubectl --namespace=kube-system get pods -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods -o=wide -l @args }
function kgdepowidel { Write-Host "kubectl get deployment -o=wide -l $args" -ForegroundColor Magenta; k get deployment -o=wide -l @args }
function ksysgdepowidel { Write-Host "kubectl --namespace=kube-system get deployment -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment -o=wide -l @args }
function kgsvcowidel { Write-Host "kubectl get service -o=wide -l $args" -ForegroundColor Magenta; k get service -o=wide -l @args }
function ksysgsvcowidel { Write-Host "kubectl --namespace=kube-system get service -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get service -o=wide -l @args }
function kgingowidel { Write-Host "kubectl get ingress -o=wide -l $args" -ForegroundColor Magenta; k get ingress -o=wide -l @args }
function ksysgingowidel { Write-Host "kubectl --namespace=kube-system get ingress -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress -o=wide -l @args }
function kgcmowidel { Write-Host "kubectl get configmap -o=wide -l $args" -ForegroundColor Magenta; k get configmap -o=wide -l @args }
function ksysgcmowidel { Write-Host "kubectl --namespace=kube-system get configmap -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap -o=wide -l @args }
function kgsecowidel { Write-Host "kubectl get secret -o=wide -l $args" -ForegroundColor Magenta; k get secret -o=wide -l @args }
function ksysgsecowidel { Write-Host "kubectl --namespace=kube-system get secret -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get secret -o=wide -l @args }
function kgnoowidel { Write-Host "kubectl get nodes -o=wide -l $args" -ForegroundColor Magenta; k get nodes -o=wide -l @args }
function kgnsowidel { Write-Host "kubectl get namespaces -o=wide -l $args" -ForegroundColor Magenta; k get namespaces -o=wide -l @args }
function kgojsonl { Write-Host "kubectl get -o=json -l $args" -ForegroundColor Magenta; k get -o=json -l @args }
function ksysgojsonl { Write-Host "kubectl --namespace=kube-system get -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get -o=json -l @args }
function kgpoojsonl { Write-Host "kubectl get pods -o=json -l $args" -ForegroundColor Magenta; k get pods -o=json -l @args }
function ksysgpoojsonl { Write-Host "kubectl --namespace=kube-system get pods -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods -o=json -l @args }
function kgdepojsonl { Write-Host "kubectl get deployment -o=json -l $args" -ForegroundColor Magenta; k get deployment -o=json -l @args }
function ksysgdepojsonl { Write-Host "kubectl --namespace=kube-system get deployment -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment -o=json -l @args }
function kgsvcojsonl { Write-Host "kubectl get service -o=json -l $args" -ForegroundColor Magenta; k get service -o=json -l @args }
function ksysgsvcojsonl { Write-Host "kubectl --namespace=kube-system get service -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get service -o=json -l @args }
function kgingojsonl { Write-Host "kubectl get ingress -o=json -l $args" -ForegroundColor Magenta; k get ingress -o=json -l @args }
function ksysgingojsonl { Write-Host "kubectl --namespace=kube-system get ingress -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress -o=json -l @args }
function kgcmojsonl { Write-Host "kubectl get configmap -o=json -l $args" -ForegroundColor Magenta; k get configmap -o=json -l @args }
function ksysgcmojsonl { Write-Host "kubectl --namespace=kube-system get configmap -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap -o=json -l @args }
function kgsecojsonl { Write-Host "kubectl get secret -o=json -l $args" -ForegroundColor Magenta; k get secret -o=json -l @args }
function ksysgsecojsonl { Write-Host "kubectl --namespace=kube-system get secret -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get secret -o=json -l @args }
function kgnoojsonl { Write-Host "kubectl get nodes -o=json -l $args" -ForegroundColor Magenta; k get nodes -o=json -l @args }
function kgnsojsonl { Write-Host "kubectl get namespaces -o=json -l $args" -ForegroundColor Magenta; k get namespaces -o=json -l @args }
function kgsll { Write-Host "kubectl get --show-labels -l $args" -ForegroundColor Magenta; k get --show-labels -l @args }
function ksysgsll { Write-Host "kubectl --namespace=kube-system get --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get --show-labels -l @args }
function kgposll { Write-Host "kubectl get pods --show-labels -l $args" -ForegroundColor Magenta; k get pods --show-labels -l @args }
function ksysgposll { Write-Host "kubectl --namespace=kube-system get pods --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --show-labels -l @args }
function kgdepsll { Write-Host "kubectl get deployment --show-labels -l $args" -ForegroundColor Magenta; k get deployment --show-labels -l @args }
function ksysgdepsll { Write-Host "kubectl --namespace=kube-system get deployment --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --show-labels -l @args }
function kgwl { Write-Host "kubectl get --watch -l $args" -ForegroundColor Magenta; k get --watch -l @args }
function ksysgwl { Write-Host "kubectl --namespace=kube-system get --watch -l $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch -l @args }
function kgpowl { Write-Host "kubectl get pods --watch -l $args" -ForegroundColor Magenta; k get pods --watch -l @args }
function ksysgpowl { Write-Host "kubectl --namespace=kube-system get pods --watch -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch -l @args }
function kgdepwl { Write-Host "kubectl get deployment --watch -l $args" -ForegroundColor Magenta; k get deployment --watch -l @args }
function ksysgdepwl { Write-Host "kubectl --namespace=kube-system get deployment --watch -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch -l @args }
function kgsvcwl { Write-Host "kubectl get service --watch -l $args" -ForegroundColor Magenta; k get service --watch -l @args }
function ksysgsvcwl { Write-Host "kubectl --namespace=kube-system get service --watch -l $args" -ForegroundColor Magenta; k --namespace=kube-system get service --watch -l @args }
function kgingwl { Write-Host "kubectl get ingress --watch -l $args" -ForegroundColor Magenta; k get ingress --watch -l @args }
function ksysgingwl { Write-Host "kubectl --namespace=kube-system get ingress --watch -l $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress --watch -l @args }
function kgcmwl { Write-Host "kubectl get configmap --watch -l $args" -ForegroundColor Magenta; k get configmap --watch -l @args }
function ksysgcmwl { Write-Host "kubectl --namespace=kube-system get configmap --watch -l $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap --watch -l @args }
function kgsecwl { Write-Host "kubectl get secret --watch -l $args" -ForegroundColor Magenta; k get secret --watch -l @args }
function ksysgsecwl { Write-Host "kubectl --namespace=kube-system get secret --watch -l $args" -ForegroundColor Magenta; k --namespace=kube-system get secret --watch -l @args }
function kgnowl { Write-Host "kubectl get nodes --watch -l $args" -ForegroundColor Magenta; k get nodes --watch -l @args }
function kgnswl { Write-Host "kubectl get namespaces --watch -l $args" -ForegroundColor Magenta; k get namespaces --watch -l @args }
function kgwoyamll { Write-Host "kubectl get --watch -o=yaml -l $args" -ForegroundColor Magenta; k get --watch -o=yaml -l @args }
function ksysgwoyamll { Write-Host "kubectl --namespace=kube-system get --watch -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch -o=yaml -l @args }
function kgpowoyamll { Write-Host "kubectl get pods --watch -o=yaml -l $args" -ForegroundColor Magenta; k get pods --watch -o=yaml -l @args }
function ksysgpowoyamll { Write-Host "kubectl --namespace=kube-system get pods --watch -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch -o=yaml -l @args }
function kgdepwoyamll { Write-Host "kubectl get deployment --watch -o=yaml -l $args" -ForegroundColor Magenta; k get deployment --watch -o=yaml -l @args }
function ksysgdepwoyamll { Write-Host "kubectl --namespace=kube-system get deployment --watch -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch -o=yaml -l @args }
function kgsvcwoyamll { Write-Host "kubectl get service --watch -o=yaml -l $args" -ForegroundColor Magenta; k get service --watch -o=yaml -l @args }
function ksysgsvcwoyamll { Write-Host "kubectl --namespace=kube-system get service --watch -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get service --watch -o=yaml -l @args }
function kgingwoyamll { Write-Host "kubectl get ingress --watch -o=yaml -l $args" -ForegroundColor Magenta; k get ingress --watch -o=yaml -l @args }
function ksysgingwoyamll { Write-Host "kubectl --namespace=kube-system get ingress --watch -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress --watch -o=yaml -l @args }
function kgcmwoyamll { Write-Host "kubectl get configmap --watch -o=yaml -l $args" -ForegroundColor Magenta; k get configmap --watch -o=yaml -l @args }
function ksysgcmwoyamll { Write-Host "kubectl --namespace=kube-system get configmap --watch -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap --watch -o=yaml -l @args }
function kgsecwoyamll { Write-Host "kubectl get secret --watch -o=yaml -l $args" -ForegroundColor Magenta; k get secret --watch -o=yaml -l @args }
function ksysgsecwoyamll { Write-Host "kubectl --namespace=kube-system get secret --watch -o=yaml -l $args" -ForegroundColor Magenta; k --namespace=kube-system get secret --watch -o=yaml -l @args }
function kgnowoyamll { Write-Host "kubectl get nodes --watch -o=yaml -l $args" -ForegroundColor Magenta; k get nodes --watch -o=yaml -l @args }
function kgnswoyamll { Write-Host "kubectl get namespaces --watch -o=yaml -l $args" -ForegroundColor Magenta; k get namespaces --watch -o=yaml -l @args }
function kgowidesll { Write-Host "kubectl get -o=wide --show-labels -l $args" -ForegroundColor Magenta; k get -o=wide --show-labels -l @args }
function ksysgowidesll { Write-Host "kubectl --namespace=kube-system get -o=wide --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get -o=wide --show-labels -l @args }
function kgpoowidesll { Write-Host "kubectl get pods -o=wide --show-labels -l $args" -ForegroundColor Magenta; k get pods -o=wide --show-labels -l @args }
function ksysgpoowidesll { Write-Host "kubectl --namespace=kube-system get pods -o=wide --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods -o=wide --show-labels -l @args }
function kgdepowidesll { Write-Host "kubectl get deployment -o=wide --show-labels -l $args" -ForegroundColor Magenta; k get deployment -o=wide --show-labels -l @args }
function ksysgdepowidesll { Write-Host "kubectl --namespace=kube-system get deployment -o=wide --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment -o=wide --show-labels -l @args }
function kgslowidel { Write-Host "kubectl get --show-labels -o=wide -l $args" -ForegroundColor Magenta; k get --show-labels -o=wide -l @args }
function ksysgslowidel { Write-Host "kubectl --namespace=kube-system get --show-labels -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get --show-labels -o=wide -l @args }
function kgposlowidel { Write-Host "kubectl get pods --show-labels -o=wide -l $args" -ForegroundColor Magenta; k get pods --show-labels -o=wide -l @args }
function ksysgposlowidel { Write-Host "kubectl --namespace=kube-system get pods --show-labels -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --show-labels -o=wide -l @args }
function kgdepslowidel { Write-Host "kubectl get deployment --show-labels -o=wide -l $args" -ForegroundColor Magenta; k get deployment --show-labels -o=wide -l @args }
function ksysgdepslowidel { Write-Host "kubectl --namespace=kube-system get deployment --show-labels -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --show-labels -o=wide -l @args }
function kgwowidel { Write-Host "kubectl get --watch -o=wide -l $args" -ForegroundColor Magenta; k get --watch -o=wide -l @args }
function ksysgwowidel { Write-Host "kubectl --namespace=kube-system get --watch -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch -o=wide -l @args }
function kgpowowidel { Write-Host "kubectl get pods --watch -o=wide -l $args" -ForegroundColor Magenta; k get pods --watch -o=wide -l @args }
function ksysgpowowidel { Write-Host "kubectl --namespace=kube-system get pods --watch -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch -o=wide -l @args }
function kgdepwowidel { Write-Host "kubectl get deployment --watch -o=wide -l $args" -ForegroundColor Magenta; k get deployment --watch -o=wide -l @args }
function ksysgdepwowidel { Write-Host "kubectl --namespace=kube-system get deployment --watch -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch -o=wide -l @args }
function kgsvcwowidel { Write-Host "kubectl get service --watch -o=wide -l $args" -ForegroundColor Magenta; k get service --watch -o=wide -l @args }
function ksysgsvcwowidel { Write-Host "kubectl --namespace=kube-system get service --watch -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get service --watch -o=wide -l @args }
function kgingwowidel { Write-Host "kubectl get ingress --watch -o=wide -l $args" -ForegroundColor Magenta; k get ingress --watch -o=wide -l @args }
function ksysgingwowidel { Write-Host "kubectl --namespace=kube-system get ingress --watch -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress --watch -o=wide -l @args }
function kgcmwowidel { Write-Host "kubectl get configmap --watch -o=wide -l $args" -ForegroundColor Magenta; k get configmap --watch -o=wide -l @args }
function ksysgcmwowidel { Write-Host "kubectl --namespace=kube-system get configmap --watch -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap --watch -o=wide -l @args }
function kgsecwowidel { Write-Host "kubectl get secret --watch -o=wide -l $args" -ForegroundColor Magenta; k get secret --watch -o=wide -l @args }
function ksysgsecwowidel { Write-Host "kubectl --namespace=kube-system get secret --watch -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get secret --watch -o=wide -l @args }
function kgnowowidel { Write-Host "kubectl get nodes --watch -o=wide -l $args" -ForegroundColor Magenta; k get nodes --watch -o=wide -l @args }
function kgnswowidel { Write-Host "kubectl get namespaces --watch -o=wide -l $args" -ForegroundColor Magenta; k get namespaces --watch -o=wide -l @args }
function kgwojsonl { Write-Host "kubectl get --watch -o=json -l $args" -ForegroundColor Magenta; k get --watch -o=json -l @args }
function ksysgwojsonl { Write-Host "kubectl --namespace=kube-system get --watch -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch -o=json -l @args }
function kgpowojsonl { Write-Host "kubectl get pods --watch -o=json -l $args" -ForegroundColor Magenta; k get pods --watch -o=json -l @args }
function ksysgpowojsonl { Write-Host "kubectl --namespace=kube-system get pods --watch -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch -o=json -l @args }
function kgdepwojsonl { Write-Host "kubectl get deployment --watch -o=json -l $args" -ForegroundColor Magenta; k get deployment --watch -o=json -l @args }
function ksysgdepwojsonl { Write-Host "kubectl --namespace=kube-system get deployment --watch -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch -o=json -l @args }
function kgsvcwojsonl { Write-Host "kubectl get service --watch -o=json -l $args" -ForegroundColor Magenta; k get service --watch -o=json -l @args }
function ksysgsvcwojsonl { Write-Host "kubectl --namespace=kube-system get service --watch -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get service --watch -o=json -l @args }
function kgingwojsonl { Write-Host "kubectl get ingress --watch -o=json -l $args" -ForegroundColor Magenta; k get ingress --watch -o=json -l @args }
function ksysgingwojsonl { Write-Host "kubectl --namespace=kube-system get ingress --watch -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get ingress --watch -o=json -l @args }
function kgcmwojsonl { Write-Host "kubectl get configmap --watch -o=json -l $args" -ForegroundColor Magenta; k get configmap --watch -o=json -l @args }
function ksysgcmwojsonl { Write-Host "kubectl --namespace=kube-system get configmap --watch -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get configmap --watch -o=json -l @args }
function kgsecwojsonl { Write-Host "kubectl get secret --watch -o=json -l $args" -ForegroundColor Magenta; k get secret --watch -o=json -l @args }
function ksysgsecwojsonl { Write-Host "kubectl --namespace=kube-system get secret --watch -o=json -l $args" -ForegroundColor Magenta; k --namespace=kube-system get secret --watch -o=json -l @args }
function kgnowojsonl { Write-Host "kubectl get nodes --watch -o=json -l $args" -ForegroundColor Magenta; k get nodes --watch -o=json -l @args }
function kgnswojsonl { Write-Host "kubectl get namespaces --watch -o=json -l $args" -ForegroundColor Magenta; k get namespaces --watch -o=json -l @args }
function kgslwl { Write-Host "kubectl get --show-labels --watch -l $args" -ForegroundColor Magenta; k get --show-labels --watch -l @args }
function ksysgslwl { Write-Host "kubectl --namespace=kube-system get --show-labels --watch -l $args" -ForegroundColor Magenta; k --namespace=kube-system get --show-labels --watch -l @args }
function kgposlwl { Write-Host "kubectl get pods --show-labels --watch -l $args" -ForegroundColor Magenta; k get pods --show-labels --watch -l @args }
function ksysgposlwl { Write-Host "kubectl --namespace=kube-system get pods --show-labels --watch -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --show-labels --watch -l @args }
function kgdepslwl { Write-Host "kubectl get deployment --show-labels --watch -l $args" -ForegroundColor Magenta; k get deployment --show-labels --watch -l @args }
function ksysgdepslwl { Write-Host "kubectl --namespace=kube-system get deployment --show-labels --watch -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --show-labels --watch -l @args }
function kgwsll { Write-Host "kubectl get --watch --show-labels -l $args" -ForegroundColor Magenta; k get --watch --show-labels -l @args }
function ksysgwsll { Write-Host "kubectl --namespace=kube-system get --watch --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch --show-labels -l @args }
function kgpowsll { Write-Host "kubectl get pods --watch --show-labels -l $args" -ForegroundColor Magenta; k get pods --watch --show-labels -l @args }
function ksysgpowsll { Write-Host "kubectl --namespace=kube-system get pods --watch --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch --show-labels -l @args }
function kgdepwsll { Write-Host "kubectl get deployment --watch --show-labels -l $args" -ForegroundColor Magenta; k get deployment --watch --show-labels -l @args }
function ksysgdepwsll { Write-Host "kubectl --namespace=kube-system get deployment --watch --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch --show-labels -l @args }
function kgslwowidel { Write-Host "kubectl get --show-labels --watch -o=wide -l $args" -ForegroundColor Magenta; k get --show-labels --watch -o=wide -l @args }
function ksysgslwowidel { Write-Host "kubectl --namespace=kube-system get --show-labels --watch -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get --show-labels --watch -o=wide -l @args }
function kgposlwowidel { Write-Host "kubectl get pods --show-labels --watch -o=wide -l $args" -ForegroundColor Magenta; k get pods --show-labels --watch -o=wide -l @args }
function ksysgposlwowidel { Write-Host "kubectl --namespace=kube-system get pods --show-labels --watch -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --show-labels --watch -o=wide -l @args }
function kgdepslwowidel { Write-Host "kubectl get deployment --show-labels --watch -o=wide -l $args" -ForegroundColor Magenta; k get deployment --show-labels --watch -o=wide -l @args }
function ksysgdepslwowidel { Write-Host "kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --show-labels --watch -o=wide -l @args }
function kgwowidesll { Write-Host "kubectl get --watch -o=wide --show-labels -l $args" -ForegroundColor Magenta; k get --watch -o=wide --show-labels -l @args }
function ksysgwowidesll { Write-Host "kubectl --namespace=kube-system get --watch -o=wide --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch -o=wide --show-labels -l @args }
function kgpowowidesll { Write-Host "kubectl get pods --watch -o=wide --show-labels -l $args" -ForegroundColor Magenta; k get pods --watch -o=wide --show-labels -l @args }
function ksysgpowowidesll { Write-Host "kubectl --namespace=kube-system get pods --watch -o=wide --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch -o=wide --show-labels -l @args }
function kgdepwowidesll { Write-Host "kubectl get deployment --watch -o=wide --show-labels -l $args" -ForegroundColor Magenta; k get deployment --watch -o=wide --show-labels -l @args }
function ksysgdepwowidesll { Write-Host "kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch -o=wide --show-labels -l @args }
function kgwslowidel { Write-Host "kubectl get --watch --show-labels -o=wide -l $args" -ForegroundColor Magenta; k get --watch --show-labels -o=wide -l @args }
function ksysgwslowidel { Write-Host "kubectl --namespace=kube-system get --watch --show-labels -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get --watch --show-labels -o=wide -l @args }
function kgpowslowidel { Write-Host "kubectl get pods --watch --show-labels -o=wide -l $args" -ForegroundColor Magenta; k get pods --watch --show-labels -o=wide -l @args }
function ksysgpowslowidel { Write-Host "kubectl --namespace=kube-system get pods --watch --show-labels -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get pods --watch --show-labels -o=wide -l @args }
function kgdepwslowidel { Write-Host "kubectl get deployment --watch --show-labels -o=wide -l $args" -ForegroundColor Magenta; k get deployment --watch --show-labels -o=wide -l @args }
function ksysgdepwslowidel { Write-Host "kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide -l $args" -ForegroundColor Magenta; k --namespace=kube-system get deployment --watch --show-labels -o=wide -l @args }
function kexn { Write-Host "kubectl exec -i -t --namespace $args" -ForegroundColor Magenta; k exec -i -t --namespace @args }
function klon { Write-Host "kubectl logs -f --namespace $args" -ForegroundColor Magenta; k logs -f --namespace @args }
function kpfn { Write-Host "kubectl port-forward --namespace $args" -ForegroundColor Magenta; k port-forward --namespace @args }
function kgn { Write-Host "kubectl get --namespace $args" -ForegroundColor Magenta; k get --namespace @args }
function kdn { Write-Host "kubectl describe --namespace $args" -ForegroundColor Magenta; k describe --namespace @args }
function krmn { Write-Host "kubectl delete --namespace $args" -ForegroundColor Magenta; k delete --namespace @args }
function kgpon { Write-Host "kubectl get pods --namespace $args" -ForegroundColor Magenta; k get pods --namespace @args }
function kdpon { Write-Host "kubectl describe pods --namespace $args" -ForegroundColor Magenta; k describe pods --namespace @args }
function krmpon { Write-Host "kubectl delete pods --namespace $args" -ForegroundColor Magenta; k delete pods --namespace @args }
function kgdepn { Write-Host "kubectl get deployment --namespace $args" -ForegroundColor Magenta; k get deployment --namespace @args }
function kddepn { Write-Host "kubectl describe deployment --namespace $args" -ForegroundColor Magenta; k describe deployment --namespace @args }
function krmdepn { Write-Host "kubectl delete deployment --namespace $args" -ForegroundColor Magenta; k delete deployment --namespace @args }
function kgsvcn { Write-Host "kubectl get service --namespace $args" -ForegroundColor Magenta; k get service --namespace @args }
function kdsvcn { Write-Host "kubectl describe service --namespace $args" -ForegroundColor Magenta; k describe service --namespace @args }
function krmsvcn { Write-Host "kubectl delete service --namespace $args" -ForegroundColor Magenta; k delete service --namespace @args }
function kgingn { Write-Host "kubectl get ingress --namespace $args" -ForegroundColor Magenta; k get ingress --namespace @args }
function kdingn { Write-Host "kubectl describe ingress --namespace $args" -ForegroundColor Magenta; k describe ingress --namespace @args }
function krmingn { Write-Host "kubectl delete ingress --namespace $args" -ForegroundColor Magenta; k delete ingress --namespace @args }
function kgcmn { Write-Host "kubectl get configmap --namespace $args" -ForegroundColor Magenta; k get configmap --namespace @args }
function kdcmn { Write-Host "kubectl describe configmap --namespace $args" -ForegroundColor Magenta; k describe configmap --namespace @args }
function krmcmn { Write-Host "kubectl delete configmap --namespace $args" -ForegroundColor Magenta; k delete configmap --namespace @args }
function kgsecn { Write-Host "kubectl get secret --namespace $args" -ForegroundColor Magenta; k get secret --namespace @args }
function kdsecn { Write-Host "kubectl describe secret --namespace $args" -ForegroundColor Magenta; k describe secret --namespace @args }
function krmsecn { Write-Host "kubectl delete secret --namespace $args" -ForegroundColor Magenta; k delete secret --namespace @args }
function kgoyamln { Write-Host "kubectl get -o=yaml --namespace $args" -ForegroundColor Magenta; k get -o=yaml --namespace @args }
function kgpooyamln { Write-Host "kubectl get pods -o=yaml --namespace $args" -ForegroundColor Magenta; k get pods -o=yaml --namespace @args }
function kgdepoyamln { Write-Host "kubectl get deployment -o=yaml --namespace $args" -ForegroundColor Magenta; k get deployment -o=yaml --namespace @args }
function kgsvcoyamln { Write-Host "kubectl get service -o=yaml --namespace $args" -ForegroundColor Magenta; k get service -o=yaml --namespace @args }
function kgingoyamln { Write-Host "kubectl get ingress -o=yaml --namespace $args" -ForegroundColor Magenta; k get ingress -o=yaml --namespace @args }
function kgcmoyamln { Write-Host "kubectl get configmap -o=yaml --namespace $args" -ForegroundColor Magenta; k get configmap -o=yaml --namespace @args }
function kgsecoyamln { Write-Host "kubectl get secret -o=yaml --namespace $args" -ForegroundColor Magenta; k get secret -o=yaml --namespace @args }
function kgowiden { Write-Host "kubectl get -o=wide --namespace $args" -ForegroundColor Magenta; k get -o=wide --namespace @args }
function kgpoowiden { Write-Host "kubectl get pods -o=wide --namespace $args" -ForegroundColor Magenta; k get pods -o=wide --namespace @args }
function kgdepowiden { Write-Host "kubectl get deployment -o=wide --namespace $args" -ForegroundColor Magenta; k get deployment -o=wide --namespace @args }
function kgsvcowiden { Write-Host "kubectl get service -o=wide --namespace $args" -ForegroundColor Magenta; k get service -o=wide --namespace @args }
function kgingowiden { Write-Host "kubectl get ingress -o=wide --namespace $args" -ForegroundColor Magenta; k get ingress -o=wide --namespace @args }
function kgcmowiden { Write-Host "kubectl get configmap -o=wide --namespace $args" -ForegroundColor Magenta; k get configmap -o=wide --namespace @args }
function kgsecowiden { Write-Host "kubectl get secret -o=wide --namespace $args" -ForegroundColor Magenta; k get secret -o=wide --namespace @args }
function kgojsonn { Write-Host "kubectl get -o=json --namespace $args" -ForegroundColor Magenta; k get -o=json --namespace @args }
function kgpoojsonn { Write-Host "kubectl get pods -o=json --namespace $args" -ForegroundColor Magenta; k get pods -o=json --namespace @args }
function kgdepojsonn { Write-Host "kubectl get deployment -o=json --namespace $args" -ForegroundColor Magenta; k get deployment -o=json --namespace @args }
function kgsvcojsonn { Write-Host "kubectl get service -o=json --namespace $args" -ForegroundColor Magenta; k get service -o=json --namespace @args }
function kgingojsonn { Write-Host "kubectl get ingress -o=json --namespace $args" -ForegroundColor Magenta; k get ingress -o=json --namespace @args }
function kgcmojsonn { Write-Host "kubectl get configmap -o=json --namespace $args" -ForegroundColor Magenta; k get configmap -o=json --namespace @args }
function kgsecojsonn { Write-Host "kubectl get secret -o=json --namespace $args" -ForegroundColor Magenta; k get secret -o=json --namespace @args }
function kgsln { Write-Host "kubectl get --show-labels --namespace $args" -ForegroundColor Magenta; k get --show-labels --namespace @args }
function kgposln { Write-Host "kubectl get pods --show-labels --namespace $args" -ForegroundColor Magenta; k get pods --show-labels --namespace @args }
function kgdepsln { Write-Host "kubectl get deployment --show-labels --namespace $args" -ForegroundColor Magenta; k get deployment --show-labels --namespace @args }
function kgwn { Write-Host "kubectl get --watch --namespace $args" -ForegroundColor Magenta; k get --watch --namespace @args }
function kgpown { Write-Host "kubectl get pods --watch --namespace $args" -ForegroundColor Magenta; k get pods --watch --namespace @args }
function kgdepwn { Write-Host "kubectl get deployment --watch --namespace $args" -ForegroundColor Magenta; k get deployment --watch --namespace @args }
function kgsvcwn { Write-Host "kubectl get service --watch --namespace $args" -ForegroundColor Magenta; k get service --watch --namespace @args }
function kgingwn { Write-Host "kubectl get ingress --watch --namespace $args" -ForegroundColor Magenta; k get ingress --watch --namespace @args }
function kgcmwn { Write-Host "kubectl get configmap --watch --namespace $args" -ForegroundColor Magenta; k get configmap --watch --namespace @args }
function kgsecwn { Write-Host "kubectl get secret --watch --namespace $args" -ForegroundColor Magenta; k get secret --watch --namespace @args }
function kgwoyamln { Write-Host "kubectl get --watch -o=yaml --namespace $args" -ForegroundColor Magenta; k get --watch -o=yaml --namespace @args }
function kgpowoyamln { Write-Host "kubectl get pods --watch -o=yaml --namespace $args" -ForegroundColor Magenta; k get pods --watch -o=yaml --namespace @args }
function kgdepwoyamln { Write-Host "kubectl get deployment --watch -o=yaml --namespace $args" -ForegroundColor Magenta; k get deployment --watch -o=yaml --namespace @args }
function kgsvcwoyamln { Write-Host "kubectl get service --watch -o=yaml --namespace $args" -ForegroundColor Magenta; k get service --watch -o=yaml --namespace @args }
function kgingwoyamln { Write-Host "kubectl get ingress --watch -o=yaml --namespace $args" -ForegroundColor Magenta; k get ingress --watch -o=yaml --namespace @args }
function kgcmwoyamln { Write-Host "kubectl get configmap --watch -o=yaml --namespace $args" -ForegroundColor Magenta; k get configmap --watch -o=yaml --namespace @args }
function kgsecwoyamln { Write-Host "kubectl get secret --watch -o=yaml --namespace $args" -ForegroundColor Magenta; k get secret --watch -o=yaml --namespace @args }
function kgowidesln { Write-Host "kubectl get -o=wide --show-labels --namespace $args" -ForegroundColor Magenta; k get -o=wide --show-labels --namespace @args }
function kgpoowidesln { Write-Host "kubectl get pods -o=wide --show-labels --namespace $args" -ForegroundColor Magenta; k get pods -o=wide --show-labels --namespace @args }
function kgdepowidesln { Write-Host "kubectl get deployment -o=wide --show-labels --namespace $args" -ForegroundColor Magenta; k get deployment -o=wide --show-labels --namespace @args }
function kgslowiden { Write-Host "kubectl get --show-labels -o=wide --namespace $args" -ForegroundColor Magenta; k get --show-labels -o=wide --namespace @args }
function kgposlowiden { Write-Host "kubectl get pods --show-labels -o=wide --namespace $args" -ForegroundColor Magenta; k get pods --show-labels -o=wide --namespace @args }
function kgdepslowiden { Write-Host "kubectl get deployment --show-labels -o=wide --namespace $args" -ForegroundColor Magenta; k get deployment --show-labels -o=wide --namespace @args }
function kgwowiden { Write-Host "kubectl get --watch -o=wide --namespace $args" -ForegroundColor Magenta; k get --watch -o=wide --namespace @args }
function kgpowowiden { Write-Host "kubectl get pods --watch -o=wide --namespace $args" -ForegroundColor Magenta; k get pods --watch -o=wide --namespace @args }
function kgdepwowiden { Write-Host "kubectl get deployment --watch -o=wide --namespace $args" -ForegroundColor Magenta; k get deployment --watch -o=wide --namespace @args }
function kgsvcwowiden { Write-Host "kubectl get service --watch -o=wide --namespace $args" -ForegroundColor Magenta; k get service --watch -o=wide --namespace @args }
function kgingwowiden { Write-Host "kubectl get ingress --watch -o=wide --namespace $args" -ForegroundColor Magenta; k get ingress --watch -o=wide --namespace @args }
function kgcmwowiden { Write-Host "kubectl get configmap --watch -o=wide --namespace $args" -ForegroundColor Magenta; k get configmap --watch -o=wide --namespace @args }
function kgsecwowiden { Write-Host "kubectl get secret --watch -o=wide --namespace $args" -ForegroundColor Magenta; k get secret --watch -o=wide --namespace @args }
function kgwojsonn { Write-Host "kubectl get --watch -o=json --namespace $args" -ForegroundColor Magenta; k get --watch -o=json --namespace @args }
function kgpowojsonn { Write-Host "kubectl get pods --watch -o=json --namespace $args" -ForegroundColor Magenta; k get pods --watch -o=json --namespace @args }
function kgdepwojsonn { Write-Host "kubectl get deployment --watch -o=json --namespace $args" -ForegroundColor Magenta; k get deployment --watch -o=json --namespace @args }
function kgsvcwojsonn { Write-Host "kubectl get service --watch -o=json --namespace $args" -ForegroundColor Magenta; k get service --watch -o=json --namespace @args }
function kgingwojsonn { Write-Host "kubectl get ingress --watch -o=json --namespace $args" -ForegroundColor Magenta; k get ingress --watch -o=json --namespace @args }
function kgcmwojsonn { Write-Host "kubectl get configmap --watch -o=json --namespace $args" -ForegroundColor Magenta; k get configmap --watch -o=json --namespace @args }
function kgsecwojsonn { Write-Host "kubectl get secret --watch -o=json --namespace $args" -ForegroundColor Magenta; k get secret --watch -o=json --namespace @args }
function kgslwn { Write-Host "kubectl get --show-labels --watch --namespace $args" -ForegroundColor Magenta; k get --show-labels --watch --namespace @args }
function kgposlwn { Write-Host "kubectl get pods --show-labels --watch --namespace $args" -ForegroundColor Magenta; k get pods --show-labels --watch --namespace @args }
function kgdepslwn { Write-Host "kubectl get deployment --show-labels --watch --namespace $args" -ForegroundColor Magenta; k get deployment --show-labels --watch --namespace @args }
function kgwsln { Write-Host "kubectl get --watch --show-labels --namespace $args" -ForegroundColor Magenta; k get --watch --show-labels --namespace @args }
function kgpowsln { Write-Host "kubectl get pods --watch --show-labels --namespace $args" -ForegroundColor Magenta; k get pods --watch --show-labels --namespace @args }
function kgdepwsln { Write-Host "kubectl get deployment --watch --show-labels --namespace $args" -ForegroundColor Magenta; k get deployment --watch --show-labels --namespace @args }
function kgslwowiden { Write-Host "kubectl get --show-labels --watch -o=wide --namespace $args" -ForegroundColor Magenta; k get --show-labels --watch -o=wide --namespace @args }
function kgposlwowiden { Write-Host "kubectl get pods --show-labels --watch -o=wide --namespace $args" -ForegroundColor Magenta; k get pods --show-labels --watch -o=wide --namespace @args }
function kgdepslwowiden { Write-Host "kubectl get deployment --show-labels --watch -o=wide --namespace $args" -ForegroundColor Magenta; k get deployment --show-labels --watch -o=wide --namespace @args }
function kgwowidesln { Write-Host "kubectl get --watch -o=wide --show-labels --namespace $args" -ForegroundColor Magenta; k get --watch -o=wide --show-labels --namespace @args }
function kgpowowidesln { Write-Host "kubectl get pods --watch -o=wide --show-labels --namespace $args" -ForegroundColor Magenta; k get pods --watch -o=wide --show-labels --namespace @args }
function kgdepwowidesln { Write-Host "kubectl get deployment --watch -o=wide --show-labels --namespace $args" -ForegroundColor Magenta; k get deployment --watch -o=wide --show-labels --namespace @args }
function kgwslowiden { Write-Host "kubectl get --watch --show-labels -o=wide --namespace $args" -ForegroundColor Magenta; k get --watch --show-labels -o=wide --namespace @args }
function kgpowslowiden { Write-Host "kubectl get pods --watch --show-labels -o=wide --namespace $args" -ForegroundColor Magenta; k get pods --watch --show-labels -o=wide --namespace @args }
function kgdepwslowiden { Write-Host "kubectl get deployment --watch --show-labels -o=wide --namespace $args" -ForegroundColor Magenta; k get deployment --watch --show-labels -o=wide --namespace @args }
