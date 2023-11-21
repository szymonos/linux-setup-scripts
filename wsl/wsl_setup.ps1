#Requires -PSEdition Core
<#
.SYNOPSIS
Setting up WSL distro(s).
.DESCRIPTION
You can use the script for:
- installing base packages and setting up bash and pwsh shells,
- installing docker-ce locally inside WSL distro (WSL2 only),
- installing podman with distrobox (WSL2 only),
- installing tools for interacting with kubernetes,
- setting gtk theme in WSLg (WSL2 only),
- installing Python environment management tools: venv and miniconda,
- cloning GH repositories and setting up VSCode workspace,
- updating packages in all existing WSL distros.
When GH repositories cloning is used, you need to generate and add an SSH key to your GH account.

.PARAMETER Distro
Name of the WSL distro to set up. If not specified, script will update all existing distros.
.PARAMETER Scope
List of installation scopes. Valid values:
- az: azure-cli, do-az from ps-modules if pwsh scope specified; autoselects python scope
- distrobox: podman and distrobox (WSL2 only)
- docker: docker, containerd buildx docker-compose (WSL2 only)
- k8s_base: kubectl, kubelogin, helm, k9s, kubeseal, flux, kustomize
- k8s_ext: minikube, k3d, argorollouts-cli (WSL2 only); autoselects docker and k8s_base scopes
- pwsh: PowerShell Core and corresponding PS modules; autoselects shell scope
- python: pip, venv, miniconda
- rice: btop, cmatrix, cowsay, fastfetch
- shell: bat, eza, oh-my-posh, ripgrep, yq
- zsh: zsh shell with plugins
.PARAMETER OmpTheme
Specify to install oh-my-posh prompt theme engine and name of the theme to be used.
You can specify one of the three included profiles: base, powerline, nerd,
or use any theme available on the page: https://ohmyposh.dev/docs/themes/
.PARAMETER GtkTheme
Specify gtk theme for wslg. Available values: light, dark.
Default: automatically detects based on the system theme.
.PARAMETER Repos
List of GitHub repositories in format "Owner/RepoName" to clone into the WSL.
.PARAMETER AddCertificate
Intercept and add certificates from chain into selected distro.
.PARAMETER FixNetwork
Set network settings from the selected network interface in Windows.

.EXAMPLE
$Distro = 'Ubuntu'
# :set up WSL distro using default values
wsl/wsl_setup.ps1 $Distro
wsl/wsl_setup.ps1 $Distro -AddCertificate
wsl/wsl_setup.ps1 $Distro -FixNetwork -AddCertificate
# :set up WSL distro with specified installation scopes
$Scope = @('pwsh', 'python')
$Scope = @('k8s_ext', 'pwsh', 'python', 'rice')
$Scope = @('az', 'docker', 'shell')
$Scope = @('az', 'k8s_base', 'pwsh')
$Scope = @('az', 'k8s_ext', 'pwsh')
wsl/wsl_setup.ps1 $Distro -s $Scope
wsl/wsl_setup.ps1 $Distro -s $Scope -AddCertificate
# :set up shell with the specified oh-my-posh theme
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
using namespace System.Management.Automation.Host

