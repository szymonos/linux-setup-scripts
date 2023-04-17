#Requires -PSEdition Core
<#
.SYNOPSIS
Setting up WSL distro(s).
.DESCRIPTION
You can use the script for:
- installing base packages and setting up bash and pwsh shells,
- installing docker-ce locally in WSL,
- installing tools for interacting with kubernetes,
- setting gtk theme in WSLg,
- installing Python environment management tools: venv and miniconda,
- cloning GH repositories and setting up VSCode workspace,
- updating packages in all existing WSL distros.
When GH repositories cloning is used, you need to generate and add an SSH key to your GH account.

.PARAMETER Distro
Name of the WSL distro to set up. If not specified, script will update all existing distros.
.PARAMETER Scope
List of installation scopes. Valid values:
- az: azure-cli if python scope specified, do-az from ps-modules if shell scope specified.
- docker: docker, containerd buildx docker-compose
- k8s_base: kubectl, helm, minikube, k3d, k9s, yq
- k8s_ext: flux, kubeseal, kustomize, argorollouts-cli
- python: pip, venv, miniconda
- shell: bat, exa, oh-my-posh, pwsh, ripgrep
Default: @('shell').
.PARAMETER OmpTheme
Specify to install oh-my-posh prompt theme engine and name of the theme to be used.
You can specify one of the three included profiles: base, powerline, nerd,
or use any theme available on the page: https://ohmyposh.dev/docs/themes/
Default: 'base'
.PARAMETER PSModules
List of PowerShell modules from ps-modules repository to be installed.
Default: @('do-common', 'do-linux')
.PARAMETER GtkTheme
Specify gtk theme for wslg. Available values: light, dark.
Default: 'dark'
.PARAMETER Repos
List of GitHub repositories in format "Owner/RepoName" to clone into the WSL.
.PARAMETER AddCertificate
Intercept and add self-signed certificates from chain into selected distro.
.PARAMETER FixNetwork
Set network settings from the selected network interface in Windows.

.EXAMPLE
$Distro = 'Ubuntu'
# ~set up WSL distro using default values
wsl/wsl_setup.ps1 $Distro
wsl/wsl_setup.ps1 $Distro -AddCertificate
wsl/wsl_setup.ps1 $Distro -FixNetwork -AddCertificate
# ~set up WSL distro using specified values
$Scope = @('az', 'docker', 'k8s_base', 'k8s_ext', 'python', 'shell')
$OmpTheme = 'nerd'
wsl/wsl_setup.ps1 $Distro -s $Scope -o $OmpTheme
# ~set up WSL distro and clone specified GitHub repositories
$Repos = @('szymonos/linux-setup-scripts', 'szymonos/ps-modules')
wsl/wsl_setup.ps1 $Distro -r $Repos -s $Scope -o $OmpTheme
# ~update all existing WSL distros
wsl/wsl_setup.ps1
#>
[CmdletBinding(DefaultParameterSetName = 'Update')]
param (
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Setup')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'GitHub')]
    [string]$Distro,

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateScript({ $_.ForEach({ $_ -in @('az', 'docker', 'k8s_base', 'k8s_ext', 'oh_my_posh', 'python', 'shell') }) -notcontains $false },
        ErrorMessage = 'Wrong scope provided. Valid values: az docker k8s_base k8s_ext python shell')]
    [string[]]$Scope,

    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateNotNullOrEmpty()]
    [string]$OmpTheme,

    [Alias('m')]
    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateScript({ $_.ForEach({ $_ -in @('do-az', 'do-common', 'do-linux') }) -notcontains $false },
        ErrorMessage = 'Wrong modules provided. Valid values: do-az do-common do-linux')]
    [string[]]$PSModules = @('do-common', 'do-linux'),

    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateSet('light', 'dark')]
    [string]$GtkTheme = 'dark',

    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [ValidateScript({ $_.ForEach({ $_ -match '^[\w-]+/[\w-]+$' }) -notcontains $false },
        ErrorMessage = 'Repos should be provided in "Owner/RepoName" format.')]
    [string[]]$Repos,

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [switch]$AddCertificate,

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [switch]$FixNetwork
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

    # instantiate scope generic lists
    $scopes = [Collections.Generic.List[String]]::new()
    $Scope.ForEach({ $scopes.Add($_) })
    # instantiate psmodules generic lists
    $modules = [Collections.Generic.List[String]]::new()
    $PSModules.ForEach({ $modules.Add($_) })

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
}

