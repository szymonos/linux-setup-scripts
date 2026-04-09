# Cross-platform dev environment aliases for tools installed via Nix.
# Checks ~/.nix-profile/bin/ - works on macOS, Linux, WSL, and Coder.
# Dot-sourced from the PowerShell profile by nix/configure/profiles.ps1.

$_nb = "$HOME/.nix-profile/bin"

if (Test-Path "$_nb/eza" -PathType Leaf) {
    function eza { & /usr/bin/env eza -g --color=auto --time-style=long-iso --group-directories-first --color-scale=all --git-repos @args }
    function l { eza -1 @args }
    function lsa { eza -a @args }
    function ll { eza -lah @args }
    function lt { eza -Th @args }
    function lta { eza -aTh --git-ignore @args }
    function ltd { eza -DTh @args }
    function ltad { eza -aDTh --git-ignore @args }
    function llt { eza -lTh @args }
    function llta { eza -laTh --git-ignore @args }
} else {
    function l { ls -1 @args }
    function lsa { ls -a @args }
    function ll { ls -lah @args }
}
if (Test-Path "$_nb/rg" -PathType Leaf) {
    function rg { $input | & /usr/bin/env rg --ignore-case @args }
}
if (Test-Path "$_nb/bat" -PathType Leaf) {
    function batp { $input | & /usr/bin/env bat -pP @args }
}
if (Test-Path "$_nb/fastfetch" -PathType Leaf) {
    Set-Alias -Name ff -Value fastfetch
}
if (Test-Path "$_nb/pwsh" -PathType Leaf) {
    function p { & /usr/bin/env pwsh -NoProfileLoadTime @args }
}
if (Test-Path "$_nb/kubectx" -PathType Leaf) {
    Set-Alias -Name kc -Value kubectx
}
if (Test-Path "$_nb/kubens" -PathType Leaf) {
    Set-Alias -Name kn -Value kubens
}
if (Test-Path "$_nb/kubecolor" -PathType Leaf) {
    Set-Alias -Name kubectl -Value kubecolor
}

Remove-Variable _nb