[CmdletBinding(DefaultParameterSetName = 'Update')]
param (
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Setup')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'GitHub')]
    [string]$Distro,

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateScript({ $_.ForEach({ $_ -in @('az', 'distrobox', 'docker', 'k8s_base', 'k8s_ext', 'oh_my_posh', 'pwsh', 'python', 'rice', 'shell', 'zsh') }) -notcontains $false },
        ErrorMessage = 'Wrong scope provided. Valid values: az distrobox docker k8s_base k8s_ext python rice shell')]
    [string[]]$Scope,

    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateNotNullOrEmpty()]
    [string]$OmpTheme,

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
    # check if the script is running on Windows
    if (-not $IsWindows) {
        Write-Warning 'Run the script on Windows!'
        exit 0
    }

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
    # import InstallUtils for the Invoke-GhRepoClone function
    Import-Module (Convert-Path './modules/InstallUtils')
    # import SetupUtils for the Set-WslConf function
    Import-Module (Convert-Path './modules/SetupUtils')

    # check if repository is up to date
    Write-Host "`nchecking if the repository is up to date..." -ForegroundColor Cyan
    git fetch
    $remote = "$(git remote)/$(git branch --show-current)"
    if ((git rev-parse HEAD) -ne (git rev-parse $remote)) {
        Write-Warning "Current branch is behind remote, performing hard reset.`n`t Run the script again!`n"
        git reset --hard $remote
        exit 0
    }

    # *get list of distros
    $lxss = Get-WslDistro | Where-Object Name -NotMatch '^docker-desktop'
    if ($PsCmdlet.ParameterSetName -ne 'Update') {
        if ($Distro -notin $lxss.Name) {
            for ($i = 0; $i -lt 5; $i++) {
                if ($onlineDistros = Get-WslDistro -Online) { break }
            }
            # install online distro
            if ($Distro -in $onlineDistros.Name) {
                Write-Host "`nspecified distribution not found ($Distro), proceeding to install..." -ForegroundColor Cyan
                $cmd = "wsl.exe --install --distribution $Distro --web-download"
                try {
                    Get-Service LxssManagerUser*, WSLService | Out-Null
                    Write-Host "`nSetting up user profile in WSL distro. Type 'exit' when finished to proceed with WSL setup!`n" -ForegroundColor Yellow
                    Invoke-Expression $cmd
                } catch {
                    if (Test-IsAdmin) {
                        Invoke-Expression $cmd
                        Write-Host 'WSL service installation finished.'
                        Write-Host "`nRestart the system and run the script again to install the specified WSL distro!`n" -ForegroundColor Yellow
                    } else {
                        Start-Process pwsh.exe "-NoProfile -Command `"$cmd`"" -Verb RunAs
                        Write-Host "`nWSL service installing. Wait for the process to finish and restart the system!`n" -ForegroundColor Yellow
                    }
                    exit 0
                }
            } else {
                Write-Warning "The specified distro does not exist ($Distro)."
                exit 1
            }
        } elseif ($lxss.Where({ $_.Name -eq $Distro }).Version -eq 1) {
            Write-Host ''
            Write-Warning "The distribution `"$Distro`" is currently using WSL1!"
            $caption = 'It is strongly recommended to use WSL2.'
            $message = 'Select your choice:'
            $choices = @(
                @{ choice = '&Replace the current distro'; desc = "Delete current '$Distro' distro and install it as WSL2." }
                @{ choice = '&Select another distro to install'; desc = 'Select from other online distros to install as WSL2.' }
                @{ choice = '&Continue setup of the current distro'; desc = "Continue setup of the current WSL1 '$Distro' distro." }
            )
            [ChoiceDescription[]]$options = $choices.ForEach({ [ChoiceDescription]::new($_.choice, $_.desc) })
            $choice = $Host.UI.PromptForChoice($caption, $message, $options, -1)
            if ($choice -ne 2) {
                # check the default WSL version and change to 2 if necessary
                if ((Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss').DefaultVersion -ne 2) {
                    wsl.exe --set-default-version 2
                }
                switch ($choice) {
                    0 {
                        Write-Host "`nunregistering current distro..." -ForegroundColor Cyan
                        wsl.exe --unregister $Distro
                        continue
                    }
                    1 {
                        for ($i = 0; $i -lt 5; $i++) {
                            if ($onlineDistros = Get-WslDistro -Online) {
                                $onlineDistros = $onlineDistros.Name | Where-Object {
                                    $_ -ne $Distro -and $_ -match 'ubuntu|debian'
                                }
                                break
                            }
                        }
                        $Distro = Get-ArrayIndexMenu $onlineDistros -Message 'Choose distro to install' -Value
                        Write-Host "`ninstalling selected distro ($Distro)..." -ForegroundColor Cyan
                        continue
                    }
                }
                Write-Host "`nSetting up user profile in WSL distro. Type 'exit' when finished to proceed with WSL setup!`n" -ForegroundColor Yellow
                wsl.exe --install --distribution $Distro --web-download
            }
        }
        # get installed distro details
        $lxss = Get-WslDistro -FromRegistry | Where-Object Name -EQ $Distro
    } elseif ($lxss) {
        Write-Host "Found $($lxss.Count) distro$($lxss.Count -eq 1 ? '' : 's') to update." -ForegroundColor White
        $lxss.Name.ForEach({ Write-Host "- $_" })
        $lxss.Count ? '' : $null
    } else {
        Write-Warning 'No installed WSL distributions found.'
        exit 0
    }

    # determine GTK theme if not provided, based on system theme
    if (-not $GtkTheme) {
        $systemUsesLightTheme = Get-ItemPropertyValue -ErrorAction SilentlyContinue `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' `
            -Name 'SystemUsesLightTheme'
        $GtkTheme = $systemUsesLightTheme ? 'light' : 'dark'
    }
}

process {
    foreach ($lx in $lxss) {
        $Distro = $lx.Name
        # *perform distro checks
        $cmd = [string]::Join('',
            '[ -f /usr/bin/rg ] && shell="true" || shell="false";',
            '[ -f /usr/bin/pwsh ] && pwsh="true" || pwsh="false";',
            '[ -f /usr/bin/zsh ] && zsh="true" || zsh="false";',
            '[ -f /usr/bin/kubectl ] && k8s_base="true" || k8s_base="false";',
            '[ -f /usr/local/bin/k3d ] && k8s_ext="true" || k8s_ext="false";',
            '[ -f /usr/bin/oh-my-posh ] && omp="true" || omp="false";',
            '[ -d $HOME/.local/share/powershell/Modules/Az ] && az="true" || az="false";',
            '[ -d $HOME/miniconda3 ] && python="true" || python="false";',
            '[ -f $HOME/.ssh/id_ed25519 ] && ssh_key="true" || ssh_key="false";',
            '[ -d /mnt/wslg ] && wslg="true" || wslg="false";',
            '[ -x /etc/autoexec.sh ] && wsl_boot="true" || wsl_boot="false";',
            'git_user_name="$(git config --global --get user.name 2>/dev/null)";',
            '[ -n "$git_user_name" ] && git_user="true" || git_user="false";',
            'git_user_email="$(git config --global --get user.email 2>/dev/null)";',
            '[ -n "$git_user_email" ] && git_email="true" || git_email="false";',
            'grep -qw "systemd.*true" /etc/wsl.conf 2>/dev/null && systemd="true" || systemd="false";',
            'grep -Fqw "dark" /etc/profile.d/gtk_theme.sh 2>/dev/null && gtkd="true" || gtkd="false";',
            'printf "{\"user\":\"$(id -un)\",\"shell\":$shell,\"k8s_base\":$k8s_base,\"k8s_ext\":$k8s_ext,\"omp\":$omp,',
            '\"az\":$az,\"wslg\":$wslg,\"wsl_boot\":$wsl_boot,\"python\":$python,\"systemd\":$systemd,\"gtkd\":$gtkd,',
            '\"pwsh\":$pwsh,\"zsh\":$zsh,\"git_user\":$git_user,\"git_email\":$git_email,\"ssh_key\":$ssh_key}"'
        )
        # check existing distro setup
        $chk = wsl.exe -d $Distro --exec sh -c $cmd | ConvertFrom-Json -AsHashtable
        # instantiate scope generic sorted set
        $scopes = [System.Collections.Generic.SortedSet[string]]::new()
        $Scope.ForEach({ $scopes.Add($_) | Out-Null })
        # *determine additional scopes from distro check
        switch ($chk) {
            { $_.az } { $scopes.Add('az') | Out-Null }
            { $_.k8s_base } { $scopes.Add('k8s_base') | Out-Null }
            { $_.k8s_ext } { $scopes.Add('k8s_ext') | Out-Null }
            { $_.pwsh } { $scopes.Add('pwsh') | Out-Null }
            { $_.python } { $scopes.Add('python') | Out-Null }
            { $_.shell } { $scopes.Add('shell') | Out-Null }
        }
        # add corresponding scopes
        switch (@($scopes)) {
            az { $scopes.Add('python') | Out-Null }
            k8s_ext { @('docker', 'k8s_base').ForEach({ $scopes.Add($_) | Out-Null }) }
            pwsh { $scopes.Add('shell') | Out-Null }
            zsh { $scopes.Add('shell') | Out-Null }
        }
        # determine 'oh_my_posh' scope
        if ($chk.omp -or $OmpTheme) {
            @('oh_my_posh', 'shell').ForEach({ $scopes.Add($_) | Out-Null })
        }
        # remove scopes unavailable in WSL1
        if ($lx.Version -eq 1) {
            $scopes.Remove('distrobox') | Out-Null
            $scopes.Remove('docker') | Out-Null
            $scopes.Remove('k8s_ext') | Out-Null
        }
        # display distro name and installed scopes
        Write-Host "`n`e[95;1m${Distro}$($scopes.Count ? " :`e[0;90m $($scopes -join ', ')`e[0m" : "`e[0m")"
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
        # *boot setup
        if (-not $chk.wsl_boot) {
            wsl.exe --distribution $Distro --user root install -m 0755 .assets/provision/autoexec.sh /etc
            Set-WslConf -Distro $Distro -ConfDict ([ordered]@{ boot = @{ command = '"[ -x /etc/autoexec.sh ] && /etc/autoexec.sh || true"' } })
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
                $rel_k9s = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k9s.sh $Script:rel_k9s
                $rel_kubeseal = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubeseal.sh $Script:rel_kubeseal
                $rel_flux = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_flux.sh $Script:rel_flux
                $rel_kustomize = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kustomize.sh $Script:rel_kustomize
                continue
            }
            k8s_ext {
                Write-Host 'installing kubernetes additional packages...' -ForegroundColor Cyan
                $rel_minikube = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_minikube.sh $Script:rel_minikube
                $rel_k3d = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k3d.sh $Script:rel_k3d
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
            pwsh {
                Write-Host 'installing pwsh...' -ForegroundColor Cyan
                $rel_pwsh = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_pwsh.sh $Script:rel_pwsh && $($chk.pwsh = $true)
                # *setup profiles
                Write-Host 'setting up profile for all users...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.ps1 -UserName $chk.user
                Write-Host 'setting up profile for current user...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.ps1
                # *install PowerShell modules from ps-modules repository
                # clone/refresh szymonos/ps-modules repository
                $repoClone = Invoke-GhRepoClone -OrgRepo 'szymonos/ps-modules' -Path '..'
                if ($repoClone) {
                    Write-Verbose "Repository `"ps-modules`" $($repoClone -eq 1 ? 'cloned': 'refreshed') successfully."
                } else {
                    Write-Error 'Cloning ps-modules repository failed.'
                }
                Write-Host 'installing ps-modules...' -ForegroundColor Cyan
                Write-Host "`e[32mAllUsers    :`e[0;90m do-common`e[0m"
                wsl.exe --distribution $Distro --user root --exec ../ps-modules/module_manage.ps1 'do-common' -CleanUp
                # instantiate psmodules generic lists
                $modules = [System.Collections.Generic.SortedSet[String]]::new([string[]]@('aliases-git', 'do-linux'))
                # determine modules to install
                if ('az' -in $scopes) {
                    $modules.Add('do-az') | Out-Null
                    Write-Verbose "Added `e[3mdo-az`e[23m to be installed from ps-modules."
                }
                if ($chk.k8s_base) {
                    $modules.Add('aliases-kubectl') | Out-Null
                    Write-Verbose "Added `e[3maliases-kubectl`e[23m to be installed from ps-modules."
                }
                Write-Host "`e[32mCurrentUser :`e[0;90m $($modules -join ', ')`e[0m"
                $cmd = "@($($modules | Join-String -SingleQuote -Separator ',')) | ../ps-modules/module_manage.ps1 -CleanUp"
                wsl.exe --distribution $Distro --exec pwsh -nop -c $cmd
                # *install PowerShell Az modules
                if ('az' -in $scopes) {
                    $cmd = [string]::Join("`n",
                        'if (-not (Get-Module -ListAvailable "Az")) {',
                        "`tWrite-Host 'installing Az...'",
                        "`tInvoke-CommandRetry { Install-PSResource Az -WarningAction SilentlyContinue }`n}",
                        'if (-not (Get-Module -ListAvailable "Az.ResourceGraph")) {',
                        "`tWrite-Host 'installing Az.ResourceGraph...'",
                        "`tInvoke-CommandRetry { Install-PSResource Az.ResourceGraph }`n}"
                    )
                    wsl.exe --distribution $Distro -- pwsh -nop -c $cmd
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
                $rel_eza = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_eza.sh $Script:rel_eza
                $rel_bat = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_bat.sh $Script:rel_bat
                $rel_rg = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_ripgrep.sh $Script:rel_rg
                $rel_yq = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_yq.sh $Script:rel_yq
                # *setup profiles
                Write-Host 'setting up profile for all users...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.sh $chk.user
                Write-Host 'setting up profile for current user...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.sh
                continue
            }
            zsh {
                Write-Host 'installing zsh...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_zsh.sh
                # *setup profiles
                Write-Host 'setting up zsh profile for current user...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user_zsh.sh
                continue
            }
        }
        # *set gtk theme for wslg
        if ($lx.Version -eq 2 -and $chk.wslg) {
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
        # *setup git config
        $builder = [System.Text.StringBuilder]::new()
        # set up git author identity
        if (-not $chk.git_user) {
            if (-not ($user = git config --global --get user.name)) {
                $user = try {
                    Get-LocalUser -Name $env:USERNAME | Select-Object -ExpandProperty FullName
                } catch {
                    try {
                        [string[]]$userArr = ([ADSI]"LDAP://$(WHOAMI /FQDN 2>$null)").displayName.Split(',').Trim()
                        if ($userArr.Count -gt 1) { [array]::Reverse($userArr) }
                        "$userArr"
                    } catch {
                        ''
                    }
                }
                while (-not $user) {
                    $user = Read-Host -Prompt 'provide git user name'
                }
                git config --global user.name "$user"
            }
            $builder.AppendLine("git config --global user.name '$user'") | Out-Null
        }
        if (-not $chk.git_email) {
            if (-not ($email = git config --global --get user.email)) {
                $email = try {
                (Get-ChildItem -Path HKCU:\Software\Microsoft\IdentityCRL\UserExtendedProperties).PSChildName
                } catch {
                    try {
                    ([ADSI]"LDAP://$(WHOAMI /FQDN 2>$null)").mail
                    } catch {
                        ''
                    }
                }
                while ($email -notmatch '.+@.+') {
                    $email = Read-Host -Prompt 'provide git user email'
                }
                git config --global user.email "$email"
            }
            $builder.AppendLine("git config --global user.email '$email'") | Out-Null
        }
        if (-not ($chk.git_user -and $chk.git_email)) {
            # additional git settings
            $builder.AppendLine('git config --global core.eol lf') | Out-Null
            $builder.AppendLine('git config --global core.autocrlf input') | Out-Null
            $builder.AppendLine('git config --global core.longpaths true') | Out-Null
            $builder.AppendLine('git config --global push.autoSetupRemote true') | Out-Null
            Write-Host 'configuring git...' -ForegroundColor Cyan
            wsl.exe --distribution $Distro --exec bash -c $builder.ToString().Trim()
        }
        # *check ssh keys and create if necessary
        if (-not $chk.ssh_key) {
            $sshKey = '.ssh/id_ed25519'
            if (-not ((Test-Path "$HOME/$sshKey") -and (Test-Path "$HOME/$sshKey.pub"))) {
                ssh-keygen -t ed25519 -f "$HOME/$sshKey" -q -N ''
                $idPub = [System.IO.File]::ReadAllLines("$HOME/$sshKey.pub")
                $msg = [string]::Join("`n",
                    "`e[97mUse the following values to add new SSH Key on `e[34;4mhttps://github.com/settings/ssh/new`e[97;24m",
                    "`n`e[1;96mTitle`e[0m`n$($idPub.Split()[-1])",
                    "`n`e[1;96mKey type`e[30m`n<Authentication Key>",
                    "`n`e[1;96mKey`e[0m`n$idPub",
                    "`npress any key to continue..."
                )
                Write-Host $msg
                [System.Console]::ReadKey() | Out-Null
            }
            Write-Host 'copying ssh keys...' -ForegroundColor Cyan
            $mntHome = "/mnt/$($env:HOMEDRIVE.Replace(':', '').ToLower())$($env:HOMEPATH.Replace('\', '/'))"
            $cmd = [string]::Join("`n",
                'mkdir -p $HOME/.ssh',
                "install -m 0400 '$mntHome/$sshKey' `$HOME/.ssh",
                "install -m 0400 '$mntHome/$sshKey.pub' `$HOME/.ssh"
            )
            wsl.exe --distribution $Distro --exec sh -c $cmd
        }
    }

    if ($PsCmdlet.ParameterSetName -eq 'GitHub') {
        # *install GitHub CLI
        wsl.exe --distribution $Distro --user root --exec .assets/provision/install_gh.sh
        # *clone GitHub repositories
        Write-Host 'cloning GitHub repositories...' -ForegroundColor Cyan
        wsl.exe --distribution $Distro --exec .assets/provision/setup_gh_repos.sh --repos "$Repos"
    }
}

end {
    Pop-Location
}