process {
    foreach ($Distro in $distros) {
        # *perform distro checks
        $cmd = [string]::Join("`n",
            '[ -f /usr/bin/pwsh ] && shell="true" || shell="false"',
            '[ -f /usr/bin/kubectl ] && k8s_base="true" || k8s_base="false"',
            '[ -f /usr/bin/kustomize ] && k8s_ext="true" || k8s_ext="false"',
            '[ -f /usr/bin/oh-my-posh ] && omp="true" || omp="false"',
            '[ -d /mnt/wslg ] && wslg="true" || wslg="false"',
            'grep -Fqw "dark" /etc/profile.d/gtk_theme.sh 2>/dev/null && gtkd="true" || gtkd="false"',
            'echo "{\"shell\":$shell,\"k8s_base\":$k8s_base,\"k8s_ext\":$k8s_ext,\"omp\":$omp,\"wslg\":$wslg,\"gtkd\":$gtkd}"'
        )
        # check existing packages
        $chk = wsl.exe -d $Distro --exec bash -c $cmd | ConvertFrom-Json -AsHashtable
        # *determine scope if not provided
        if (-not $scopes) {
            switch ($chk) {
                { $_.k8s_base } { $scopes.Add('k8s_base') }
                { $_.k8s_ext } { $scopes.Add('k8s_ext') }
                { $_.shell } { $scopes.Add('shell') }
            }
        }
        # determine 'oh_my_posh' scope
        if ($chk.omp -or $OmpTheme) {
            $scopes.Add('oh_my_posh')
        }
        # remove duplicates and sort scopes
        $scopes = $scopes | Select-Object -Unique | Sort-Object
        # separate log for multpiple distros update
        Write-Host "$($Distro -eq $distros[0] ? '': "`n")" -NoNewline
        # display distro name and installed scopes
        Write-Host "$distro$($scopes ? " : `e[3m$scopes`e[23m" : '')" -ForegroundColor Magenta
        # *fix WSL networking
        if ($FixNetwork) {
            wsl/wsl_network_fix.ps1 $Distro
        }
        # *install certificates
        if ($AddCertificate) {
            wsl/wsl_certs_add.ps1 $Distro
        }
        # *install packages
        wsl.exe --distribution $Distro --user root --exec .assets/provision/fix_secure_path.sh
        wsl.exe --distribution $Distro --user root --exec .assets/provision/upgrade_system.sh
        wsl.exe --distribution $Distro --user root --exec .assets/provision/install_base.sh
        if (wsl.exe --distribution $Distro -- bash -c 'curl https://www.google.com 2>&1 | grep -q "(60) SSL certificate problem" && echo 1') {
            Write-Warning 'SSL certificate problem: self-signed certificate in certificate chain. Script execution halted.'
            exit
        }
        switch ($scopes) {
            docker {
                Write-Host 'installing docker...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_docker.sh
                continue
            }
            k8s_base {
                Write-Host 'installing kubernetes base packages...' -ForegroundColor Cyan
                $rel_kubectl = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubectl.sh $Script:rel_kubectl && $($chk.k8s_base = $true)
                $rel_kubelogin = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubelogin.sh $Script:rel_kubelogin
                $rel_helm = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_helm.sh $Script:rel_helm
                $rel_minikube = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_minikube.sh $Script:rel_minikube
                $rel_k3d = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k3d.sh $Script:rel_k3d
                $rel_k9s = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k9s.sh $Script:rel_k9s
                $rel_yq = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_yq.sh $Script:rel_yq
                continue
            }
            k8s_ext {
                Write-Host 'installing kubernetes additional packages...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_flux.sh
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kustomize.sh
                $rel_kubeseal = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubeseal.sh $Script:rel_kubeseal
                $rel_argoroll = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_argorolloutscli.sh $Script:rel_argoroll
                continue
            }
            oh_my_posh {
                Write-Host 'installing oh-my-posh...' -ForegroundColor Cyan
                $rel_omp = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_omp.sh $Script:rel_omp
                if ($OmpTheme) {
                    wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_omp.sh --theme $OmpTheme
                }
                continue
            }
            python {
                Write-Host 'installing python packages...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --exec .assets/provision/install_miniconda.sh
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_python.sh
                if ('az' -in $scopes) {
                    wsl.exe --distribution $Distro --exec .assets/provision/install_azurecli.sh --fix_certify true
                }
                continue
            }
            shell {
                Write-Host 'installing shell packages...' -ForegroundColor Cyan
                $rel_pwsh = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_pwsh.sh $Script:rel_pwsh && $($chk.shell = $true)
                $rel_exa = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_exa.sh $Script:rel_exa
                $rel_bat = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_bat.sh $Script:rel_bat
                $rel_rg = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_ripgrep.sh $Script:rel_rg
                # *setup profiles
                Write-Host 'setting up profile for all users...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.ps1
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.sh
                Write-Host 'setting up profile for current user...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.ps1
                if ('az' -in $scopes) {
                    $cmd = 'if (-not (Get-Module Az -ListAvailable)) { Install-PSResource Az }'
                    wsl.exe --distribution $Distro -- pwsh -nop -c $cmd
                }
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.sh
                continue
            }
        }
        # *install PowerShell modules from ps-modules repository
        if ($chk.shell) {
            # determine modules to install
            if ('az' -in $scopes) { $modules.Add('do-az') }
            $modules.Add('aliases-git') # git is always installed
            if ($chk.k8s_base) { $modules.Add('aliases-kubectl') }

            # determine if ps-modules repository exist and clone if necessary
            $getOrigin = { git config --get remote.origin.url }
            $remote = (Invoke-Command $getOrigin).Replace('linux-setup-scripts', 'ps-modules')
            try {
                Push-Location '../ps-modules' -ErrorAction Stop
                if ($(Invoke-Command $getOrigin) -eq $remote) {
                    # pull ps-modules repository
                    git reset --hard --quiet && git clean --force -d && git pull --quiet
                } else {
                    $modules = [System.Collections.Generic.List[string]]::new()
                }
                Pop-Location
            } catch {
                # clone ps-modules repository
                git clone $remote ../ps-modules
            }
            Write-Host 'installing ps-modules...' -ForegroundColor Cyan
            if ('do-common' -in $modules) {
                Write-Host "`e[3mAllUsers`e[23m    : do-common" -ForegroundColor DarkGreen
                wsl.exe --distribution $Distro --user root --exec ../ps-modules/module_manage.ps1 'do-common' -CleanUp
                $modules.Remove('do-common') | Out-Null
            }
            if ($modules) {
                Write-Host "`e[3mCurrentUser`e[23m : $modules" -ForegroundColor DarkGreen
                $cmd = "@($($modules.ForEach({ "'$_'" }) -join ',')) | ../ps-modules/module_manage.ps1 -CleanUp"
                wsl.exe --distribution $Distro --exec pwsh -nop -c $cmd
            }
        }
        # *set gtk theme for wslg
        if ($chk.wslg) {
            [string]$GTK_THEME = switch ($GtkTheme) {
                light {
                    $chk.gtkd ? 'export GTK_THEME="Adwaita"' : ''
                }
                dark {
                    $chk.gtkd ? '' : 'export GTK_THEME="Adwaita:dark"'
                }
            }
            if ($GTK_THEME) {
                Write-Host 'setting gtk theme...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root -- bash -c "echo '$GTK_THEME' >/etc/profile.d/gtk_theme.sh"
            }
        }
    }

    if ($PsCmdlet.ParameterSetName -eq 'GitHub') {
        # *setup GitHub repositories
        Write-Host 'setting up GitHub repositories...' -ForegroundColor Cyan
        # set git eol config
        wsl.exe --distribution $Distro --exec bash -c 'git config --global core.eol lf && git config --global core.autocrlf input'
        # copy git user settings from the host
        $gitConfigCmd = (git config --list --global 2>$null | Select-String '^user\b').ForEach({
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
