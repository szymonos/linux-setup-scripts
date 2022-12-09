<#
.SYNOPSIS
Setting up WSL distro(s).
.DESCRIPTION
You can use the script for:
- installing base packages and setting up bash and pwsh shells,
- installing tools for interacting with kubernetes,
- setting gtk theme in WSLg
- cloning GH repositories and setting up VSCode workspace,
- updating packages in all existing WSL distros.
When GH repositories cloning is used, you need to generate and add an SSH key to your GH account.

.PARAMETER Distro
Name of the WSL distro to set up. If not specified, script will update all existing distros.
.PARAMETER OmpTheme
Choose if oh-my-posh prompt theme should use base or powerline fonts.
Available values: 'base', 'powerline'
.PARAMETER GtkTheme
Specify gtk theme for wslg.
Available values: 'light', 'dark'
.PARAMETER Scope
Installation scope - valid values, and packages installed:
- none: no additional packages installed
- base: curl, git, jq, tree, vim, oh-my-posh, pwsh, bat, exa, ripgrep
- k8s_basic: kubectl, helm, minikube, k3d, k9s, yq
- k8s_full: flux, kubeseal, kustomize, argorolloutts-cli
Every following option expands the scope.
.PARAMETER Account
GH account with the repositories to clone.
.PARAMETER Repos
List of repositories to clone into the WSL.
.PARAMETER PSModules
List of PowerShell modules from ps-szymonos repository to be installed.

.EXAMPLE
$Distro   = 'Ubuntu'
$OmpTheme = 'powerline'
$GtkTheme = 'dark'
$Scope    = 'k8s_basic'
$Account  = 'szymonos'
$Repos = @(
    'vagrant-scripts'
    'ps-szymonos'
)
$PSModules = @(
    'do-common'
    'do-linux'
)
~install packages and setup profile
.assets/scripts/wsl_setup.ps1 $Distro -o $OmpTheme -g $GtkTheme -s $Scope -m $PSModules
~install packages, setup profiles and clone repositories
.assets/scripts/wsl_setup.ps1 $Distro -a $Account -r $Repos -o $OmpTheme -g $GtkTheme -s $Scope -m $PSModules
~update all existing WSL distros
.assets/scripts/wsl_setup.ps1 -o $OmpTheme -g $GtkTheme -m $PSModules
#>
[CmdletBinding(DefaultParameterSetName = 'Update')]
param (
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Setup')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'GitHub')]
    [string]$Distro,

    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateSet('base', 'powerline')]
    [string]$OmpTheme = 'base',

    [Alias('g')]
    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateSet('light', 'dark')]
    [string]$GtkTheme = 'light',

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateSet('none', 'base', 'k8s_basic', 'k8s_full')]
    [string]$Scope = 'base',

    [Alias('a')]
    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [string]$Account,

    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [string[]]$Repos,

    [Alias('m')]
    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [string[]]$PSModules
)

begin {
    # *get list of distros
    # change temporarily encoding to utf-16 to match wsl output
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    [string[]]$distros = (wsl.exe --list --quiet) -notmatch '^docker-'
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    if ($PsCmdlet.ParameterSetName -ne 'Update') {
        if ($Distro -notin $distros) {
            Write-Warning "The specified distro does not exist ($Distro)."
            exit
        }
        [string[]]$distros = $Distro
    }

    $workspaceFolder = Split-Path (Split-Path $PSScriptRoot)
    if ($workspaceFolder -ne $PWD.Path) {
        $startWorkingDirectory = $PWD
        Write-Verbose "Setting working directory to '$($workspaceFolder.Replace($HOME, '~'))'."
        Set-Location $workspaceFolder
    }
}

