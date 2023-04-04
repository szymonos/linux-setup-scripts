#Requires -PSEdition Core
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
Specify oh-my-posh theme to be installed, from themes available on the page.
There are also two baseline profiles included: base and powerline.
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
.PARAMETER Repos
List of GitHub repositories in format "Owner/RepoName" to clone into the WSL.
.PARAMETER PSModules
List of PowerShell modules from ps-modules repository to be installed.

.EXAMPLE
$Distro    = 'Ubuntu'
$OmpTheme  = 'powerline'
$GtkTheme  = 'dark'
$Scope     = 'k8s_basic'
$PSModules = @('do-common', 'do-linux')
$Repos     = @('szymonos/vagrant-scripts', 'szymonos/ps-modules')
~install packages and setup profile
.assets/scripts/wsl_setup.ps1 $Distro -g $GtkTheme -m $PSModules -o $OmpTheme -s $Scope
~install packages, setup profiles and clone GitHub repositories
.assets/scripts/wsl_setup.ps1 $Distro -r $Repos -g $GtkTheme -m $PSModules -o $OmpTheme -s $Scope
~update all existing WSL distros
.assets/scripts/wsl_setup.ps1 -g $GtkTheme -m $PSModules -o $OmpTheme
# fix network, add certificates and update all distros
.assets/scripts/wsl_setup.ps1 -g $GtkTheme -m $PSModules -o $OmpTheme -AddCertificate -FixNetwork
#>
[CmdletBinding(DefaultParameterSetName = 'Update')]
param (
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Setup')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'GitHub')]
    [string]$Distro,

    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
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

    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [switch]$FixNetwork,

    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [switch]$AddCertificate,

    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [ValidateScript({ -not ($_.ForEach({ $_ -match '^[\w-]+/[\w-]+$' }) -contains $false) }, ErrorMessage = 'Repos should be provided in "Owner/RepoName" format.')]
    [string[]]$Repos,

    [Alias('m')]
    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [string[]]$PSModules
)

begin {
    # *get list of distros
    [string[]]$distros = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss `
    | ForEach-Object { $_.GetValue('DistributionName') } `
    | Where-Object { $_ -notmatch '^docker-desktop' }
    if ($PsCmdlet.ParameterSetName -ne 'Update') {
        if ($Distro -notin $distros) {
            Write-Warning "The specified distro does not exist ($Distro)."
            exit
        }
        [string[]]$distros = $Distro
    }

    # set location to workspace folder
    Push-Location "$PSScriptRoot/../.."
}

