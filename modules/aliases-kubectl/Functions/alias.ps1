function kinf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('cluster-info')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kav {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('api-versions')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kcv {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecKubectl -Command @('config', 'view') @PSBoundParameters
}
function ksys {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ka {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('apply', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kadryc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('apply', '--recursive', '--dry-run=client', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kadrys {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('apply', '--recursive', '--dry-run=server', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysa {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'apply', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kak {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('apply', '-k')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kk {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('kustomize')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmk {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', '-k')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kre {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('replace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kre! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('replace', '--force')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kref {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('replace', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kref! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('replace', '--force', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysex {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'exec', '-i', '-t')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksyslo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'logs', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksyslop {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'logs', '-f', '-p')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kp {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('proxy')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kpf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('port-forward')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kg {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysg {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krun {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('run', '--rm', '--restart=Never', '--image-pull-policy=IfNotPresent', '-i', '-t')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrun {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'run', '--rm', '--restart=Never', '--image-pull-policy=IfNotPresent', '-i', '-t')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysdpo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'pods')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmpo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'pods')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmpo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'pods')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdep {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdep {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kddep {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'deployment')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysddep {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'deployment')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmdep {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'deployment')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmdep {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'deployment')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdsvc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'service')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysdsvc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'service')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmsvc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'service')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmsvc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'service')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kging {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysging {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kding {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'ingress')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysding {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'ingress')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krming {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'ingress')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrming {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'ingress')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdcm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'configmap')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysdcm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'configmap')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmcm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'configmap')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmcm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'configmap')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsec {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdsec {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'secret')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysdsec {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'secret')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmsec {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'secret')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmsec {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'secret')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgno {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdno {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'nodes')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgns {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdns {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmns {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpooyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpooyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnooyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpoowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnoowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpoojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnoojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kga {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdpoall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'pods', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kddepall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'deployment', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdsvcall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'service', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdingall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'ingress', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdcmall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'configmap', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdsecall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'secret', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdnsall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'namespaces', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgposl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmpoall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'pods', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmpoall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'pods', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmdepall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'deployment', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmdepall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'deployment', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmsvcall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'service', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmsvcall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'service', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmingall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'ingress', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmingall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'ingress', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmcmall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'configmap', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmcmall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'configmap', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmsecall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'secret', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmsecall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'secret', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmnsall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'namespaces', '--all')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpow {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpow {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnow {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpooyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnowoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpoowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgposlowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnowowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnowojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcallw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--all-namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingallw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--all-namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmallw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--all-namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecallw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--all-namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsallw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--all-namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgslw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--show-labels', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgposlw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--show-labels', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepslw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--show-labels', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcallwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--all-namespaces', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingallwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--all-namespaces', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmallwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--all-namespaces', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecallwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--all-namespaces', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsallwoyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--all-namespaces', '--watch', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswoyamlall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '-o=yaml', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswalloyaml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '--all-namespaces', '-o=yaml')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgowideallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=wide', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoowideallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=wide', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepowideallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=wide', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgowideslall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=wide', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoowideslall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=wide', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepowideslall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=wide', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcallwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--all-namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingallwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--all-namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmallwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--all-namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecallwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--all-namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsallwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--all-namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgslwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--show-labels', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgposlwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--show-labels', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepslwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--show-labels', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcallwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--all-namespaces', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingallwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--all-namespaces', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmallwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--all-namespaces', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecallwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--all-namespaces', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsallwojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--all-namespaces', '--watch', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswojsonall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '-o=json', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswallojson {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '--all-namespaces', '-o=json')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallslw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '--show-labels', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallslw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '--show-labels', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallslw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '--show-labels', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallwsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '--watch', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallwsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '--watch', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallwsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '--watch', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslallw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--all-namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlallw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--all-namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslallw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--all-namespaces', '--watch')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslwall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--watch', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlwall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--watch', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslwall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--watch', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwslall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowslall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwslall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallslwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '--show-labels', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallslwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '--show-labels', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallslwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '--show-labels', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallwowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '--watch', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallwowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '--watch', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallwowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '--watch', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgallwslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--all-namespaces', '--watch', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoallwslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--all-namespaces', '--watch', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepallwslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--all-namespaces', '--watch', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslallwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--all-namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlallwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--all-namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslallwowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--all-namespaces', '--watch', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslwowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--watch', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlwowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--watch', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslwowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--watch', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslwallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--watch', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlwallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--watch', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslwallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--watch', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwowideallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=wide', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowowideallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=wide', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwowideallsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=wide', '--all-namespaces', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwowideslall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=wide', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowowideslall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=wide', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwowideslall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=wide', '--show-labels', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwallowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--all-namespaces', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowallowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--all-namespaces', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwallowidesl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--all-namespaces', '-o=wide', '--show-labels')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwallslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--all-namespaces', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowallslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--all-namespaces', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwallslowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--all-namespaces', '--show-labels', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwslowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--show-labels', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowslowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--show-labels', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwslowideall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--show-labels', '-o=wide', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwslallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--show-labels', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowslallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--show-labels', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwslallowide {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--show-labels', '--all-namespaces', '-o=wide')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgoyamlf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=yaml', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgowidef {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=wide', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgojsonf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=json', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwoyamlf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=yaml', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgowideslf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=wide', '--show-labels', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslowidef {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '-o=wide', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwowidef {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=wide', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwojsonf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=json', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslwf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--watch', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwslf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--show-labels', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslwowidef {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--watch', '-o=wide', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwowideslf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=wide', '--show-labels', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwslowidef {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--show-labels', '-o=wide', '--recursive', '-f')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysdl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpol {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpol {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdpol {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'pods', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysdpol {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'pods', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmpol {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'pods', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmpol {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'pods', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kddepl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'deployment', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysddepl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'deployment', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmdepl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'deployment', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmdepl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'deployment', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdsvcl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'service', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysdsvcl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'service', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmsvcl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'service', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmsvcl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'service', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdingl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'ingress', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysdingl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'ingress', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmingl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'ingress', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmingl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'ingress', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdcml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'configmap', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysdcml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'configmap', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmcml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'configmap', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmcml {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'configmap', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdsecl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'secret', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysdsecl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'describe', 'secret', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmsecl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'secret', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysrmsecl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'delete', 'secret', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnol {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdnol {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'nodes', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdnsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'namespaces', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmnsl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'namespaces', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpooyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpooyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnooyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpoowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnoowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpoojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnoojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnsojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgposll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepsll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepsll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnowl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecwoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnowoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswoyamll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '-o=yaml', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpoowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgslowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgposlowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepslowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnowowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsvcwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'service', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgingwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'ingress', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgcmwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'configmap', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgsecwojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'secret', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnowojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'nodes', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgnswojsonl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'namespaces', '--watch', '-o=json', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgslwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--show-labels', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgposlwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--show-labels', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepslwl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--show-labels', '--watch', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwsll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwsll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowsll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowsll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwsll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwsll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgslwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--show-labels', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgposlwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--show-labels', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepslwowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--show-labels', '--watch', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwowidesll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '-o=wide', '--show-labels', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwslowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgwslowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', '--watch', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowslowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgpowslowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'pods', '--watch', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwslowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ksysgdepwslowidel {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('--namespace=kube-system', 'get', 'deployment', '--watch', '--show-labels', '-o=wide', '-l')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kpfn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('port-forward', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgponr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--field-selector=status.phase!=Running')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgponrall {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--field-selector=status.phase!=Running', '--all-namespaces')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpon {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdpon {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'pods', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmponr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'pods', '--field-selector=status.phase!=Running')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmpon {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'pods', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kddepn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'deployment', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmdepn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'deployment', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdsvcn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'service', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmsvcn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'service', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdingn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'ingress', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmingn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'ingress', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdcmn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'configmap', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmcmn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'configmap', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kdsecn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('describe', 'secret', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function krmsecn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('delete', 'secret', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpooyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepsln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpown {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwoyamln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=yaml', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgowidesln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '-o=wide', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpoowidesln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '-o=wide', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepowidesln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '-o=wide', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsvcwojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'service', '--watch', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgingwojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'ingress', '--watch', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgcmwojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'configmap', '--watch', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgsecwojsonn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'secret', '--watch', '-o=json', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslwn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--watch', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlwn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--watch', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslwn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--watch', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwsln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowsln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwsln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgslwowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--show-labels', '--watch', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgposlwowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--show-labels', '--watch', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepslwowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--show-labels', '--watch', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwowidesln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '-o=wide', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowowidesln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '-o=wide', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwowidesln {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '-o=wide', '--show-labels', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgwslowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', '--watch', '--show-labels', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgpowslowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'pods', '--watch', '--show-labels', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function kgdepwslowiden {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('get', 'deployment', '--watch', '--show-labels', '-o=wide', '--namespace')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
function ktno {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $cmnd = @('top', 'nodes', '--use-protocol-buffers')
    Invoke-WriteExecKubectl -Command $cmnd @PSBoundParameters
}
