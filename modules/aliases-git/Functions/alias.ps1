function ga {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git add' @PSBoundParameters
}
function gaa {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git add --all' @PSBoundParameters
}
function gapa {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git add --patch' @PSBoundParameters
}
function gau {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git add --update' @PSBoundParameters
}
function gbl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git blame -b -w' @PSBoundParameters
}
function gb {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git branch' @PSBoundParameters
}
function gba {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git branch --all' @PSBoundParameters
}
function gbnm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git branch --no-merged' @PSBoundParameters
}
function gbr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git branch --remote' @PSBoundParameters
}
function gbsu {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    if ($remote = @(git remote)[0]) {
        # calculate command string
        $cmnd = "git branch --set-upstream-to=${remote}/$(Get-GitCurrentBranch)"
        # run command
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    } else {
        Write-Host 'fatal: Remote repository not set.'
        return
    }
}
function gbs {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git bisect' @PSBoundParameters
}
function gbsb {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git bisect bad' @PSBoundParameters
}
function gbsg {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git bisect good' @PSBoundParameters
}
function gbsr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git bisect reset' @PSBoundParameters
}
function gbss {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git bisect start' @PSBoundParameters
}
function gcv {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git commit --verbose' @PSBoundParameters
}
function gc! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git commit --verbose --amend' @PSBoundParameters
}
function gca {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git commit --verbose --all' @PSBoundParameters
}
function gcap {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    gca @PSBoundParameters

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gpush @PSBoundParameters
}
function gac {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gaa @PSBoundParameters

    gcv -Xargs $Xargs @PSBoundParameters
}
function gacp {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    gac @PSBoundParameters

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gpush @PSBoundParameters
}
function gca! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git commit --verbose --all --amend' @PSBoundParameters
}
function gac! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gaa @PSBoundParameters

    gca! -Xargs $Xargs @PSBoundParameters
}
function gcam {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git commit --all -m' @PSBoundParameters
}
function gcamp {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    gcam @PSBoundParameters

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gpush @PSBoundParameters
}
function gacm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gaa @PSBoundParameters

    gcmsg -Xargs $Xargs @PSBoundParameters
}
function gacmp {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    gacm @PSBoundParameters

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gpush @PSBoundParameters
}
function gcan! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git commit --verbose --all --no-edit --amend' @PSBoundParameters
}
function gcanp! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    gcan! @PSBoundParameters

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gpush! @PSBoundParameters
}
function gcempty {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand 'git commit --allow-empty -m' @PSBoundParameters
}
function gacn! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gaa @PSBoundParameters

    gcn! -Xargs $Xargs @PSBoundParameters
}
function gacnp! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    gacn! @PSBoundParameters

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gpush! @PSBoundParameters
}
function gcns! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git commit --verbose --signoff --no-edit --amend' @PSBoundParameters
}
function gcans! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git commit --verbose --all --signoff --no-edit --amend' @PSBoundParameters
}
function gacns! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gaa @PSBoundParameters

    gcns! -Xargs $Xargs @PSBoundParameters
}
function gcmsg {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git commit -m' @PSBoundParameters
}
function gcmsgp {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    gcmsg @PSBoundParameters

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gpush @PSBoundParameters
}
function gcn! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git commit --verbose --no-edit --amend' @PSBoundParameters
}
function gcnp! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    gcn! @PSBoundParameters

    $PSBoundParameters.Remove('Xargs') | Out-Null
    gpush! @PSBoundParameters
}
function gcsm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git commit --signoff -m' @PSBoundParameters
}
function gcd { Set-Location $(git rev-parse --show-toplevel 2>$null || '.') }
function gcf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git config' @PSBoundParameters
}
function gcfg {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git config --global' @PSBoundParameters
}
function gcfge {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git config --global --edit' @PSBoundParameters
}
function gcfgl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git config --global --list' @PSBoundParameters
}
function gcfl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git config --local' @PSBoundParameters
}
function gcfle {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git config --local --edit' @PSBoundParameters
}
function gcfll {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git config --local --list' @PSBoundParameters
}
function gcl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git clone --recursive' @PSBoundParameters
}
function gclean {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git clean --force -d' @PSBoundParameters
}
function gclean! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $PSBoundParameters.Remove('Xargs') | Out-Null
    grh @PSBoundParameters

    gclean -Xargs $Xargs @PSBoundParameters
}
function gpristine {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $PSBoundParameters.Remove('Xargs') | Out-Null
    grh @PSBoundParameters

    $Xargs = @('-x') + $Xargs
    gclean -Xargs $Xargs @PSBoundParameters
}
function gco {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git checkout' @PSBoundParameters
}
function gcount {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git shortlog --summary --numbered' @PSBoundParameters
}
function gcp {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git cherry-pick' @PSBoundParameters
}
function gcpa {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git cherry-pick --abort' @PSBoundParameters
}
function gcpc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git cherry-pick --continue' @PSBoundParameters
}
function gcps {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git cherry-pick --signoff' @PSBoundParameters
}
function gd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git diff' @PSBoundParameters
}
function gdca {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git diff --cached' @PSBoundParameters
}
function gdno {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git diff --name-only' @PSBoundParameters
}
function gdt {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git diff-tree --no-commit-id --name-only -r' @PSBoundParameters
}
function gdw {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git diff --word-diff' @PSBoundParameters
}
function gdct {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git describe --tags `git rev-list --tags --max-count=1`' @PSBoundParameters
}
function gf {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git fetch' @PSBoundParameters
}
function gfa {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git fetch --all --prune' @PSBoundParameters
}
function gfa! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git fetch --all --tags --prune --prune-tags --force' @PSBoundParameters
}
function gfo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    if ($remote = @(git remote)[0]) {
        Invoke-WriteExecCommand -Command "git fetch $remote" @PSBoundParameters
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function gg {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git grep --ignore-case' @PSBoundParameters
}
function ggc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git gc' @PSBoundParameters
}
function ggca {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git gc --aggressive' @PSBoundParameters
}
function gge {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git grep --ignore-case --extended-regexp' @PSBoundParameters
}
function ggp {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git grep --ignore-case --perl-regexp' @PSBoundParameters
}
function ghh {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git help' @PSBoundParameters
}
function gignore {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git update-index --assume-unchanged' @PSBoundParameters
}
function gignored {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git ls-files -v | Select-String "^[a-z]" -CaseSensitive' @PSBoundParameters
}
function glo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --date=rfc' @PSBoundParameters
}
function gloa {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --date=rfc --all' @PSBoundParameters
}
function glog {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --date=rfc --graph' @PSBoundParameters
}
function gloga {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --date=rfc --graph --decorate --all' @PSBoundParameters
}
function glol {
    # command string
    $cmnd = 'git log --graph --pretty="%C(yellow)%h%C(reset) %C(green)(%cr)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%an>%C(reset)" --abbrev-commit'
    # run command
    Invoke-WriteExecCommand -Command $cmnd -Quiet
}
function glola {
    # command string
    $cmnd = 'git log --graph --pretty="%C(yellow)%h%C(reset) %C(green)(%cr)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%an>%C(reset)" --abbrev-commit --all'
    # run command
    Invoke-WriteExecCommand -Command $cmnd -Quiet
}
function glon {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --oneline --decorate' @PSBoundParameters
}
function glona {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --oneline --decorate --all' @PSBoundParameters
}
function glong {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --oneline --decorate --graph' @PSBoundParameters
}
function glonga {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --oneline --decorate --graph --all' @PSBoundParameters
}
function glont {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --oneline --decorate --no-walk --tags="*"' @PSBoundParameters
}
function glop {
    # command string
    $cmnd = 'git log --pretty=format:"%C(yellow)%h%C(reset) %C(green)(%ai)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%ae>%C(reset)" --abbrev-commit'
    # run command
    Invoke-WriteExecCommand -Command $cmnd -Quiet
}
function glopa {
    # command string
    $cmnd = 'git log --pretty=format:"%C(yellow)%h%C(reset) %C(green)(%ai)%C(reset)%C(red)%d%C(reset) %s %C(bold blue)<%ae>%C(reset)" --abbrev-commit --all'
    # run command
    Invoke-WriteExecCommand -Command $cmnd -Quiet
}
function glos {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --date=rfc --stat' @PSBoundParameters
}
function glosa {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --date=rfc --stat --all' @PSBoundParameters
}
function glosp {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --date=rfc --stat --patch' @PSBoundParameters
}
function glospa {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git log --date=rfc --stat --patch --all' @PSBoundParameters
}
function gmt {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git mergetool --no-prompt' @PSBoundParameters
}
function gmtvim {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git mergetool --no-prompt --tool=vimdiff' @PSBoundParameters
}
function gpl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    if ($remote = @(git remote)[0]) {
        # calculate command string
        $cmnd = "git pull $remote $(Get-GitCurrentBranch) --tags --prune"
        # run command
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function gpl! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    $PSBoundParameters.Xargs = @('--force') + $Xargs
    gpl @PSBoundParameters
}
function gpull {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git pull' @PSBoundParameters
}
function gpullr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git pull --rebase' @PSBoundParameters
}
function gpullra {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git pull --rebase --autostash' @PSBoundParameters
}
function gpullrav {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git pull --rebase --autostash --verbose' @PSBoundParameters
}
function gpullrv {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git pull --rebase --verbose' @PSBoundParameters
}
function gpush {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git push' @PSBoundParameters
}
function gpush! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git push --force-with-lease' @PSBoundParameters
}
function gpushdr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git push --dry-run' @PSBoundParameters
}
function gpushoat {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Position = 0)]
        [ArgumentCompleter({ ArgGitGetBranches @args })]
        [string]$Branch,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    if ($remote = @(git remote)[0]) {
        # calculate command string
        $cmnd = "git push $remote --all && git push $remote --tags"
        # run command
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function gpushsup {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command "git push --set-upstream origin $(Get-GitCurrentBranch)" @PSBoundParameters
}
function gpusht {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git push --tags' @PSBoundParameters
}
function gpusht! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git push --tags --force' @PSBoundParameters
}
function gpushv {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git push --verbose' @PSBoundParameters
}
function grba {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git rebase --abort' @PSBoundParameters
}
function grbc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git rebase --continue' @PSBoundParameters
}
function grbi {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git rebase --interactive' @PSBoundParameters
}
function grbs {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git rebase --skip' @PSBoundParameters
}
function gr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git reset' @PSBoundParameters
}
function grh {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git reset --hard' @PSBoundParameters
}
function grho {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    if ($remote = @(git remote)[0]) {
        $PSBoundParameters.Remove('Xargs') | Out-Null
        $cmnd = "git fetch $remote --tags --prune --prune-tags --force"
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters

        $cmnd = "git reset --hard $remote/$(Get-GitCurrentBranch)"
        Invoke-WriteExecCommand -Command $cmnd -Xargs $Xargs @PSBoundParameters
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function grho! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    grho @PSBoundParameters

    git clean --force -d
}
function grs {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git reset --soft' @PSBoundParameters
}
function grl {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git reflog' @PSBoundParameters
}
function grmc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git rm --cached' @PSBoundParameters
}
function grm! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git rm --force' @PSBoundParameters
}
function grmrc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git rm -r --cached' @PSBoundParameters
}
function grmr! {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git rm -r --force' @PSBoundParameters
}
function grp {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git rev-parse' @PSBoundParameters
}
function grr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git restore' @PSBoundParameters
}
function grrsrc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git restore --source' @PSBoundParameters
}
function grrstg {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git restore --staged' @PSBoundParameters
}
function grrstga {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git restore --staged .' @PSBoundParameters
}
function grt {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git remote' @PSBoundParameters
}
function grta {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git remote add' @PSBoundParameters
}
function grtrm {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git remote remove' @PSBoundParameters
}
function grtrn {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git remote rename' @PSBoundParameters
}
function grtsu {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git remote set-url' @PSBoundParameters
}
function grtup {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    if ($remote = @(git remote)[0]) {
        # calculate command string
        $cmnd = "git remote update $remote"
        # run command
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function grtupp {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    if ($remote = @(git remote)[0]) {
        # calculate command string
        $cmnd = "git remote update $remote --prune"
        # run command
        Invoke-WriteExecCommand -Command $cmnd @PSBoundParameters
    } else {
        Write-Host 'fatal: Remote repository not set.'
    }
}
function grtv {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git remote --verbose' @PSBoundParameters
}
function grturl {
    (git remote get-url origin) -replace '^git@(.+?):', 'https://$1/' -replace '\.git$'
}
function grturlb {
    $url = (git remote get-url origin) -replace '^git@(.+?):', 'https://$1/' -replace '\.git$'
    $branch = git branch --show-current
    "$url/tree/$branch"
}
function gswc {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git switch --create' @PSBoundParameters
}
function gswd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git switch --detach' @PSBoundParameters
}
function gswo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git switch --orphan' @PSBoundParameters
}
function gsmi {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git submodule init' @PSBoundParameters
}
function gsmu {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git submodule update' @PSBoundParameters
}
function gsps {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git show --pretty=short --show-signature' @PSBoundParameters
}
function gsta {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git stash push' @PSBoundParameters
}
function gstaa {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git stash push --all' @PSBoundParameters
}
function gstac {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git stash clear' @PSBoundParameters
}
function gstal {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git stash list' @PSBoundParameters
}
function gstap {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git stash pop' @PSBoundParameters
}
function gst {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git status' @PSBoundParameters
}
function gstb {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git status --short --branch' @PSBoundParameters
}
function gsts {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git status --short' @PSBoundParameters
}
function gsvnd {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git svn dcommit' @PSBoundParameters
}
function gsvnr {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git svn rebase' @PSBoundParameters
}
function gt {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git tag --sort=-v:refname' @PSBoundParameters
}
function gts {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git tag --sign' @PSBoundParameters
}
function gtr {
    # command string
    $cmnd = "git for-each-ref refs/tags/ --sort=-v:refname --format='%1B[33m%(objectname:short)%1B[m %1B[31m%(refname:short)%1B[m %(subject) %1B[1;94m%(authorname)%1B[m %1B[36m%(authoremail)%1B[m'"
    # run command
    Invoke-WriteExecCommand -Command $cmnd -Quiet
}
function gunignore {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git update-index --no-assume-unchanged' @PSBoundParameters
}
function gwch {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Xargs,

        [Parameter(ParameterSetName = 'whatif')]
        [switch]$WhatIf,

        [Parameter(ParameterSetName = 'quiet')]
        [switch]$Quiet
    )

    Invoke-WriteExecCommand -Command 'git whatchanged -p --abbrev-commit --pretty=medium' @PSBoundParameters
}
