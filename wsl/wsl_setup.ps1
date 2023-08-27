#Requires -PSEdition Core
<#
.SYNOPSIS
Setting up WSL distro(s).
.DESCRIPTION
You can use the script for:
- installing base packages and setting up bash and pwsh shells,
- installing docker-ce locally in WSL,
- installing podman with distrobox,
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
- distrobox: podman and distrobox
- docker: docker, containerd buildx docker-compose
- k8s_base: kubectl, helm, minikube, k3d, k9s, yq
- k8s_ext: flux, kubeseal, kustomize, argorollouts-cli
- python: pip, venv, miniconda
- rice: btop, cmatrix, cowsay, fastfetch
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
Default: automatically detects based on the system theme.
.PARAMETER Repos
List of GitHub repositories in format "Owner/RepoName" to clone into the WSL.
.PARAMETER AddCertificate
Intercept and add self-signed certificates from chain into selected distro.
.PARAMETER FixNetwork
Set network settings from the selected network interface in Windows.

.EXAMPLE
$Distro = 'Ubuntu'
# :set up WSL distro using default values
wsl/wsl_setup.ps1 $Distro
wsl/wsl_setup.ps1 $Distro -AddCertificate
wsl/wsl_setup.ps1 $Distro -FixNetwork -AddCertificate
# :set up WSL distro using specified values
$Scope = @('az', 'python', 'shell')
$Scope = @('az', 'docker', 'k8s_base', 'k8s_ext', 'python', 'shell')
wsl/wsl_setup.ps1 $Distro -s $Scope
wsl/wsl_setup.ps1 $Distro -s $Scope -AddCertificate
$OmpTheme = 'nerd'
wsl/wsl_setup.ps1 $Distro -s $Scope -o $OmpTheme
wsl/wsl_setup.ps1 $Distro -s $Scope -o $OmpTheme -AddCertificate
# :set up WSL distro and clone specified GitHub repositories
$Repos = @('szymonos/linux-setup-scripts', 'szymonos/ps-modules')
wsl/wsl_setup.ps1 $Distro -r $Repos -s $Scope -o $OmpTheme
wsl/wsl_setup.ps1 $Distro -r $Repos -s $Scope -o $OmpTheme -AddCertificate
# :update all existing WSL distros
wsl/wsl_setup.ps1
#>
[CmdletBinding(DefaultParameterSetName = 'Update')]
param (
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Setup')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'GitHub')]
    [string]$Distro,

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateScript({ $_.ForEach({ $_ -in @('az', 'distrobox', 'docker', 'k8s_base', 'k8s_ext', 'oh_my_posh', 'python', 'rice', 'shell') }) -notcontains $false },
        ErrorMessage = 'Wrong scope provided. Valid values: az distrobox docker k8s_base k8s_ext python rice shell')]
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
    [string]$GtkTheme,

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
    $ErrorActionPreference = 'Stop'

    # *get list of distros
    $lxss = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss `
    | ForEach-Object { $_ | Get-ItemProperty } `
    | Where-Object { $_.DistributionName -notmatch '^docker-desktop' } `
    | Select-Object DistributionName, DefaultUid, @{ N = 'Version'; E = { $_.Flags -lt 8 ? 1 : 2 } }
    if ($PsCmdlet.ParameterSetName -ne 'Update') {
        if ($Distro -in $lxss.DistributionName) {
            $lxss = $lxss.Where({ $_.DistributionName -eq $Distro })
        } else {
            Write-Warning "The specified distro does not exist ($Distro)."
            exit
        }
    } else {
        Write-Host "Found $($lxss.Count) distro$($lxss.Count -eq 1 ? '' : 's') to update." -ForegroundColor White
        $lxss.DistributionName.ForEach({ Write-Host "- $_" })
        $lxss.Count ? '' : $null
    }

    # determine GTK theme if not provided, based on system theme
    if (-not $GtkTheme) {
        $systemUsesLightTheme = Get-ItemPropertyValue -ErrorAction SilentlyContinue `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' `
            -Name 'SystemUsesLightTheme'
        $GtkTheme = $systemUsesLightTheme ? 'light' : 'dark'
    }

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
}