process {
    foreach ($Distro in $distros) {
        # *install packages
        if ($PsCmdlet.ParameterSetName -eq 'Update') {
            $Scope = wsl.exe -d $distro --exec bash -c "[ -f /usr/bin/bat ] && ([ -f /usr/bin/kubectl ] && ([ -f /usr/local/bin/kubeseal ] && echo 'k8s_full' || echo 'k8s_basic') || echo 'base') || echo 'none'"
        }
        Write-Host "$distro - $Scope" -ForegroundColor Magenta
        wsl.exe --distribution $Distro --user root --exec .assets/provision/upgrade_system.sh
        wsl.exe --distribution $Distro --user root --exec .assets/provision/install_base.sh
        if (wsl.exe --distribution $Distro -- bash -c 'curl https://www.google.com 2>&1 | grep -q "(60) SSL certificate problem" && echo 1') {
            Write-Warning 'SSL certificate problem: self-signed certificate in certificate chain. Script execution halted.'
            exit
        }
        switch -Regex ($Scope) {
            none {
                continue
            }
            'k8s_basic|k8s_full' {
                Write-Host 'installing kubernetes base packages...' -ForegroundColor Green
                $rel_kubectl = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubectl.sh $Script:rel_kubectl
                $rel_kubelogin = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubelogin.sh $Script:rel_kubelogin
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_helm.sh
                $rel_minikube = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_minikube.sh $Script:rel_minikube
                $rel_k3d = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k3d.sh $Script:rel_k3d
                $rel_k9s = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k9s.sh $Script:rel_k9s
                $rel_yq = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_yq.sh $Script:rel_yq
            }
            k8s_full {
                Write-Host 'installing kubernetes additional packages...' -ForegroundColor Green
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_flux.sh
                $rel_kubeseal = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubeseal.sh $Script:rel_kubeseal
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kustomize.sh
                $rel_argoroll = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_argorolloutscli.sh $Script:rel_argoroll
            }
            'base|k8s_basic|k8s_full' {
                Write-Host 'installing base packages...' -ForegroundColor Green
                $rel_omp = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_omp.sh $Script:rel_omp
                $rel_pwsh = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_pwsh.sh $Script:rel_pwsh
                $rel_exa = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_exa.sh $Script:rel_exa
                $rel_bat = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_bat.sh $Script:rel_bat
                $rel_rg = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_ripgrep.sh $Script:rel_rg
                wsl.exe --distribution $Distro --exec .assets/provision/install_miniconda.sh
                # *setup profiles
                Write-Host 'setting up profile for all users...' -ForegroundColor Green
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_omp.sh --theme_font $OmpTheme
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profiles_allusers.ps1
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profiles_allusers.sh
                Write-Host 'setting up profile for current user...' -ForegroundColor Green
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profiles_user.ps1
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profiles_user.sh
                if ($PSModules -and (Test-Path '../ps-szymonos/module_manage.ps1')) {
                    # *install PowerShell modules from ps-szymonos repository
                    Write-Host 'installing PowerShell modules...' -ForegroundColor Green
                    foreach ($module in $PSModules) {
                        if ($module -eq 'do-common') {
                            wsl.exe --distribution $Distro --user root --exec ../ps-szymonos/module_manage.ps1 $module -CleanUp
                        } else {
                            wsl.exe --distribution $Distro --exec ../ps-szymonos/module_manage.ps1 $module -CleanUp
                        }
                    }
                }
            }
        }
        # *set gtk theme for wslg
        if (wsl.exe --distribution $Distro -- bash -c '[ -d /mnt/wslg ] && echo 1') {
            Write-Host 'setting gtk theme...' -ForegroundColor Green
            $themeString = switch ($GtkTheme) {
                light { 'export GTK_THEME="Adwaita"' }
                dark { 'export GTK_THEME="Adwaita:dark"' }
            }
            wsl.exe --distribution $Distro --user root -- bash -c "echo '$themeString' >/etc/profile.d/gtk_theme.sh"
        }
    }

    if ($PsCmdlet.ParameterSetName -eq 'GitHub') {
        # *setup GitHub repositories
        Write-Host 'setting up GitHub repositories...' -ForegroundColor Green
        # set git eol config
        wsl.exe --distribution $Distro --exec bash -c 'git config --global core.eol lf && git config --global core.autocrlf input'
        # copy git user settings from the host
        $gitConfigCmd = (git config --list --global | Select-String '^user\b').ForEach({
                $split = $_.Line.Split('=')
                "git config --global $($split[0]) '$($split[1])'"
            }
        ) -join ' && '
        if ($gitConfigCmd) {
            wsl.exe --distribution $Distro --exec bash -c $gitConfigCmd
        }
        # clone repos
        wsl.exe --distribution $Distro --exec .assets/provision/setup_gh_repos.sh --distro $Distro --repos "$Repos" --gh_user $Account --win_user $env:USERNAME
    }
}

end {
    if ($startWorkingDirectory) {
        Set-Location $startWorkingDirectory
    }
}
