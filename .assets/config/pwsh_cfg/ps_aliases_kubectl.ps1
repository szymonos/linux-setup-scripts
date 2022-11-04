# helper function
#region helper functions
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

    $ver = Get-KubectlServerVersion
    $kctlVer = [IO.Path]::Combine($KUBECTL_DIR, $ver, $KUBECTL)

    if ((Get-ItemPropertyValue $KUBECTL_LOCAL -Name LinkTarget -ErrorAction SilentlyContinue) -ne $kctlVer) {
        if (-not (Test-Path $LOCAL_BIN)) {
            New-Item $LOCAL_BIN -ItemType Directory | Out-Null
        }
        if (-not (Test-Path $kctlVer -PathType Leaf)) {
            New-Item $([IO.Path]::Combine($KUBECTL_DIR, $ver)) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
            $dlSysArch = if ($IsWindows) {
                'windows/amd64'
            } elseif ($IsLinux) {
                'linux/amd64'
            } elseif ($IsMacOS) {
                'darwin/arm64'
            }
            do {
                [Net.WebClient]::new().DownloadFile("https://dl.k8s.io/release/${ver}/bin/$dlSysArch/$KUBECTL", $kctlVer)
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
Prints the command passed as the parameter and then executes it.
#>
function Invoke-PrintRunCommand {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$cmd
    )
    Write-Host $cmd -ForegroundColor Magenta
    Invoke-Expression $cmd
}

<#
.SYNOPSIS
Change kubernetes context and sets the corresponding kubectl client version.
#>
function Set-KubectlUseContext {
    Invoke-PrintRunCommand "kubectl config use-context $args"
    Set-KubectlLocal
}
#endregion

#region aliases
Set-Alias -Name k -Value kubectl
Set-Alias -Name kvc -Value Get-KubectlClientVersion
Set-Alias -Name kvs -Value Get-KubectlServerVersion
Set-Alias -Name kcuctx -Value Set-KubectlUseContext
#endregion

#region kubectl functions
function ktop { Invoke-PrintRunCommand "kubectl top pod $args --use-protocol-buffers" }
function ktopcntr { Invoke-PrintRunCommand "kubectl top pod $args --use-protocol-buffers --containers" }
function kga { Invoke-PrintRunCommand "kubectl get all $args" }
function kinf { Invoke-PrintRunCommand 'kubectl cluster-info' }
function kav { Invoke-PrintRunCommand 'kubectl api-versions' }
function kcv { Invoke-PrintRunCommand 'kubectl config view' }
function kcgctx { Invoke-PrintRunCommand 'kubectl config get-contexts' }
function kcsctxcns { Invoke-PrintRunCommand "kubectl config set-context --current --namespace $args" }
function ksys { Invoke-PrintRunCommand "kubectl --namespace=kube-system $args" }
function ka { Invoke-PrintRunCommand "kubectl apply --recursive -f $args" }
function ksysa { Invoke-PrintRunCommand "kubectl --namespace=kube-system apply --recursive -f $args" }
function kak { Invoke-PrintRunCommand "kubectl apply -k $args" }
function kk { Invoke-PrintRunCommand "kubectl kustomize $args" }
function krmk { Invoke-PrintRunCommand "kubectl delete -k $args" }
function kex { Invoke-PrintRunCommand "kubectl exec -i -t $args" }
function kexsh { Invoke-PrintRunCommand "kubectl exec -i -t $args -- sh" }
function kexbash { Invoke-PrintRunCommand "kubectl exec -i -t $args -- bash" }
function kexpwsh { Invoke-PrintRunCommand "kubectl exec -i -t $args -- pwsh" }
function kexpy { Invoke-PrintRunCommand "kubectl exec -i -t $args -- python" }
function kexipy { Invoke-PrintRunCommand "kubectl exec -i -t $args -- ipython" }
function kexzsh { Invoke-PrintRunCommand "kubectl exec -i -t $args -- zsh" }
function ksysex { Invoke-PrintRunCommand "kubectl --namespace=kube-system exec -i -t $args" }
function klo { Invoke-PrintRunCommand "kubectl logs -f $args" }
function ksyslo { Invoke-PrintRunCommand "kubectl --namespace=kube-system logs -f $args" }
function klop { Invoke-PrintRunCommand "kubectl logs -f -p $args" }
function ksyslop { Invoke-PrintRunCommand "kubectl --namespace=kube-system logs -f -p $args" }
function kp { Invoke-PrintRunCommand "kubectl proxy $args" }
function kpf { Invoke-PrintRunCommand "kubectl port-forward $args" }
function kg { Invoke-PrintRunCommand "kubectl get $args" }
function ksysg { Invoke-PrintRunCommand "kubectl --namespace=kube-system get $args" }
function kd { Invoke-PrintRunCommand "kubectl describe $args" }
function ksysd { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe $args" }
function krm { Invoke-PrintRunCommand "kubectl delete $args" }
function ksysrm { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete $args" }
function krun { Invoke-PrintRunCommand "kubectl run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t $args" }
function ksysrun { Invoke-PrintRunCommand "kubectl --namespace=kube-system run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t $args" }
function kgpo { Invoke-PrintRunCommand "kubectl get pods $args" }
function kgpocntr { Invoke-PrintRunCommand "kubectl get pods $args -o jsonpath='{.spec.containers[*].name}'" }
function kgpolname { Invoke-PrintRunCommand "kubectl get pods -l app=$args -o jsonpath='{.items[*].metadata.name}'" }
function kgpolcntr { Invoke-PrintRunCommand "kubectl get pods -l app=$args -o jsonpath='{.items[*].spec.containers[*].name}'" }
function ksysgpo { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods $args" }
function kdpo { Invoke-PrintRunCommand "kubectl describe pods $args" }
function ksysdpo { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe pods $args" }
function krmpo { Invoke-PrintRunCommand "kubectl delete pods $args" }
function ksysrmpo { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete pods $args" }
function kgdep { Invoke-PrintRunCommand "kubectl get deployment $args" }
function ksysgdep { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment $args" }
function kddep { Invoke-PrintRunCommand "kubectl describe deployment $args" }
function ksysddep { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe deployment $args" }
function krmdep { Invoke-PrintRunCommand "kubectl delete deployment $args" }
function ksysrmdep { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete deployment $args" }
function kgsvc { Invoke-PrintRunCommand "kubectl get service $args" }
function ksysgsvc { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service $args" }
function kdsvc { Invoke-PrintRunCommand "kubectl describe service $args" }
function ksysdsvc { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe service $args" }
function krmsvc { Invoke-PrintRunCommand "kubectl delete service $args" }
function ksysrmsvc { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete service $args" }
function kging { Invoke-PrintRunCommand "kubectl get ingress $args" }
function ksysging { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress $args" }
function kding { Invoke-PrintRunCommand "kubectl describe ingress $args" }
function ksysding { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe ingress $args" }
function krming { Invoke-PrintRunCommand "kubectl delete ingress $args" }
function ksysrming { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete ingress $args" }
function kgcm { Invoke-PrintRunCommand "kubectl get configmap $args" }
function ksysgcm { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap $args" }
function kdcm { Invoke-PrintRunCommand "kubectl describe configmap $args" }
function ksysdcm { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe configmap $args" }
function krmcm { Invoke-PrintRunCommand "kubectl delete configmap $args" }
function ksysrmcm { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete configmap $args" }
function kgsec { Invoke-PrintRunCommand "kubectl get secret $args" }
function ksysgsec { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret $args" }
function kdsec { Invoke-PrintRunCommand "kubectl describe secret $args" }
function ksysdsec { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe secret $args" }
function krmsec { Invoke-PrintRunCommand "kubectl delete secret $args" }
function ksysrmsec { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete secret $args" }
function kgno { Invoke-PrintRunCommand "kubectl get nodes $args" }
function kdno { Invoke-PrintRunCommand "kubectl describe nodes $args" }
function kgns { Invoke-PrintRunCommand "kubectl get namespaces $args" }
function kdns { Invoke-PrintRunCommand "kubectl describe namespaces $args" }
function krmns { Invoke-PrintRunCommand "kubectl delete namespaces $args" }
function kgoyaml { Invoke-PrintRunCommand "kubectl get -o=yaml $args" }
function ksysgoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get -o=yaml $args" }
function kgpooyaml { Invoke-PrintRunCommand "kubectl get pods -o=yaml $args" }
function ksysgpooyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods -o=yaml $args" }
function kgdepoyaml { Invoke-PrintRunCommand "kubectl get deployment -o=yaml $args" }
function ksysgdepoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment -o=yaml $args" }
function kgsvcoyaml { Invoke-PrintRunCommand "kubectl get service -o=yaml $args" }
function ksysgsvcoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service -o=yaml $args" }
function kgingoyaml { Invoke-PrintRunCommand "kubectl get ingress -o=yaml $args" }
function ksysgingoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress -o=yaml $args" }
function kgcmoyaml { Invoke-PrintRunCommand "kubectl get configmap -o=yaml $args" }
function ksysgcmoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap -o=yaml $args" }
function kgsecoyaml { Invoke-PrintRunCommand "kubectl get secret -o=yaml $args" }
function ksysgsecoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret -o=yaml $args" }
function kgnooyaml { Invoke-PrintRunCommand "kubectl get nodes -o=yaml $args" }
function kgnsoyaml { Invoke-PrintRunCommand "kubectl get namespaces -o=yaml $args" }
function kgowide { Invoke-PrintRunCommand "kubectl get -o=wide $args" }
function ksysgowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get -o=wide $args" }
function kgpoowide { Invoke-PrintRunCommand "kubectl get pods -o=wide $args" }
function ksysgpoowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods -o=wide $args" }
function kgdepowide { Invoke-PrintRunCommand "kubectl get deployment -o=wide $args" }
function ksysgdepowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment -o=wide $args" }
function kgsvcowide { Invoke-PrintRunCommand "kubectl get service -o=wide $args" }
function ksysgsvcowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service -o=wide $args" }
function kgingowide { Invoke-PrintRunCommand "kubectl get ingress -o=wide $args" }
function ksysgingowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress -o=wide $args" }
function kgcmowide { Invoke-PrintRunCommand "kubectl get configmap -o=wide $args" }
function ksysgcmowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap -o=wide $args" }
function kgsecowide { Invoke-PrintRunCommand "kubectl get secret -o=wide $args" }
function ksysgsecowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret -o=wide $args" }
function kgnoowide { Invoke-PrintRunCommand "kubectl get nodes -o=wide $args" }
function kgnsowide { Invoke-PrintRunCommand "kubectl get namespaces -o=wide $args" }
function kgojson { Invoke-PrintRunCommand "kubectl get -o=json $args" }
function ksysgojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get -o=json $args" }
function kgpoojson { Invoke-PrintRunCommand "kubectl get pods -o=json $args" }
function ksysgpoojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods -o=json $args" }
function kgdepojson { Invoke-PrintRunCommand "kubectl get deployment -o=json $args" }
function ksysgdepojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment -o=json $args" }
function kgsvcojson { Invoke-PrintRunCommand "kubectl get service -o=json $args" }
function ksysgsvcojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service -o=json $args" }
function kgingojson { Invoke-PrintRunCommand "kubectl get ingress -o=json $args" }
function ksysgingojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress -o=json $args" }
function kgcmojson { Invoke-PrintRunCommand "kubectl get configmap -o=json $args" }
function ksysgcmojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap -o=json $args" }
function kgsecojson { Invoke-PrintRunCommand "kubectl get secret -o=json $args" }
function ksysgsecojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret -o=json $args" }
function kgnoojson { Invoke-PrintRunCommand "kubectl get nodes -o=json $args" }
function kgnsojson { Invoke-PrintRunCommand "kubectl get namespaces -o=json $args" }
function kgall { Invoke-PrintRunCommand "kubectl get --all-namespaces $args" }
function kdall { Invoke-PrintRunCommand "kubectl describe --all-namespaces $args" }
function kgpoall { Invoke-PrintRunCommand "kubectl get pods --all-namespaces $args" }
function kdpoall { Invoke-PrintRunCommand "kubectl describe pods --all-namespaces $args" }
function kgdepall { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces $args" }
function kddepall { Invoke-PrintRunCommand "kubectl describe deployment --all-namespaces $args" }
function kgsvcall { Invoke-PrintRunCommand "kubectl get service --all-namespaces $args" }
function kdsvcall { Invoke-PrintRunCommand "kubectl describe service --all-namespaces $args" }
function kgingall { Invoke-PrintRunCommand "kubectl get ingress --all-namespaces $args" }
function kdingall { Invoke-PrintRunCommand "kubectl describe ingress --all-namespaces $args" }
function kgcmall { Invoke-PrintRunCommand "kubectl get configmap --all-namespaces $args" }
function kdcmall { Invoke-PrintRunCommand "kubectl describe configmap --all-namespaces $args" }
function kgsecall { Invoke-PrintRunCommand "kubectl get secret --all-namespaces $args" }
function kdsecall { Invoke-PrintRunCommand "kubectl describe secret --all-namespaces $args" }
function kgnsall { Invoke-PrintRunCommand "kubectl get namespaces --all-namespaces $args" }
function kdnsall { Invoke-PrintRunCommand "kubectl describe namespaces --all-namespaces $args" }
function kgsl { Invoke-PrintRunCommand "kubectl get --show-labels $args" }
function ksysgsl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --show-labels $args" }
function kgposl { Invoke-PrintRunCommand "kubectl get pods --show-labels $args" }
function ksysgposl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --show-labels $args" }
function kgdepsl { Invoke-PrintRunCommand "kubectl get deployment --show-labels $args" }
function ksysgdepsl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --show-labels $args" }
function krmall { Invoke-PrintRunCommand "kubectl delete --all $args" }
function ksysrmall { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete --all $args" }
function krmpoall { Invoke-PrintRunCommand "kubectl delete pods --all $args" }
function ksysrmpoall { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete pods --all $args" }
function krmdepall { Invoke-PrintRunCommand "kubectl delete deployment --all $args" }
function ksysrmdepall { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete deployment --all $args" }
function krmsvcall { Invoke-PrintRunCommand "kubectl delete service --all $args" }
function ksysrmsvcall { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete service --all $args" }
function krmingall { Invoke-PrintRunCommand "kubectl delete ingress --all $args" }
function ksysrmingall { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete ingress --all $args" }
function krmcmall { Invoke-PrintRunCommand "kubectl delete configmap --all $args" }
function ksysrmcmall { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete configmap --all $args" }
function krmsecall { Invoke-PrintRunCommand "kubectl delete secret --all $args" }
function ksysrmsecall { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete secret --all $args" }
function krmnsall { Invoke-PrintRunCommand "kubectl delete namespaces --all $args" }
function kgw { Invoke-PrintRunCommand "kubectl get --watch $args" }
function ksysgw { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch $args" }
function kgpow { Invoke-PrintRunCommand "kubectl get pods --watch $args" }
function ksysgpow { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch $args" }
function kgdepw { Invoke-PrintRunCommand "kubectl get deployment --watch $args" }
function ksysgdepw { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch $args" }
function kgsvcw { Invoke-PrintRunCommand "kubectl get service --watch $args" }
function ksysgsvcw { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service --watch $args" }
function kgingw { Invoke-PrintRunCommand "kubectl get ingress --watch $args" }
function ksysgingw { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress --watch $args" }
function kgcmw { Invoke-PrintRunCommand "kubectl get configmap --watch $args" }
function ksysgcmw { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap --watch $args" }
function kgsecw { Invoke-PrintRunCommand "kubectl get secret --watch $args" }
function ksysgsecw { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret --watch $args" }
function kgnow { Invoke-PrintRunCommand "kubectl get nodes --watch $args" }
function kgnsw { Invoke-PrintRunCommand "kubectl get namespaces --watch $args" }
function kgoyamlall { Invoke-PrintRunCommand "kubectl get -o=yaml --all-namespaces $args" }
function kgpooyamlall { Invoke-PrintRunCommand "kubectl get pods -o=yaml --all-namespaces $args" }
function kgdepoyamlall { Invoke-PrintRunCommand "kubectl get deployment -o=yaml --all-namespaces $args" }
function kgsvcoyamlall { Invoke-PrintRunCommand "kubectl get service -o=yaml --all-namespaces $args" }
function kgingoyamlall { Invoke-PrintRunCommand "kubectl get ingress -o=yaml --all-namespaces $args" }
function kgcmoyamlall { Invoke-PrintRunCommand "kubectl get configmap -o=yaml --all-namespaces $args" }
function kgsecoyamlall { Invoke-PrintRunCommand "kubectl get secret -o=yaml --all-namespaces $args" }
function kgnsoyamlall { Invoke-PrintRunCommand "kubectl get namespaces -o=yaml --all-namespaces $args" }
function kgalloyaml { Invoke-PrintRunCommand "kubectl get --all-namespaces -o=yaml $args" }
function kgpoalloyaml { Invoke-PrintRunCommand "kubectl get pods --all-namespaces -o=yaml $args" }
function kgdepalloyaml { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces -o=yaml $args" }
function kgsvcalloyaml { Invoke-PrintRunCommand "kubectl get service --all-namespaces -o=yaml $args" }
function kgingalloyaml { Invoke-PrintRunCommand "kubectl get ingress --all-namespaces -o=yaml $args" }
function kgcmalloyaml { Invoke-PrintRunCommand "kubectl get configmap --all-namespaces -o=yaml $args" }
function kgsecalloyaml { Invoke-PrintRunCommand "kubectl get secret --all-namespaces -o=yaml $args" }
function kgnsalloyaml { Invoke-PrintRunCommand "kubectl get namespaces --all-namespaces -o=yaml $args" }
function kgwoyaml { Invoke-PrintRunCommand "kubectl get --watch -o=yaml $args" }
function ksysgwoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch -o=yaml $args" }
function kgpowoyaml { Invoke-PrintRunCommand "kubectl get pods --watch -o=yaml $args" }
function ksysgpowoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch -o=yaml $args" }
function kgdepwoyaml { Invoke-PrintRunCommand "kubectl get deployment --watch -o=yaml $args" }
function ksysgdepwoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch -o=yaml $args" }
function kgsvcwoyaml { Invoke-PrintRunCommand "kubectl get service --watch -o=yaml $args" }
function ksysgsvcwoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service --watch -o=yaml $args" }
function kgingwoyaml { Invoke-PrintRunCommand "kubectl get ingress --watch -o=yaml $args" }
function ksysgingwoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress --watch -o=yaml $args" }
function kgcmwoyaml { Invoke-PrintRunCommand "kubectl get configmap --watch -o=yaml $args" }
function ksysgcmwoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap --watch -o=yaml $args" }
function kgsecwoyaml { Invoke-PrintRunCommand "kubectl get secret --watch -o=yaml $args" }
function ksysgsecwoyaml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret --watch -o=yaml $args" }
function kgnowoyaml { Invoke-PrintRunCommand "kubectl get nodes --watch -o=yaml $args" }
function kgnswoyaml { Invoke-PrintRunCommand "kubectl get namespaces --watch -o=yaml $args" }
function kgowideall { Invoke-PrintRunCommand "kubectl get -o=wide --all-namespaces $args" }
function kgpoowideall { Invoke-PrintRunCommand "kubectl get pods -o=wide --all-namespaces $args" }
function kgdepowideall { Invoke-PrintRunCommand "kubectl get deployment -o=wide --all-namespaces $args" }
function kgsvcowideall { Invoke-PrintRunCommand "kubectl get service -o=wide --all-namespaces $args" }
function kgingowideall { Invoke-PrintRunCommand "kubectl get ingress -o=wide --all-namespaces $args" }
function kgcmowideall { Invoke-PrintRunCommand "kubectl get configmap -o=wide --all-namespaces $args" }
function kgsecowideall { Invoke-PrintRunCommand "kubectl get secret -o=wide --all-namespaces $args" }
function kgnsowideall { Invoke-PrintRunCommand "kubectl get namespaces -o=wide --all-namespaces $args" }
function kgallowide { Invoke-PrintRunCommand "kubectl get --all-namespaces -o=wide $args" }
function kgpoallowide { Invoke-PrintRunCommand "kubectl get pods --all-namespaces -o=wide $args" }
function kgdepallowide { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces -o=wide $args" }
function kgsvcallowide { Invoke-PrintRunCommand "kubectl get service --all-namespaces -o=wide $args" }
function kgingallowide { Invoke-PrintRunCommand "kubectl get ingress --all-namespaces -o=wide $args" }
function kgcmallowide { Invoke-PrintRunCommand "kubectl get configmap --all-namespaces -o=wide $args" }
function kgsecallowide { Invoke-PrintRunCommand "kubectl get secret --all-namespaces -o=wide $args" }
function kgnsallowide { Invoke-PrintRunCommand "kubectl get namespaces --all-namespaces -o=wide $args" }
function kgowidesl { Invoke-PrintRunCommand "kubectl get -o=wide --show-labels $args" }
function ksysgowidesl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get -o=wide --show-labels $args" }
function kgpoowidesl { Invoke-PrintRunCommand "kubectl get pods -o=wide --show-labels $args" }
function ksysgpoowidesl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods -o=wide --show-labels $args" }
function kgdepowidesl { Invoke-PrintRunCommand "kubectl get deployment -o=wide --show-labels $args" }
function ksysgdepowidesl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment -o=wide --show-labels $args" }
function kgslowide { Invoke-PrintRunCommand "kubectl get --show-labels -o=wide $args" }
function ksysgslowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --show-labels -o=wide $args" }
function kgposlowide { Invoke-PrintRunCommand "kubectl get pods --show-labels -o=wide $args" }
function ksysgposlowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --show-labels -o=wide $args" }
function kgdepslowide { Invoke-PrintRunCommand "kubectl get deployment --show-labels -o=wide $args" }
function ksysgdepslowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --show-labels -o=wide $args" }
function kgwowide { Invoke-PrintRunCommand "kubectl get --watch -o=wide $args" }
function ksysgwowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch -o=wide $args" }
function kgpowowide { Invoke-PrintRunCommand "kubectl get pods --watch -o=wide $args" }
function ksysgpowowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch -o=wide $args" }
function kgdepwowide { Invoke-PrintRunCommand "kubectl get deployment --watch -o=wide $args" }
function ksysgdepwowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch -o=wide $args" }
function kgsvcwowide { Invoke-PrintRunCommand "kubectl get service --watch -o=wide $args" }
function ksysgsvcwowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service --watch -o=wide $args" }
function kgingwowide { Invoke-PrintRunCommand "kubectl get ingress --watch -o=wide $args" }
function ksysgingwowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress --watch -o=wide $args" }
function kgcmwowide { Invoke-PrintRunCommand "kubectl get configmap --watch -o=wide $args" }
function ksysgcmwowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap --watch -o=wide $args" }
function kgsecwowide { Invoke-PrintRunCommand "kubectl get secret --watch -o=wide $args" }
function ksysgsecwowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret --watch -o=wide $args" }
function kgnowowide { Invoke-PrintRunCommand "kubectl get nodes --watch -o=wide $args" }
function kgnswowide { Invoke-PrintRunCommand "kubectl get namespaces --watch -o=wide $args" }
function kgojsonall { Invoke-PrintRunCommand "kubectl get -o=json --all-namespaces $args" }
function kgpoojsonall { Invoke-PrintRunCommand "kubectl get pods -o=json --all-namespaces $args" }
function kgdepojsonall { Invoke-PrintRunCommand "kubectl get deployment -o=json --all-namespaces $args" }
function kgsvcojsonall { Invoke-PrintRunCommand "kubectl get service -o=json --all-namespaces $args" }
function kgingojsonall { Invoke-PrintRunCommand "kubectl get ingress -o=json --all-namespaces $args" }
function kgcmojsonall { Invoke-PrintRunCommand "kubectl get configmap -o=json --all-namespaces $args" }
function kgsecojsonall { Invoke-PrintRunCommand "kubectl get secret -o=json --all-namespaces $args" }
function kgnsojsonall { Invoke-PrintRunCommand "kubectl get namespaces -o=json --all-namespaces $args" }
function kgallojson { Invoke-PrintRunCommand "kubectl get --all-namespaces -o=json $args" }
function kgpoallojson { Invoke-PrintRunCommand "kubectl get pods --all-namespaces -o=json $args" }
function kgdepallojson { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces -o=json $args" }
function kgsvcallojson { Invoke-PrintRunCommand "kubectl get service --all-namespaces -o=json $args" }
function kgingallojson { Invoke-PrintRunCommand "kubectl get ingress --all-namespaces -o=json $args" }
function kgcmallojson { Invoke-PrintRunCommand "kubectl get configmap --all-namespaces -o=json $args" }
function kgsecallojson { Invoke-PrintRunCommand "kubectl get secret --all-namespaces -o=json $args" }
function kgnsallojson { Invoke-PrintRunCommand "kubectl get namespaces --all-namespaces -o=json $args" }
function kgwojson { Invoke-PrintRunCommand "kubectl get --watch -o=json $args" }
function ksysgwojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch -o=json $args" }
function kgpowojson { Invoke-PrintRunCommand "kubectl get pods --watch -o=json $args" }
function ksysgpowojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch -o=json $args" }
function kgdepwojson { Invoke-PrintRunCommand "kubectl get deployment --watch -o=json $args" }
function ksysgdepwojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch -o=json $args" }
function kgsvcwojson { Invoke-PrintRunCommand "kubectl get service --watch -o=json $args" }
function ksysgsvcwojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service --watch -o=json $args" }
function kgingwojson { Invoke-PrintRunCommand "kubectl get ingress --watch -o=json $args" }
function ksysgingwojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress --watch -o=json $args" }
function kgcmwojson { Invoke-PrintRunCommand "kubectl get configmap --watch -o=json $args" }
function ksysgcmwojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap --watch -o=json $args" }
function kgsecwojson { Invoke-PrintRunCommand "kubectl get secret --watch -o=json $args" }
function ksysgsecwojson { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret --watch -o=json $args" }
function kgnowojson { Invoke-PrintRunCommand "kubectl get nodes --watch -o=json $args" }
function kgnswojson { Invoke-PrintRunCommand "kubectl get namespaces --watch -o=json $args" }
function kgallsl { Invoke-PrintRunCommand "kubectl get --all-namespaces --show-labels $args" }
function kgpoallsl { Invoke-PrintRunCommand "kubectl get pods --all-namespaces --show-labels $args" }
function kgdepallsl { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces --show-labels $args" }
function kgslall { Invoke-PrintRunCommand "kubectl get --show-labels --all-namespaces $args" }
function kgposlall { Invoke-PrintRunCommand "kubectl get pods --show-labels --all-namespaces $args" }
function kgdepslall { Invoke-PrintRunCommand "kubectl get deployment --show-labels --all-namespaces $args" }
function kgallw { Invoke-PrintRunCommand "kubectl get --all-namespaces --watch $args" }
function kgpoallw { Invoke-PrintRunCommand "kubectl get pods --all-namespaces --watch $args" }
function kgdepallw { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces --watch $args" }
function kgsvcallw { Invoke-PrintRunCommand "kubectl get service --all-namespaces --watch $args" }
function kgingallw { Invoke-PrintRunCommand "kubectl get ingress --all-namespaces --watch $args" }
function kgcmallw { Invoke-PrintRunCommand "kubectl get configmap --all-namespaces --watch $args" }
function kgsecallw { Invoke-PrintRunCommand "kubectl get secret --all-namespaces --watch $args" }
function kgnsallw { Invoke-PrintRunCommand "kubectl get namespaces --all-namespaces --watch $args" }
function kgwall { Invoke-PrintRunCommand "kubectl get --watch --all-namespaces $args" }
function kgpowall { Invoke-PrintRunCommand "kubectl get pods --watch --all-namespaces $args" }
function kgdepwall { Invoke-PrintRunCommand "kubectl get deployment --watch --all-namespaces $args" }
function kgsvcwall { Invoke-PrintRunCommand "kubectl get service --watch --all-namespaces $args" }
function kgingwall { Invoke-PrintRunCommand "kubectl get ingress --watch --all-namespaces $args" }
function kgcmwall { Invoke-PrintRunCommand "kubectl get configmap --watch --all-namespaces $args" }
function kgsecwall { Invoke-PrintRunCommand "kubectl get secret --watch --all-namespaces $args" }
function kgnswall { Invoke-PrintRunCommand "kubectl get namespaces --watch --all-namespaces $args" }
function kgslw { Invoke-PrintRunCommand "kubectl get --show-labels --watch $args" }
function ksysgslw { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --show-labels --watch $args" }
function kgposlw { Invoke-PrintRunCommand "kubectl get pods --show-labels --watch $args" }
function ksysgposlw { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --show-labels --watch $args" }
function kgdepslw { Invoke-PrintRunCommand "kubectl get deployment --show-labels --watch $args" }
function ksysgdepslw { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --show-labels --watch $args" }
function kgwsl { Invoke-PrintRunCommand "kubectl get --watch --show-labels $args" }
function ksysgwsl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch --show-labels $args" }
function kgpowsl { Invoke-PrintRunCommand "kubectl get pods --watch --show-labels $args" }
function ksysgpowsl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch --show-labels $args" }
function kgdepwsl { Invoke-PrintRunCommand "kubectl get deployment --watch --show-labels $args" }
function ksysgdepwsl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch --show-labels $args" }
function kgallwoyaml { Invoke-PrintRunCommand "kubectl get --all-namespaces --watch -o=yaml $args" }
function kgpoallwoyaml { Invoke-PrintRunCommand "kubectl get pods --all-namespaces --watch -o=yaml $args" }
function kgdepallwoyaml { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces --watch -o=yaml $args" }
function kgsvcallwoyaml { Invoke-PrintRunCommand "kubectl get service --all-namespaces --watch -o=yaml $args" }
function kgingallwoyaml { Invoke-PrintRunCommand "kubectl get ingress --all-namespaces --watch -o=yaml $args" }
function kgcmallwoyaml { Invoke-PrintRunCommand "kubectl get configmap --all-namespaces --watch -o=yaml $args" }
function kgsecallwoyaml { Invoke-PrintRunCommand "kubectl get secret --all-namespaces --watch -o=yaml $args" }
function kgnsallwoyaml { Invoke-PrintRunCommand "kubectl get namespaces --all-namespaces --watch -o=yaml $args" }
function kgwoyamlall { Invoke-PrintRunCommand "kubectl get --watch -o=yaml --all-namespaces $args" }
function kgpowoyamlall { Invoke-PrintRunCommand "kubectl get pods --watch -o=yaml --all-namespaces $args" }
function kgdepwoyamlall { Invoke-PrintRunCommand "kubectl get deployment --watch -o=yaml --all-namespaces $args" }
function kgsvcwoyamlall { Invoke-PrintRunCommand "kubectl get service --watch -o=yaml --all-namespaces $args" }
function kgingwoyamlall { Invoke-PrintRunCommand "kubectl get ingress --watch -o=yaml --all-namespaces $args" }
function kgcmwoyamlall { Invoke-PrintRunCommand "kubectl get configmap --watch -o=yaml --all-namespaces $args" }
function kgsecwoyamlall { Invoke-PrintRunCommand "kubectl get secret --watch -o=yaml --all-namespaces $args" }
function kgnswoyamlall { Invoke-PrintRunCommand "kubectl get namespaces --watch -o=yaml --all-namespaces $args" }
function kgwalloyaml { Invoke-PrintRunCommand "kubectl get --watch --all-namespaces -o=yaml $args" }
function kgpowalloyaml { Invoke-PrintRunCommand "kubectl get pods --watch --all-namespaces -o=yaml $args" }
function kgdepwalloyaml { Invoke-PrintRunCommand "kubectl get deployment --watch --all-namespaces -o=yaml $args" }
function kgsvcwalloyaml { Invoke-PrintRunCommand "kubectl get service --watch --all-namespaces -o=yaml $args" }
function kgingwalloyaml { Invoke-PrintRunCommand "kubectl get ingress --watch --all-namespaces -o=yaml $args" }
function kgcmwalloyaml { Invoke-PrintRunCommand "kubectl get configmap --watch --all-namespaces -o=yaml $args" }
function kgsecwalloyaml { Invoke-PrintRunCommand "kubectl get secret --watch --all-namespaces -o=yaml $args" }
function kgnswalloyaml { Invoke-PrintRunCommand "kubectl get namespaces --watch --all-namespaces -o=yaml $args" }
function kgowideallsl { Invoke-PrintRunCommand "kubectl get -o=wide --all-namespaces --show-labels $args" }
function kgpoowideallsl { Invoke-PrintRunCommand "kubectl get pods -o=wide --all-namespaces --show-labels $args" }
function kgdepowideallsl { Invoke-PrintRunCommand "kubectl get deployment -o=wide --all-namespaces --show-labels $args" }
function kgowideslall { Invoke-PrintRunCommand "kubectl get -o=wide --show-labels --all-namespaces $args" }
function kgpoowideslall { Invoke-PrintRunCommand "kubectl get pods -o=wide --show-labels --all-namespaces $args" }
function kgdepowideslall { Invoke-PrintRunCommand "kubectl get deployment -o=wide --show-labels --all-namespaces $args" }
function kgallowidesl { Invoke-PrintRunCommand "kubectl get --all-namespaces -o=wide --show-labels $args" }
function kgpoallowidesl { Invoke-PrintRunCommand "kubectl get pods --all-namespaces -o=wide --show-labels $args" }
function kgdepallowidesl { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces -o=wide --show-labels $args" }
function kgallslowide { Invoke-PrintRunCommand "kubectl get --all-namespaces --show-labels -o=wide $args" }
function kgpoallslowide { Invoke-PrintRunCommand "kubectl get pods --all-namespaces --show-labels -o=wide $args" }
function kgdepallslowide { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces --show-labels -o=wide $args" }
function kgslowideall { Invoke-PrintRunCommand "kubectl get --show-labels -o=wide --all-namespaces $args" }
function kgposlowideall { Invoke-PrintRunCommand "kubectl get pods --show-labels -o=wide --all-namespaces $args" }
function kgdepslowideall { Invoke-PrintRunCommand "kubectl get deployment --show-labels -o=wide --all-namespaces $args" }
function kgslallowide { Invoke-PrintRunCommand "kubectl get --show-labels --all-namespaces -o=wide $args" }
function kgposlallowide { Invoke-PrintRunCommand "kubectl get pods --show-labels --all-namespaces -o=wide $args" }
function kgdepslallowide { Invoke-PrintRunCommand "kubectl get deployment --show-labels --all-namespaces -o=wide $args" }
function kgallwowide { Invoke-PrintRunCommand "kubectl get --all-namespaces --watch -o=wide $args" }
function kgpoallwowide { Invoke-PrintRunCommand "kubectl get pods --all-namespaces --watch -o=wide $args" }
function kgdepallwowide { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces --watch -o=wide $args" }
function kgsvcallwowide { Invoke-PrintRunCommand "kubectl get service --all-namespaces --watch -o=wide $args" }
function kgingallwowide { Invoke-PrintRunCommand "kubectl get ingress --all-namespaces --watch -o=wide $args" }
function kgcmallwowide { Invoke-PrintRunCommand "kubectl get configmap --all-namespaces --watch -o=wide $args" }
function kgsecallwowide { Invoke-PrintRunCommand "kubectl get secret --all-namespaces --watch -o=wide $args" }
function kgnsallwowide { Invoke-PrintRunCommand "kubectl get namespaces --all-namespaces --watch -o=wide $args" }
function kgwowideall { Invoke-PrintRunCommand "kubectl get --watch -o=wide --all-namespaces $args" }
function kgpowowideall { Invoke-PrintRunCommand "kubectl get pods --watch -o=wide --all-namespaces $args" }
function kgdepwowideall { Invoke-PrintRunCommand "kubectl get deployment --watch -o=wide --all-namespaces $args" }
function kgsvcwowideall { Invoke-PrintRunCommand "kubectl get service --watch -o=wide --all-namespaces $args" }
function kgingwowideall { Invoke-PrintRunCommand "kubectl get ingress --watch -o=wide --all-namespaces $args" }
function kgcmwowideall { Invoke-PrintRunCommand "kubectl get configmap --watch -o=wide --all-namespaces $args" }
function kgsecwowideall { Invoke-PrintRunCommand "kubectl get secret --watch -o=wide --all-namespaces $args" }
function kgnswowideall { Invoke-PrintRunCommand "kubectl get namespaces --watch -o=wide --all-namespaces $args" }
function kgwallowide { Invoke-PrintRunCommand "kubectl get --watch --all-namespaces -o=wide $args" }
function kgpowallowide { Invoke-PrintRunCommand "kubectl get pods --watch --all-namespaces -o=wide $args" }
function kgdepwallowide { Invoke-PrintRunCommand "kubectl get deployment --watch --all-namespaces -o=wide $args" }
function kgsvcwallowide { Invoke-PrintRunCommand "kubectl get service --watch --all-namespaces -o=wide $args" }
function kgingwallowide { Invoke-PrintRunCommand "kubectl get ingress --watch --all-namespaces -o=wide $args" }
function kgcmwallowide { Invoke-PrintRunCommand "kubectl get configmap --watch --all-namespaces -o=wide $args" }
function kgsecwallowide { Invoke-PrintRunCommand "kubectl get secret --watch --all-namespaces -o=wide $args" }
function kgnswallowide { Invoke-PrintRunCommand "kubectl get namespaces --watch --all-namespaces -o=wide $args" }
function kgslwowide { Invoke-PrintRunCommand "kubectl get --show-labels --watch -o=wide $args" }
function ksysgslwowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --show-labels --watch -o=wide $args" }
function kgposlwowide { Invoke-PrintRunCommand "kubectl get pods --show-labels --watch -o=wide $args" }
function ksysgposlwowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --show-labels --watch -o=wide $args" }
function kgdepslwowide { Invoke-PrintRunCommand "kubectl get deployment --show-labels --watch -o=wide $args" }
function ksysgdepslwowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide $args" }
function kgwowidesl { Invoke-PrintRunCommand "kubectl get --watch -o=wide --show-labels $args" }
function ksysgwowidesl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch -o=wide --show-labels $args" }
function kgpowowidesl { Invoke-PrintRunCommand "kubectl get pods --watch -o=wide --show-labels $args" }
function ksysgpowowidesl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch -o=wide --show-labels $args" }
function kgdepwowidesl { Invoke-PrintRunCommand "kubectl get deployment --watch -o=wide --show-labels $args" }
function ksysgdepwowidesl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels $args" }
function kgwslowide { Invoke-PrintRunCommand "kubectl get --watch --show-labels -o=wide $args" }
function ksysgwslowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch --show-labels -o=wide $args" }
function kgpowslowide { Invoke-PrintRunCommand "kubectl get pods --watch --show-labels -o=wide $args" }
function ksysgpowslowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch --show-labels -o=wide $args" }
function kgdepwslowide { Invoke-PrintRunCommand "kubectl get deployment --watch --show-labels -o=wide $args" }
function ksysgdepwslowide { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide $args" }
function kgallwojson { Invoke-PrintRunCommand "kubectl get --all-namespaces --watch -o=json $args" }
function kgpoallwojson { Invoke-PrintRunCommand "kubectl get pods --all-namespaces --watch -o=json $args" }
function kgdepallwojson { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces --watch -o=json $args" }
function kgsvcallwojson { Invoke-PrintRunCommand "kubectl get service --all-namespaces --watch -o=json $args" }
function kgingallwojson { Invoke-PrintRunCommand "kubectl get ingress --all-namespaces --watch -o=json $args" }
function kgcmallwojson { Invoke-PrintRunCommand "kubectl get configmap --all-namespaces --watch -o=json $args" }
function kgsecallwojson { Invoke-PrintRunCommand "kubectl get secret --all-namespaces --watch -o=json $args" }
function kgnsallwojson { Invoke-PrintRunCommand "kubectl get namespaces --all-namespaces --watch -o=json $args" }
function kgwojsonall { Invoke-PrintRunCommand "kubectl get --watch -o=json --all-namespaces $args" }
function kgpowojsonall { Invoke-PrintRunCommand "kubectl get pods --watch -o=json --all-namespaces $args" }
function kgdepwojsonall { Invoke-PrintRunCommand "kubectl get deployment --watch -o=json --all-namespaces $args" }
function kgsvcwojsonall { Invoke-PrintRunCommand "kubectl get service --watch -o=json --all-namespaces $args" }
function kgingwojsonall { Invoke-PrintRunCommand "kubectl get ingress --watch -o=json --all-namespaces $args" }
function kgcmwojsonall { Invoke-PrintRunCommand "kubectl get configmap --watch -o=json --all-namespaces $args" }
function kgsecwojsonall { Invoke-PrintRunCommand "kubectl get secret --watch -o=json --all-namespaces $args" }
function kgnswojsonall { Invoke-PrintRunCommand "kubectl get namespaces --watch -o=json --all-namespaces $args" }
function kgwallojson { Invoke-PrintRunCommand "kubectl get --watch --all-namespaces -o=json $args" }
function kgpowallojson { Invoke-PrintRunCommand "kubectl get pods --watch --all-namespaces -o=json $args" }
function kgdepwallojson { Invoke-PrintRunCommand "kubectl get deployment --watch --all-namespaces -o=json $args" }
function kgsvcwallojson { Invoke-PrintRunCommand "kubectl get service --watch --all-namespaces -o=json $args" }
function kgingwallojson { Invoke-PrintRunCommand "kubectl get ingress --watch --all-namespaces -o=json $args" }
function kgcmwallojson { Invoke-PrintRunCommand "kubectl get configmap --watch --all-namespaces -o=json $args" }
function kgsecwallojson { Invoke-PrintRunCommand "kubectl get secret --watch --all-namespaces -o=json $args" }
function kgnswallojson { Invoke-PrintRunCommand "kubectl get namespaces --watch --all-namespaces -o=json $args" }
function kgallslw { Invoke-PrintRunCommand "kubectl get --all-namespaces --show-labels --watch $args" }
function kgpoallslw { Invoke-PrintRunCommand "kubectl get pods --all-namespaces --show-labels --watch $args" }
function kgdepallslw { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces --show-labels --watch $args" }
function kgallwsl { Invoke-PrintRunCommand "kubectl get --all-namespaces --watch --show-labels $args" }
function kgpoallwsl { Invoke-PrintRunCommand "kubectl get pods --all-namespaces --watch --show-labels $args" }
function kgdepallwsl { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces --watch --show-labels $args" }
function kgslallw { Invoke-PrintRunCommand "kubectl get --show-labels --all-namespaces --watch $args" }
function kgposlallw { Invoke-PrintRunCommand "kubectl get pods --show-labels --all-namespaces --watch $args" }
function kgdepslallw { Invoke-PrintRunCommand "kubectl get deployment --show-labels --all-namespaces --watch $args" }
function kgslwall { Invoke-PrintRunCommand "kubectl get --show-labels --watch --all-namespaces $args" }
function kgposlwall { Invoke-PrintRunCommand "kubectl get pods --show-labels --watch --all-namespaces $args" }
function kgdepslwall { Invoke-PrintRunCommand "kubectl get deployment --show-labels --watch --all-namespaces $args" }
function kgwallsl { Invoke-PrintRunCommand "kubectl get --watch --all-namespaces --show-labels $args" }
function kgpowallsl { Invoke-PrintRunCommand "kubectl get pods --watch --all-namespaces --show-labels $args" }
function kgdepwallsl { Invoke-PrintRunCommand "kubectl get deployment --watch --all-namespaces --show-labels $args" }
function kgwslall { Invoke-PrintRunCommand "kubectl get --watch --show-labels --all-namespaces $args" }
function kgpowslall { Invoke-PrintRunCommand "kubectl get pods --watch --show-labels --all-namespaces $args" }
function kgdepwslall { Invoke-PrintRunCommand "kubectl get deployment --watch --show-labels --all-namespaces $args" }
function kgallslwowide { Invoke-PrintRunCommand "kubectl get --all-namespaces --show-labels --watch -o=wide $args" }
function kgpoallslwowide { Invoke-PrintRunCommand "kubectl get pods --all-namespaces --show-labels --watch -o=wide $args" }
function kgdepallslwowide { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces --show-labels --watch -o=wide $args" }
function kgallwowidesl { Invoke-PrintRunCommand "kubectl get --all-namespaces --watch -o=wide --show-labels $args" }
function kgpoallwowidesl { Invoke-PrintRunCommand "kubectl get pods --all-namespaces --watch -o=wide --show-labels $args" }
function kgdepallwowidesl { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces --watch -o=wide --show-labels $args" }
function kgallwslowide { Invoke-PrintRunCommand "kubectl get --all-namespaces --watch --show-labels -o=wide $args" }
function kgpoallwslowide { Invoke-PrintRunCommand "kubectl get pods --all-namespaces --watch --show-labels -o=wide $args" }
function kgdepallwslowide { Invoke-PrintRunCommand "kubectl get deployment --all-namespaces --watch --show-labels -o=wide $args" }
function kgslallwowide { Invoke-PrintRunCommand "kubectl get --show-labels --all-namespaces --watch -o=wide $args" }
function kgposlallwowide { Invoke-PrintRunCommand "kubectl get pods --show-labels --all-namespaces --watch -o=wide $args" }
function kgdepslallwowide { Invoke-PrintRunCommand "kubectl get deployment --show-labels --all-namespaces --watch -o=wide $args" }
function kgslwowideall { Invoke-PrintRunCommand "kubectl get --show-labels --watch -o=wide --all-namespaces $args" }
function kgposlwowideall { Invoke-PrintRunCommand "kubectl get pods --show-labels --watch -o=wide --all-namespaces $args" }
function kgdepslwowideall { Invoke-PrintRunCommand "kubectl get deployment --show-labels --watch -o=wide --all-namespaces $args" }
function kgslwallowide { Invoke-PrintRunCommand "kubectl get --show-labels --watch --all-namespaces -o=wide $args" }
function kgposlwallowide { Invoke-PrintRunCommand "kubectl get pods --show-labels --watch --all-namespaces -o=wide $args" }
function kgdepslwallowide { Invoke-PrintRunCommand "kubectl get deployment --show-labels --watch --all-namespaces -o=wide $args" }
function kgwowideallsl { Invoke-PrintRunCommand "kubectl get --watch -o=wide --all-namespaces --show-labels $args" }
function kgpowowideallsl { Invoke-PrintRunCommand "kubectl get pods --watch -o=wide --all-namespaces --show-labels $args" }
function kgdepwowideallsl { Invoke-PrintRunCommand "kubectl get deployment --watch -o=wide --all-namespaces --show-labels $args" }
function kgwowideslall { Invoke-PrintRunCommand "kubectl get --watch -o=wide --show-labels --all-namespaces $args" }
function kgpowowideslall { Invoke-PrintRunCommand "kubectl get pods --watch -o=wide --show-labels --all-namespaces $args" }
function kgdepwowideslall { Invoke-PrintRunCommand "kubectl get deployment --watch -o=wide --show-labels --all-namespaces $args" }
function kgwallowidesl { Invoke-PrintRunCommand "kubectl get --watch --all-namespaces -o=wide --show-labels $args" }
function kgpowallowidesl { Invoke-PrintRunCommand "kubectl get pods --watch --all-namespaces -o=wide --show-labels $args" }
function kgdepwallowidesl { Invoke-PrintRunCommand "kubectl get deployment --watch --all-namespaces -o=wide --show-labels $args" }
function kgwallslowide { Invoke-PrintRunCommand "kubectl get --watch --all-namespaces --show-labels -o=wide $args" }
function kgpowallslowide { Invoke-PrintRunCommand "kubectl get pods --watch --all-namespaces --show-labels -o=wide $args" }
function kgdepwallslowide { Invoke-PrintRunCommand "kubectl get deployment --watch --all-namespaces --show-labels -o=wide $args" }
function kgwslowideall { Invoke-PrintRunCommand "kubectl get --watch --show-labels -o=wide --all-namespaces $args" }
function kgpowslowideall { Invoke-PrintRunCommand "kubectl get pods --watch --show-labels -o=wide --all-namespaces $args" }
function kgdepwslowideall { Invoke-PrintRunCommand "kubectl get deployment --watch --show-labels -o=wide --all-namespaces $args" }
function kgwslallowide { Invoke-PrintRunCommand "kubectl get --watch --show-labels --all-namespaces -o=wide $args" }
function kgpowslallowide { Invoke-PrintRunCommand "kubectl get pods --watch --show-labels --all-namespaces -o=wide $args" }
function kgdepwslallowide { Invoke-PrintRunCommand "kubectl get deployment --watch --show-labels --all-namespaces -o=wide $args" }
function kgf { Invoke-PrintRunCommand "kubectl get --recursive -f $args" }
function kdf { Invoke-PrintRunCommand "kubectl describe --recursive -f $args" }
function krmf { Invoke-PrintRunCommand "kubectl delete --recursive -f $args" }
function kgoyamlf { Invoke-PrintRunCommand "kubectl get -o=yaml --recursive -f $args" }
function kgowidef { Invoke-PrintRunCommand "kubectl get -o=wide --recursive -f $args" }
function kgojsonf { Invoke-PrintRunCommand "kubectl get -o=json --recursive -f $args" }
function kgslf { Invoke-PrintRunCommand "kubectl get --show-labels --recursive -f $args" }
function kgwf { Invoke-PrintRunCommand "kubectl get --watch --recursive -f $args" }
function kgwoyamlf { Invoke-PrintRunCommand "kubectl get --watch -o=yaml --recursive -f $args" }
function kgowideslf { Invoke-PrintRunCommand "kubectl get -o=wide --show-labels --recursive -f $args" }
function kgslowidef { Invoke-PrintRunCommand "kubectl get --show-labels -o=wide --recursive -f $args" }
function kgwowidef { Invoke-PrintRunCommand "kubectl get --watch -o=wide --recursive -f $args" }
function kgwojsonf { Invoke-PrintRunCommand "kubectl get --watch -o=json --recursive -f $args" }
function kgslwf { Invoke-PrintRunCommand "kubectl get --show-labels --watch --recursive -f $args" }
function kgwslf { Invoke-PrintRunCommand "kubectl get --watch --show-labels --recursive -f $args" }
function kgslwowidef { Invoke-PrintRunCommand "kubectl get --show-labels --watch -o=wide --recursive -f $args" }
function kgwowideslf { Invoke-PrintRunCommand "kubectl get --watch -o=wide --show-labels --recursive -f $args" }
function kgwslowidef { Invoke-PrintRunCommand "kubectl get --watch --show-labels -o=wide --recursive -f $args" }
function kgl { Invoke-PrintRunCommand "kubectl get -l $args" }
function ksysgl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get -l $args" }
function kdl { Invoke-PrintRunCommand "kubectl describe -l $args" }
function ksysdl { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe -l $args" }
function krml { Invoke-PrintRunCommand "kubectl delete -l $args" }
function ksysrml { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete -l $args" }
function kgpol { Invoke-PrintRunCommand "kubectl get pods -l $args" }
function ksysgpol { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods -l $args" }
function kdpol { Invoke-PrintRunCommand "kubectl describe pods -l $args" }
function ksysdpol { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe pods -l $args" }
function krmpol { Invoke-PrintRunCommand "kubectl delete pods -l $args" }
function ksysrmpol { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete pods -l $args" }
function kgdepl { Invoke-PrintRunCommand "kubectl get deployment -l $args" }
function ksysgdepl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment -l $args" }
function kddepl { Invoke-PrintRunCommand "kubectl describe deployment -l $args" }
function ksysddepl { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe deployment -l $args" }
function krmdepl { Invoke-PrintRunCommand "kubectl delete deployment -l $args" }
function ksysrmdepl { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete deployment -l $args" }
function kgsvcl { Invoke-PrintRunCommand "kubectl get service -l $args" }
function ksysgsvcl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service -l $args" }
function kdsvcl { Invoke-PrintRunCommand "kubectl describe service -l $args" }
function ksysdsvcl { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe service -l $args" }
function krmsvcl { Invoke-PrintRunCommand "kubectl delete service -l $args" }
function ksysrmsvcl { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete service -l $args" }
function kgingl { Invoke-PrintRunCommand "kubectl get ingress -l $args" }
function ksysgingl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress -l $args" }
function kdingl { Invoke-PrintRunCommand "kubectl describe ingress -l $args" }
function ksysdingl { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe ingress -l $args" }
function krmingl { Invoke-PrintRunCommand "kubectl delete ingress -l $args" }
function ksysrmingl { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete ingress -l $args" }
function kgcml { Invoke-PrintRunCommand "kubectl get configmap -l $args" }
function ksysgcml { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap -l $args" }
function kdcml { Invoke-PrintRunCommand "kubectl describe configmap -l $args" }
function ksysdcml { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe configmap -l $args" }
function krmcml { Invoke-PrintRunCommand "kubectl delete configmap -l $args" }
function ksysrmcml { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete configmap -l $args" }
function kgsecl { Invoke-PrintRunCommand "kubectl get secret -l $args" }
function ksysgsecl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret -l $args" }
function kdsecl { Invoke-PrintRunCommand "kubectl describe secret -l $args" }
function ksysdsecl { Invoke-PrintRunCommand "kubectl --namespace=kube-system describe secret -l $args" }
function krmsecl { Invoke-PrintRunCommand "kubectl delete secret -l $args" }
function ksysrmsecl { Invoke-PrintRunCommand "kubectl --namespace=kube-system delete secret -l $args" }
function kgnol { Invoke-PrintRunCommand "kubectl get nodes -l $args" }
function kdnol { Invoke-PrintRunCommand "kubectl describe nodes -l $args" }
function kgnsl { Invoke-PrintRunCommand "kubectl get namespaces -l $args" }
function kdnsl { Invoke-PrintRunCommand "kubectl describe namespaces -l $args" }
function krmnsl { Invoke-PrintRunCommand "kubectl delete namespaces -l $args" }
function kgoyamll { Invoke-PrintRunCommand "kubectl get -o=yaml -l $args" }
function ksysgoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get -o=yaml -l $args" }
function kgpooyamll { Invoke-PrintRunCommand "kubectl get pods -o=yaml -l $args" }
function ksysgpooyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods -o=yaml -l $args" }
function kgdepoyamll { Invoke-PrintRunCommand "kubectl get deployment -o=yaml -l $args" }
function ksysgdepoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment -o=yaml -l $args" }
function kgsvcoyamll { Invoke-PrintRunCommand "kubectl get service -o=yaml -l $args" }
function ksysgsvcoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service -o=yaml -l $args" }
function kgingoyamll { Invoke-PrintRunCommand "kubectl get ingress -o=yaml -l $args" }
function ksysgingoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress -o=yaml -l $args" }
function kgcmoyamll { Invoke-PrintRunCommand "kubectl get configmap -o=yaml -l $args" }
function ksysgcmoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap -o=yaml -l $args" }
function kgsecoyamll { Invoke-PrintRunCommand "kubectl get secret -o=yaml -l $args" }
function ksysgsecoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret -o=yaml -l $args" }
function kgnooyamll { Invoke-PrintRunCommand "kubectl get nodes -o=yaml -l $args" }
function kgnsoyamll { Invoke-PrintRunCommand "kubectl get namespaces -o=yaml -l $args" }
function kgowidel { Invoke-PrintRunCommand "kubectl get -o=wide -l $args" }
function ksysgowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get -o=wide -l $args" }
function kgpoowidel { Invoke-PrintRunCommand "kubectl get pods -o=wide -l $args" }
function ksysgpoowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods -o=wide -l $args" }
function kgdepowidel { Invoke-PrintRunCommand "kubectl get deployment -o=wide -l $args" }
function ksysgdepowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment -o=wide -l $args" }
function kgsvcowidel { Invoke-PrintRunCommand "kubectl get service -o=wide -l $args" }
function ksysgsvcowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service -o=wide -l $args" }
function kgingowidel { Invoke-PrintRunCommand "kubectl get ingress -o=wide -l $args" }
function ksysgingowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress -o=wide -l $args" }
function kgcmowidel { Invoke-PrintRunCommand "kubectl get configmap -o=wide -l $args" }
function ksysgcmowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap -o=wide -l $args" }
function kgsecowidel { Invoke-PrintRunCommand "kubectl get secret -o=wide -l $args" }
function ksysgsecowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret -o=wide -l $args" }
function kgnoowidel { Invoke-PrintRunCommand "kubectl get nodes -o=wide -l $args" }
function kgnsowidel { Invoke-PrintRunCommand "kubectl get namespaces -o=wide -l $args" }
function kgojsonl { Invoke-PrintRunCommand "kubectl get -o=json -l $args" }
function ksysgojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get -o=json -l $args" }
function kgpoojsonl { Invoke-PrintRunCommand "kubectl get pods -o=json -l $args" }
function ksysgpoojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods -o=json -l $args" }
function kgdepojsonl { Invoke-PrintRunCommand "kubectl get deployment -o=json -l $args" }
function ksysgdepojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment -o=json -l $args" }
function kgsvcojsonl { Invoke-PrintRunCommand "kubectl get service -o=json -l $args" }
function ksysgsvcojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service -o=json -l $args" }
function kgingojsonl { Invoke-PrintRunCommand "kubectl get ingress -o=json -l $args" }
function ksysgingojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress -o=json -l $args" }
function kgcmojsonl { Invoke-PrintRunCommand "kubectl get configmap -o=json -l $args" }
function ksysgcmojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap -o=json -l $args" }
function kgsecojsonl { Invoke-PrintRunCommand "kubectl get secret -o=json -l $args" }
function ksysgsecojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret -o=json -l $args" }
function kgnoojsonl { Invoke-PrintRunCommand "kubectl get nodes -o=json -l $args" }
function kgnsojsonl { Invoke-PrintRunCommand "kubectl get namespaces -o=json -l $args" }
function kgsll { Invoke-PrintRunCommand "kubectl get --show-labels -l $args" }
function ksysgsll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --show-labels -l $args" }
function kgposll { Invoke-PrintRunCommand "kubectl get pods --show-labels -l $args" }
function ksysgposll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --show-labels -l $args" }
function kgdepsll { Invoke-PrintRunCommand "kubectl get deployment --show-labels -l $args" }
function ksysgdepsll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --show-labels -l $args" }
function kgwl { Invoke-PrintRunCommand "kubectl get --watch -l $args" }
function ksysgwl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch -l $args" }
function kgpowl { Invoke-PrintRunCommand "kubectl get pods --watch -l $args" }
function ksysgpowl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch -l $args" }
function kgdepwl { Invoke-PrintRunCommand "kubectl get deployment --watch -l $args" }
function ksysgdepwl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch -l $args" }
function kgsvcwl { Invoke-PrintRunCommand "kubectl get service --watch -l $args" }
function ksysgsvcwl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service --watch -l $args" }
function kgingwl { Invoke-PrintRunCommand "kubectl get ingress --watch -l $args" }
function ksysgingwl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress --watch -l $args" }
function kgcmwl { Invoke-PrintRunCommand "kubectl get configmap --watch -l $args" }
function ksysgcmwl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap --watch -l $args" }
function kgsecwl { Invoke-PrintRunCommand "kubectl get secret --watch -l $args" }
function ksysgsecwl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret --watch -l $args" }
function kgnowl { Invoke-PrintRunCommand "kubectl get nodes --watch -l $args" }
function kgnswl { Invoke-PrintRunCommand "kubectl get namespaces --watch -l $args" }
function kgwoyamll { Invoke-PrintRunCommand "kubectl get --watch -o=yaml -l $args" }
function ksysgwoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch -o=yaml -l $args" }
function kgpowoyamll { Invoke-PrintRunCommand "kubectl get pods --watch -o=yaml -l $args" }
function ksysgpowoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch -o=yaml -l $args" }
function kgdepwoyamll { Invoke-PrintRunCommand "kubectl get deployment --watch -o=yaml -l $args" }
function ksysgdepwoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch -o=yaml -l $args" }
function kgsvcwoyamll { Invoke-PrintRunCommand "kubectl get service --watch -o=yaml -l $args" }
function ksysgsvcwoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service --watch -o=yaml -l $args" }
function kgingwoyamll { Invoke-PrintRunCommand "kubectl get ingress --watch -o=yaml -l $args" }
function ksysgingwoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress --watch -o=yaml -l $args" }
function kgcmwoyamll { Invoke-PrintRunCommand "kubectl get configmap --watch -o=yaml -l $args" }
function ksysgcmwoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap --watch -o=yaml -l $args" }
function kgsecwoyamll { Invoke-PrintRunCommand "kubectl get secret --watch -o=yaml -l $args" }
function ksysgsecwoyamll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret --watch -o=yaml -l $args" }
function kgnowoyamll { Invoke-PrintRunCommand "kubectl get nodes --watch -o=yaml -l $args" }
function kgnswoyamll { Invoke-PrintRunCommand "kubectl get namespaces --watch -o=yaml -l $args" }
function kgowidesll { Invoke-PrintRunCommand "kubectl get -o=wide --show-labels -l $args" }
function ksysgowidesll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get -o=wide --show-labels -l $args" }
function kgpoowidesll { Invoke-PrintRunCommand "kubectl get pods -o=wide --show-labels -l $args" }
function ksysgpoowidesll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods -o=wide --show-labels -l $args" }
function kgdepowidesll { Invoke-PrintRunCommand "kubectl get deployment -o=wide --show-labels -l $args" }
function ksysgdepowidesll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment -o=wide --show-labels -l $args" }
function kgslowidel { Invoke-PrintRunCommand "kubectl get --show-labels -o=wide -l $args" }
function ksysgslowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --show-labels -o=wide -l $args" }
function kgposlowidel { Invoke-PrintRunCommand "kubectl get pods --show-labels -o=wide -l $args" }
function ksysgposlowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --show-labels -o=wide -l $args" }
function kgdepslowidel { Invoke-PrintRunCommand "kubectl get deployment --show-labels -o=wide -l $args" }
function ksysgdepslowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --show-labels -o=wide -l $args" }
function kgwowidel { Invoke-PrintRunCommand "kubectl get --watch -o=wide -l $args" }
function ksysgwowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch -o=wide -l $args" }
function kgpowowidel { Invoke-PrintRunCommand "kubectl get pods --watch -o=wide -l $args" }
function ksysgpowowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch -o=wide -l $args" }
function kgdepwowidel { Invoke-PrintRunCommand "kubectl get deployment --watch -o=wide -l $args" }
function ksysgdepwowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch -o=wide -l $args" }
function kgsvcwowidel { Invoke-PrintRunCommand "kubectl get service --watch -o=wide -l $args" }
function ksysgsvcwowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service --watch -o=wide -l $args" }
function kgingwowidel { Invoke-PrintRunCommand "kubectl get ingress --watch -o=wide -l $args" }
function ksysgingwowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress --watch -o=wide -l $args" }
function kgcmwowidel { Invoke-PrintRunCommand "kubectl get configmap --watch -o=wide -l $args" }
function ksysgcmwowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap --watch -o=wide -l $args" }
function kgsecwowidel { Invoke-PrintRunCommand "kubectl get secret --watch -o=wide -l $args" }
function ksysgsecwowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret --watch -o=wide -l $args" }
function kgnowowidel { Invoke-PrintRunCommand "kubectl get nodes --watch -o=wide -l $args" }
function kgnswowidel { Invoke-PrintRunCommand "kubectl get namespaces --watch -o=wide -l $args" }
function kgwojsonl { Invoke-PrintRunCommand "kubectl get --watch -o=json -l $args" }
function ksysgwojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch -o=json -l $args" }
function kgpowojsonl { Invoke-PrintRunCommand "kubectl get pods --watch -o=json -l $args" }
function ksysgpowojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch -o=json -l $args" }
function kgdepwojsonl { Invoke-PrintRunCommand "kubectl get deployment --watch -o=json -l $args" }
function ksysgdepwojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch -o=json -l $args" }
function kgsvcwojsonl { Invoke-PrintRunCommand "kubectl get service --watch -o=json -l $args" }
function ksysgsvcwojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get service --watch -o=json -l $args" }
function kgingwojsonl { Invoke-PrintRunCommand "kubectl get ingress --watch -o=json -l $args" }
function ksysgingwojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get ingress --watch -o=json -l $args" }
function kgcmwojsonl { Invoke-PrintRunCommand "kubectl get configmap --watch -o=json -l $args" }
function ksysgcmwojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get configmap --watch -o=json -l $args" }
function kgsecwojsonl { Invoke-PrintRunCommand "kubectl get secret --watch -o=json -l $args" }
function ksysgsecwojsonl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get secret --watch -o=json -l $args" }
function kgnowojsonl { Invoke-PrintRunCommand "kubectl get nodes --watch -o=json -l $args" }
function kgnswojsonl { Invoke-PrintRunCommand "kubectl get namespaces --watch -o=json -l $args" }
function kgslwl { Invoke-PrintRunCommand "kubectl get --show-labels --watch -l $args" }
function ksysgslwl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --show-labels --watch -l $args" }
function kgposlwl { Invoke-PrintRunCommand "kubectl get pods --show-labels --watch -l $args" }
function ksysgposlwl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --show-labels --watch -l $args" }
function kgdepslwl { Invoke-PrintRunCommand "kubectl get deployment --show-labels --watch -l $args" }
function ksysgdepslwl { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --show-labels --watch -l $args" }
function kgwsll { Invoke-PrintRunCommand "kubectl get --watch --show-labels -l $args" }
function ksysgwsll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch --show-labels -l $args" }
function kgpowsll { Invoke-PrintRunCommand "kubectl get pods --watch --show-labels -l $args" }
function ksysgpowsll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch --show-labels -l $args" }
function kgdepwsll { Invoke-PrintRunCommand "kubectl get deployment --watch --show-labels -l $args" }
function ksysgdepwsll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch --show-labels -l $args" }
function kgslwowidel { Invoke-PrintRunCommand "kubectl get --show-labels --watch -o=wide -l $args" }
function ksysgslwowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --show-labels --watch -o=wide -l $args" }
function kgposlwowidel { Invoke-PrintRunCommand "kubectl get pods --show-labels --watch -o=wide -l $args" }
function ksysgposlwowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --show-labels --watch -o=wide -l $args" }
function kgdepslwowidel { Invoke-PrintRunCommand "kubectl get deployment --show-labels --watch -o=wide -l $args" }
function ksysgdepslwowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide -l $args" }
function kgwowidesll { Invoke-PrintRunCommand "kubectl get --watch -o=wide --show-labels -l $args" }
function ksysgwowidesll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch -o=wide --show-labels -l $args" }
function kgpowowidesll { Invoke-PrintRunCommand "kubectl get pods --watch -o=wide --show-labels -l $args" }
function ksysgpowowidesll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch -o=wide --show-labels -l $args" }
function kgdepwowidesll { Invoke-PrintRunCommand "kubectl get deployment --watch -o=wide --show-labels -l $args" }
function ksysgdepwowidesll { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels -l $args" }
function kgwslowidel { Invoke-PrintRunCommand "kubectl get --watch --show-labels -o=wide -l $args" }
function ksysgwslowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get --watch --show-labels -o=wide -l $args" }
function kgpowslowidel { Invoke-PrintRunCommand "kubectl get pods --watch --show-labels -o=wide -l $args" }
function ksysgpowslowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get pods --watch --show-labels -o=wide -l $args" }
function kgdepwslowidel { Invoke-PrintRunCommand "kubectl get deployment --watch --show-labels -o=wide -l $args" }
function ksysgdepwslowidel { Invoke-PrintRunCommand "kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide -l $args" }
function kexn { Invoke-PrintRunCommand "kubectl exec -i -t --namespace $args" }
function klon { Invoke-PrintRunCommand "kubectl logs -f --namespace $args" }
function kpfn { Invoke-PrintRunCommand "kubectl port-forward --namespace $args" }
function kgn { Invoke-PrintRunCommand "kubectl get --namespace $args" }
function kdn { Invoke-PrintRunCommand "kubectl describe --namespace $args" }
function krmn { Invoke-PrintRunCommand "kubectl delete --namespace $args" }
function kgpon { Invoke-PrintRunCommand "kubectl get pods --namespace $args" }
function kdpon { Invoke-PrintRunCommand "kubectl describe pods --namespace $args" }
function krmpon { Invoke-PrintRunCommand "kubectl delete pods --namespace $args" }
function kgdepn { Invoke-PrintRunCommand "kubectl get deployment --namespace $args" }
function kddepn { Invoke-PrintRunCommand "kubectl describe deployment --namespace $args" }
function krmdepn { Invoke-PrintRunCommand "kubectl delete deployment --namespace $args" }
function kgsvcn { Invoke-PrintRunCommand "kubectl get service --namespace $args" }
function kdsvcn { Invoke-PrintRunCommand "kubectl describe service --namespace $args" }
function krmsvcn { Invoke-PrintRunCommand "kubectl delete service --namespace $args" }
function kgingn { Invoke-PrintRunCommand "kubectl get ingress --namespace $args" }
function kdingn { Invoke-PrintRunCommand "kubectl describe ingress --namespace $args" }
function krmingn { Invoke-PrintRunCommand "kubectl delete ingress --namespace $args" }
function kgcmn { Invoke-PrintRunCommand "kubectl get configmap --namespace $args" }
function kdcmn { Invoke-PrintRunCommand "kubectl describe configmap --namespace $args" }
function krmcmn { Invoke-PrintRunCommand "kubectl delete configmap --namespace $args" }
function kgsecn { Invoke-PrintRunCommand "kubectl get secret --namespace $args" }
function kdsecn { Invoke-PrintRunCommand "kubectl describe secret --namespace $args" }
function krmsecn { Invoke-PrintRunCommand "kubectl delete secret --namespace $args" }
function kgoyamln { Invoke-PrintRunCommand "kubectl get -o=yaml --namespace $args" }
function kgpooyamln { Invoke-PrintRunCommand "kubectl get pods -o=yaml --namespace $args" }
function kgdepoyamln { Invoke-PrintRunCommand "kubectl get deployment -o=yaml --namespace $args" }
function kgsvcoyamln { Invoke-PrintRunCommand "kubectl get service -o=yaml --namespace $args" }
function kgingoyamln { Invoke-PrintRunCommand "kubectl get ingress -o=yaml --namespace $args" }
function kgcmoyamln { Invoke-PrintRunCommand "kubectl get configmap -o=yaml --namespace $args" }
function kgsecoyamln { Invoke-PrintRunCommand "kubectl get secret -o=yaml --namespace $args" }
function kgowiden { Invoke-PrintRunCommand "kubectl get -o=wide --namespace $args" }
function kgpoowiden { Invoke-PrintRunCommand "kubectl get pods -o=wide --namespace $args" }
function kgdepowiden { Invoke-PrintRunCommand "kubectl get deployment -o=wide --namespace $args" }
function kgsvcowiden { Invoke-PrintRunCommand "kubectl get service -o=wide --namespace $args" }
function kgingowiden { Invoke-PrintRunCommand "kubectl get ingress -o=wide --namespace $args" }
function kgcmowiden { Invoke-PrintRunCommand "kubectl get configmap -o=wide --namespace $args" }
function kgsecowiden { Invoke-PrintRunCommand "kubectl get secret -o=wide --namespace $args" }
function kgojsonn { Invoke-PrintRunCommand "kubectl get -o=json --namespace $args" }
function kgpoojsonn { Invoke-PrintRunCommand "kubectl get pods -o=json --namespace $args" }
function kgdepojsonn { Invoke-PrintRunCommand "kubectl get deployment -o=json --namespace $args" }
function kgsvcojsonn { Invoke-PrintRunCommand "kubectl get service -o=json --namespace $args" }
function kgingojsonn { Invoke-PrintRunCommand "kubectl get ingress -o=json --namespace $args" }
function kgcmojsonn { Invoke-PrintRunCommand "kubectl get configmap -o=json --namespace $args" }
function kgsecojsonn { Invoke-PrintRunCommand "kubectl get secret -o=json --namespace $args" }
function kgsln { Invoke-PrintRunCommand "kubectl get --show-labels --namespace $args" }
function kgposln { Invoke-PrintRunCommand "kubectl get pods --show-labels --namespace $args" }
function kgdepsln { Invoke-PrintRunCommand "kubectl get deployment --show-labels --namespace $args" }
function kgwn { Invoke-PrintRunCommand "kubectl get --watch --namespace $args" }
function kgpown { Invoke-PrintRunCommand "kubectl get pods --watch --namespace $args" }
function kgdepwn { Invoke-PrintRunCommand "kubectl get deployment --watch --namespace $args" }
function kgsvcwn { Invoke-PrintRunCommand "kubectl get service --watch --namespace $args" }
function kgingwn { Invoke-PrintRunCommand "kubectl get ingress --watch --namespace $args" }
function kgcmwn { Invoke-PrintRunCommand "kubectl get configmap --watch --namespace $args" }
function kgsecwn { Invoke-PrintRunCommand "kubectl get secret --watch --namespace $args" }
function kgwoyamln { Invoke-PrintRunCommand "kubectl get --watch -o=yaml --namespace $args" }
function kgpowoyamln { Invoke-PrintRunCommand "kubectl get pods --watch -o=yaml --namespace $args" }
function kgdepwoyamln { Invoke-PrintRunCommand "kubectl get deployment --watch -o=yaml --namespace $args" }
function kgsvcwoyamln { Invoke-PrintRunCommand "kubectl get service --watch -o=yaml --namespace $args" }
function kgingwoyamln { Invoke-PrintRunCommand "kubectl get ingress --watch -o=yaml --namespace $args" }
function kgcmwoyamln { Invoke-PrintRunCommand "kubectl get configmap --watch -o=yaml --namespace $args" }
function kgsecwoyamln { Invoke-PrintRunCommand "kubectl get secret --watch -o=yaml --namespace $args" }
function kgowidesln { Invoke-PrintRunCommand "kubectl get -o=wide --show-labels --namespace $args" }
function kgpoowidesln { Invoke-PrintRunCommand "kubectl get pods -o=wide --show-labels --namespace $args" }
function kgdepowidesln { Invoke-PrintRunCommand "kubectl get deployment -o=wide --show-labels --namespace $args" }
function kgslowiden { Invoke-PrintRunCommand "kubectl get --show-labels -o=wide --namespace $args" }
function kgposlowiden { Invoke-PrintRunCommand "kubectl get pods --show-labels -o=wide --namespace $args" }
function kgdepslowiden { Invoke-PrintRunCommand "kubectl get deployment --show-labels -o=wide --namespace $args" }
function kgwowiden { Invoke-PrintRunCommand "kubectl get --watch -o=wide --namespace $args" }
function kgpowowiden { Invoke-PrintRunCommand "kubectl get pods --watch -o=wide --namespace $args" }
function kgdepwowiden { Invoke-PrintRunCommand "kubectl get deployment --watch -o=wide --namespace $args" }
function kgsvcwowiden { Invoke-PrintRunCommand "kubectl get service --watch -o=wide --namespace $args" }
function kgingwowiden { Invoke-PrintRunCommand "kubectl get ingress --watch -o=wide --namespace $args" }
function kgcmwowiden { Invoke-PrintRunCommand "kubectl get configmap --watch -o=wide --namespace $args" }
function kgsecwowiden { Invoke-PrintRunCommand "kubectl get secret --watch -o=wide --namespace $args" }
function kgwojsonn { Invoke-PrintRunCommand "kubectl get --watch -o=json --namespace $args" }
function kgpowojsonn { Invoke-PrintRunCommand "kubectl get pods --watch -o=json --namespace $args" }
function kgdepwojsonn { Invoke-PrintRunCommand "kubectl get deployment --watch -o=json --namespace $args" }
function kgsvcwojsonn { Invoke-PrintRunCommand "kubectl get service --watch -o=json --namespace $args" }
function kgingwojsonn { Invoke-PrintRunCommand "kubectl get ingress --watch -o=json --namespace $args" }
function kgcmwojsonn { Invoke-PrintRunCommand "kubectl get configmap --watch -o=json --namespace $args" }
function kgsecwojsonn { Invoke-PrintRunCommand "kubectl get secret --watch -o=json --namespace $args" }
function kgslwn { Invoke-PrintRunCommand "kubectl get --show-labels --watch --namespace $args" }
function kgposlwn { Invoke-PrintRunCommand "kubectl get pods --show-labels --watch --namespace $args" }
function kgdepslwn { Invoke-PrintRunCommand "kubectl get deployment --show-labels --watch --namespace $args" }
function kgwsln { Invoke-PrintRunCommand "kubectl get --watch --show-labels --namespace $args" }
function kgpowsln { Invoke-PrintRunCommand "kubectl get pods --watch --show-labels --namespace $args" }
function kgdepwsln { Invoke-PrintRunCommand "kubectl get deployment --watch --show-labels --namespace $args" }
function kgslwowiden { Invoke-PrintRunCommand "kubectl get --show-labels --watch -o=wide --namespace $args" }
function kgposlwowiden { Invoke-PrintRunCommand "kubectl get pods --show-labels --watch -o=wide --namespace $args" }
function kgdepslwowiden { Invoke-PrintRunCommand "kubectl get deployment --show-labels --watch -o=wide --namespace $args" }
function kgwowidesln { Invoke-PrintRunCommand "kubectl get --watch -o=wide --show-labels --namespace $args" }
function kgpowowidesln { Invoke-PrintRunCommand "kubectl get pods --watch -o=wide --show-labels --namespace $args" }
function kgdepwowidesln { Invoke-PrintRunCommand "kubectl get deployment --watch -o=wide --show-labels --namespace $args" }
function kgwslowiden { Invoke-PrintRunCommand "kubectl get --watch --show-labels -o=wide --namespace $args" }
function kgpowslowiden { Invoke-PrintRunCommand "kubectl get pods --watch --show-labels -o=wide --namespace $args" }
function kgdepwslowiden { Invoke-PrintRunCommand "kubectl get deployment --watch --show-labels -o=wide --namespace $args" }

#endregion