process {
    foreach ($lx in $lxss) {
        $Distro = $lx.DistributionName
        # *perform distro checks
        $cmd = [string]::Join('',
            '[ -f /usr/bin/pwsh ] && shell="true" || shell="false";',
            '[ -f /usr/bin/kubectl ] && k8s_base="true" || k8s_base="false";',
            '[ -f /usr/bin/kustomize ] && k8s_ext="true" || k8s_ext="false";',
            '[ -f /usr/bin/oh-my-posh ] && omp="true" || omp="false";',
            '[ -d /mnt/wslg ] && wslg="true" || wslg="false";',
            '[ -d "$HOME/miniconda3" ] && python="true" || python="false";',
            'grep -qw "systemd.*true" /etc/wsl.conf 2>/dev/null && systemd="true" || systemd="false";',
            'grep -Fqw "dark" /etc/profile.d/gtk_theme.sh 2>/dev/null && gtkd="true" || gtkd="false";',
            'printf "{\"user\":\"$(id -un)\",\"shell\":$shell,\"k8s_base\":$k8s_base,\"k8s_ext\":$k8s_ext,',
            '\"omp\":$omp,\"wslg\":$wslg,\"python\":$python,\"systemd\":$systemd,\"gtkd\":$gtkd}"'
        )
        # check existing packages
        $chk = wsl.exe -d $Distro --exec sh -c $cmd | ConvertFrom-Json -AsHashtable
        # instantiate scope generic sorted set
        $scopes = [System.Collections.Generic.SortedSet[string]]::new()
        $Scope.ForEach({ $scopes.Add($_) | Out-Null })
        # *determine scope if not provided
        if ($scopes.Count -eq 0) {
            switch ($chk) {
                { $_.k8s_base } { $scopes.Add('k8s_base') | Out-Null }
                { $_.k8s_ext } { $scopes.Add('k8s_ext') | Out-Null }
                { $_.python } { $scopes.Add('python') | Out-Null }
                { $_.shell } { $scopes.Add('shell') | Out-Null }
            }
        }
        # determine 'oh_my_posh' scope
        if ($chk.omp -or $OmpTheme) {
            @('oh_my_posh', 'shell').ForEach({ $scopes.Add($_) | Out-Null })
        }
        # separate log for multpiple distros update
        Write-Host "$($Distro -eq $lxss.DistributionName[0] ? '': "`n")" -NoNewline
        # display distro name and installed scopes
        Write-Host "$Distro$($scopes ? " : `e[3m$scopes`e[23m" : '')" -ForegroundColor Magenta
        # *fix WSL networking
        if ($FixNetwork) {
            Write-Host 'fixing network...' -ForegroundColor Cyan
            wsl/wsl_network_fix.ps1 $Distro
        }
        # *install certificates
        if ($AddCertificate) {
            Write-Host 'adding certificates in chain...' -ForegroundColor Cyan
            wsl/wsl_certs_add.ps1 $Distro
        }
        # *install packages
        Write-Host 'updating system...' -ForegroundColor Cyan
        wsl.exe --distribution $Distro --user root --exec .assets/provision/fix_secure_path.sh
        wsl.exe --distribution $Distro --user root --exec .assets/provision/upgrade_system.sh
        wsl.exe --distribution $Distro --user root --exec .assets/provision/install_base.sh $chk.user
        if (wsl.exe --distribution $Distro -- bash -c 'curl https://www.google.com 2>&1 | grep -q "(60) SSL certificate problem" && echo 1') {
            Write-Warning 'SSL certificate problem: self-signed certificate in certificate chain. Script execution halted.'
            exit
        }
        switch ($scopes) {
            distrobox {
                Write-Host 'installing distrobox...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_podman.sh
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_distrobox.sh $chk.user
                continue
            }
            docker {
                Write-Host 'installing docker...' -ForegroundColor Cyan
                if (-not $chk.systemd) {
                    # turn on systemd for docker autostart
                    wsl/wsl_systemd.ps1 $Distro -Systemd 'true'
                    wsl.exe --shutdown $Distro
                }
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_docker.sh $chk.user
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
                    wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_omp.sh --theme $OmpTheme --user $chk.user
                }
                continue
            }
            python {
                Write-Host 'installing python packages...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --exec .assets/provision/install_miniconda.sh --fix_certify true
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_python.sh
                if ('az' -in $scopes) {
                    wsl.exe --distribution $Distro --exec .assets/provision/install_azurecli.sh --fix_certify true
                }
                continue
            }
            rice {
                Write-Host 'ricing distro ...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_btop.sh
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_cmatrix.sh
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_cowsay.sh
                $rel_ff = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_fastfetch.sh $Script:rel_ff
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
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.ps1 -UserName $chk.user
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.sh $chk.user
                Write-Host 'setting up profile for current user...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.ps1
                if ('az' -in $scopes) {
                    $cmd = 'if (-not (Get-InstalledPSResource Az)) { Write-Host "installing Az..."; Install-PSResource Az }'
                    wsl.exe --distribution $Distro -- pwsh -nop -c $cmd
                }
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.sh
                continue
            }
        }
        # *install PowerShell modules from ps-modules repository
        if ($chk.shell) {
            # instantiate psmodules generic lists
            $modules = [Collections.Generic.HashSet[String]]::new()
            $PSModules.ForEach({ $modules.Add($_) | Out-Null })

            # determine modules to install
            if ('az' -in $scopes) {
                $modules.Add('do-az') | Out-Null
                Write-Verbose "Added `e[3mdo-az`e[23m to be installed from ps-modules."
            }
            $modules.Add('aliases-git') | Out-Null # git is always installed
            Write-Verbose "Added `e[3maliases-git`e[23m to be installed from ps-modules."
            if ($chk.k8s_base) {
                $modules.Add('aliases-kubectl') | Out-Null
                Write-Verbose "Added `e[3maliases-kubectl`e[23m to be installed from ps-modules."
            }

            $targetRepo = 'ps-modules'
            # determine if target repository exists and clone if necessary
            $getOrigin = { git config --get remote.origin.url }
            $remote = (Invoke-Command $getOrigin) -replace '([:/]szymonos/)[\w-]+', "`$1$targetRepo"
            try {
                Push-Location "../$targetRepo"
                if ((Invoke-Command $getOrigin) -eq $remote) {
                    # refresh target repository
                    git fetch --prune --quiet
                    git switch main --force --quiet 2>$null
                    git reset --hard --quiet 'origin/main'
                } else {
                    Write-Warning "Another `"$targetRepo`" repository exists."
                    $modules = [System.Collections.Generic.HashSet[string]]::new()
                }
                Pop-Location
            } catch {
                # clone target repository
                git clone $remote "../$targetRepo"
            }
            Write-Host 'installing ps-modules...' -ForegroundColor Cyan
            if ('do-common' -in $modules) {
                Write-Host "`e[3mAllUsers`e[23m    : do-common" -ForegroundColor DarkGreen
                wsl.exe --distribution $Distro --user root --exec ../$targetRepo/module_manage.ps1 'do-common' -CleanUp
                $modules.Remove('do-common') | Out-Null
            }
            if ($modules.Count -gt 0) {
                Write-Host "`e[3mCurrentUser`e[23m : $modules" -ForegroundColor DarkGreen
                $cmd = "@($($modules | Join-String -SingleQuote -Separator ',')) | ../$targetRepo/module_manage.ps1 -CleanUp"
                wsl.exe --distribution $Distro --exec pwsh -nop -c $cmd
            }
        }
        # *set gtk theme for wslg
        if ($chk.wslg) {
            $GTK_THEME = if ($GtkTheme -eq 'light') {
                $chk.gtkd ? '"Adwaita"' : $null
            } else {
                $chk.gtkd ? $null : '"Adwaita:dark"'
            }
            if ($GTK_THEME) {
                Write-Host "setting `e[3m$GtkTheme`e[23m gtk theme..." -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root -- bash -c "echo 'export GTK_THEME=$GTK_THEME' >/etc/profile.d/gtk_theme.sh"
            }
        }
    }

    if ($PsCmdlet.ParameterSetName -eq 'GitHub') {
        # *install GitHub CLI
        wsl.exe --distribution $Distro --user root --exec .assets/provision/install_gh.sh

        # *setup git config
        $builder = [System.Text.StringBuilder]::new()
        # set up git author identity
        $gitConfig = git config --list --global 2>$null | Select-String '^user\b' -Raw
        if ($gitConfig) {
            foreach ($cfg in $gitConfig) {
                $setting, $value = $cfg.Split('=')
                $builder.AppendLine("git config --global $setting '$value'") | Out-Null
            }
        } else {
            Write-Warning 'Git author identity unknown.'
            do {
                $user = Read-Host -Prompt 'provide git user name'
            } until ($user)
            $builder.AppendLine("git config --global user.name '$user'") | Out-Null
            do {
                $email = Read-Host -Prompt 'provide git email'
            } until ($email -match '\S+@\S+')
            $builder.AppendLine("git config --global user.email '$email'") | Out-Null
        }
        # setup eol/crlf settings
        $builder.AppendLine('git config --global core.eol lf') | Out-Null
        $builder.AppendLine('git config --global core.autocrlf input') | Out-Null
        wsl.exe --distribution $Distro --exec bash -c $builder.ToString().Trim()

        # *check ssh keys and create if necessary
        if (-not (Test-Path "$HOME/.ssh/id_*")) {
            ssh-keygen -t ecdsa -b 521 -f "$HOME/.ssh/id_ecdsa" -q -N ''
            $idPub = Get-ChildItem "$HOME/.ssh/id_ecdsa.pub" | Select-Object -First 1 | Get-Content
            if ($idPub) {
                Write-Host 'Copy below public key and add to SSH keys on "https://github.com/settings/keys".' -ForegroundColor White
                Write-Host "`nTitle:" -ForegroundColor Cyan
                Write-Host $idPub.Split()[-1]
                Write-Host "`nKey:" -ForegroundColor Cyan
                Write-Host $idPub
                Write-Host "`nPress any key to continue"
                [System.Console]::ReadKey() | Out-Null
            }
        }

        # *clone GitHub repositories
        Write-Host 'cloning GitHub repositories...' -ForegroundColor Cyan
        wsl.exe --distribution $Distro --exec .assets/provision/setup_gh_repos.sh --repos "$Repos" --user $env:USERNAME
    }
}

end {
    Pop-Location
}