process {
    foreach ($Distro in $distros) {
        # *determine scope for WSL update
        if ($PsCmdlet.ParameterSetName -eq 'Update') {
            $Scope = wsl.exe -d $distro --exec bash -c "[ -f /usr/bin/bat ] && ([ -f /usr/bin/kubectl ] && ([ -f /usr/local/bin/kubeseal ] && echo 'k8s_full' || echo 'k8s_basic') || echo 'base') || echo 'none'"
        }
        Write-Host "$distro - $Scope" -ForegroundColor Magenta
        # *fix WSL networking
        if ($FixNetwork) {
            .assets/scripts/wsl_network_fix.ps1 $Distro
        }
        # *install certificates
        if ($AddCertificate) {
            .assets/scripts/wsl_certs_add.ps1 $Distro
        }
        # *install packages
        wsl.exe --distribution $Distro --user root --exec .assets/provision/fix_secure_path.sh
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
                Write-Host 'installing kubernetes base packages...' -ForegroundColor Cyan
                $rel_kubectl = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubectl.sh $Script:rel_kubectl
                $rel_kubelogin = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubelogin.sh $Script:rel_kubelogin
                $rel_helm = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_helm.sh $Script:rel_helm
                $rel_minikube = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_minikube.sh $Script:rel_minikube
                $rel_k3d = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k3d.sh $Script:rel_k3d
                $rel_k9s = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k9s.sh $Script:rel_k9s
                $rel_yq = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_yq.sh $Script:rel_yq
            }
            k8s_full {
                Write-Host 'installing kubernetes additional packages...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_flux.sh
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kustomize.sh
                $rel_kubeseal = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubeseal.sh $Script:rel_kubeseal
                $rel_argoroll = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_argorolloutscli.sh $Script:rel_argoroll
            }
            'base|k8s_basic|k8s_full' {
                Write-Host 'installing base packages...' -ForegroundColor Cyan
                $rel_omp = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_omp.sh $Script:rel_omp
                $rel_pwsh = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_pwsh.sh $Script:rel_pwsh
                $rel_exa = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_exa.sh $Script:rel_exa
                $rel_bat = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_bat.sh $Script:rel_bat
                $rel_rg = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_ripgrep.sh $Script:rel_rg
                wsl.exe --distribution $Distro --exec .assets/provision/install_miniconda.sh
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_python.sh
                # *setup profiles
                Write-Host 'setting up profile for all users...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_omp.sh --theme $OmpTheme
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.ps1
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.sh
                Write-Host 'setting up profile for current user...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.ps1
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.sh
            }
        }
        # *install PowerShell modules from ps-modules repository
        # determine, if pwsh, git and kubectl binaries installed
        $cmd = [string]::Join("`n",
            '[ -f /usr/bin/pwsh ] && pwsh="true" || pwsh="false"',
            '[ -f /usr/bin/git ] && git="true" || git="false"',
            '[ -f /usr/bin/kubectl ] && kubectl="true" || kubectl="false"',
            'echo "{\"pwsh\":$pwsh,\"git\":$git,\"kubectl\":$kubectl}"'
        )
        $chkbin = wsl.exe -d $Distro --exec bash -c $cmd | ConvertFrom-Json -AsHashtable
        if ($chkbin.pwsh) {
            $moduleList = [Collections.Generic.List[string]]::new()
            $PSModules.ForEach({ $moduleList.Add($_) })
            $chkbin.git ? $($moduleList.Add('aliases-git')) : $null
            $chkbin.kubectl ? $($moduleList.Add('aliases-kubectl')) : $null
            if ($moduleList) {
                Write-Host 'installing ps-modules...' -ForegroundColor Cyan
                # determine if ps-modules repository exist and clone if necessary
                $getOrigin = { git config --get remote.origin.url }
                $remote = (Invoke-Command $getOrigin).Replace('vagrant-scripts', 'ps-modules')
                try {
                    Push-Location '../ps-modules' -ErrorAction Stop
                    if ($(Invoke-Command $getOrigin) -eq $remote) {
                        # pull ps-modules repository
                        git reset --hard --quiet && git clean --force -d && git pull --quiet
                    } else {
                        $moduleList = [Collections.Generic.List[string]]::new()
                    }
                    Pop-Location
                } catch {
                    # clone ps-modules repository
                    git clone $remote ../ps-modules
                }
                # install modules
                foreach ($module in $moduleList) {
                    Write-Host "$module" -ForegroundColor DarkGreen
                    if ($module -eq 'do-common') {
                        wsl.exe --distribution $Distro --user root --exec ../ps-modules/module_manage.ps1 $module -CleanUp
                    } else {
                        wsl.exe --distribution $Distro --exec ../ps-modules/module_manage.ps1 $module -CleanUp
                    }
                }
            }
        }
        # *set gtk theme for wslg
        if (wsl.exe --distribution $Distro -- bash -c '[ -d /mnt/wslg ] && echo 1') {
            Write-Host 'setting gtk theme...' -ForegroundColor Cyan
            $themeString = switch ($GtkTheme) {
                light { 'export GTK_THEME="Adwaita"' }
                dark { 'export GTK_THEME="Adwaita:dark"' }
            }
            wsl.exe --distribution $Distro --user root -- bash -c "echo '$themeString' >/etc/profile.d/gtk_theme.sh"
        }
    }

    if ($PsCmdlet.ParameterSetName -eq 'GitHub') {
        # *setup GitHub repositories
        Write-Host 'setting up GitHub repositories...' -ForegroundColor Cyan
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
        wsl.exe --distribution $Distro --exec .assets/provision/setup_gh_repos.sh --repos "$Repos" --user $env:USERNAME
    }
}

end {
    Pop-Location
}
