#Requires -PSEdition Core -Version 7.3
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
- installing Python environment management tools: pip, uv, venv and conda,
- cloning GH repositories and setting up VSCode workspace,
- updating packages in all existing WSL distros.
When GH repositories cloning is used, you need to generate and add an SSH key to your GH account.

.PARAMETER Distro
Name of the WSL distro to set up. If not specified, script will update all existing distros.
.PARAMETER Scope
List of installation scopes. Valid values:
- az: azure-cli, azcopy, Az PowerShell module if pwsh scope specified; autoselects python scope
- conda: miniforge
- distrobox: (WSL2 only) - podman and distrobox
- docker: (WSL2 only) - docker, containerd buildx docker-compose
- gcloud: google-cloud-cli
- k8s_base: kubectl, kubelogin, k9s, kubecolor, kubectx, kubens
- k8s_dev: argorollouts, cilium, helm, flux, kustomize cli tools; autoselects k8s_base scope
- k8s_ext: (WSL2 only) - minikube, k3d, kind local kubernetes tools; autoselects docker, k8s_base and k8s_dev scopes
- nodejs: Node.js JavaScript runtime environment
- pwsh: PowerShell Core and corresponding PS modules; autoselects shell scope
- python: uv, prek, pip, venv
- rice: btop, cmatrix, cowsay, fastfetch
- shell: bat, eza, oh-my-posh, ripgrep, yq
- terraform: terraform, terrascan, tflint, tfswitch
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
.PARAMETER SkipRepoUpdate
Skip updating current repository before running the setup.

.EXAMPLE
$Distro = 'Ubuntu'
# :set up WSL distro using default values
wsl/wsl_setup.ps1 $Distro
wsl/wsl_setup.ps1 $Distro -AddCertificate
wsl/wsl_setup.ps1 $Distro -FixNetwork -AddCertificate
# :set up WSL distro with specified installation scopes
$Scope = @('conda', 'pwsh')
$Scope = @('conda', 'k8s_ext', 'pwsh', 'rice')
$Scope = @('az', 'docker', 'shell')
$Scope = @('az', 'k8s_base', 'pwsh', 'nodejs', 'terraform')
$Scope = @('az', 'gcloud', 'k8s_ext', 'pwsh')
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

.NOTES
# :save script example
./scripts_egsave.ps1 wsl/wsl_setup.ps1
# :override the existing script example if exists
./scripts_egsave.ps1 wsl/wsl_setup.ps1 -Force
# :open the example script in VSCode
code -r (./scripts_egsave.ps1 wsl/wsl_setup.ps1 -WriteOutput)
#>
using namespace System.Management.Automation.Host

[CmdletBinding(DefaultParameterSetName = 'Update')]
param (
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Setup')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'GitHub')]
    [string]$Distro,

    [Alias('s')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateScript(
        { $_.ForEach({ $_ -in @('az', 'conda', 'distrobox', 'docker', 'gcloud', 'k8s_base', 'k8s_dev', 'k8s_ext', 'nodejs', 'oh_my_posh', 'pwsh', 'python', 'rice', 'shell', 'terraform', 'zsh') }) -notcontains $false },
        ErrorMessage = 'Wrong scope provided. Valid values: az conda distrobox docker gcloud k8s_base k8s_dev k8s_ext nodejs pwsh python rice shell terraform zsh')
    ]
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
    [ValidateScript(
        { $_.ForEach({ $_ -match '^[\w-]+/[\w-]+$' }) -notcontains $false },
        ErrorMessage = 'Repos should be provided in "Owner/RepoName" format.')
    ]
    [string[]]$Repos,

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [switch]$AddCertificate,

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [switch]$FixNetwork,

    [switch]$SkipRepoUpdate
)

begin {
    $ErrorActionPreference = 'Stop'
    # check if the script is running on Windows
    if ($IsLinux) {
        Write-Warning 'This script is intended to be run on Windows only (outside of WSL).'
        exit 1
    }

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
    # import InstallUtils for the Invoke-GhRepoClone function
    Import-Module (Convert-Path './modules/InstallUtils') -Force
    # import SetupUtils for the Set-WslConf function
    Import-Module (Convert-Path './modules/SetupUtils') -Force

    if (-not $SkipRepoUpdate) {
        Show-LogContext 'checking if the repository is up to date'
        if ((Update-GitRepository) -eq 2) {
            Write-Warning 'Repository has been updated. Run the script again!'
            exit 0
        }
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
                Show-LogContext "specified distribution not found ($Distro), proceeding to install"
                try {
                    Get-Service WSLService | Out-Null
                    wsl.exe --install --distribution $Distro --web-download --no-launch
                    if ($? -and $Distro -notin (Get-WslDistro -FromRegistry).Name) {
                        Write-Host "`nSetting up user profile in WSL distro. Type 'exit' when finished to proceed with WSL setup!`n" -ForegroundColor Yellow
                        wsl.exe --install --distribution $Distro --web-download
                    }
                    if (-not $?) {
                        Show-LogContext "`"$Distro`" distro installation failed." -Level ERROR
                        exit 1
                    }
                } catch {
                    if (Test-IsAdmin) {
                        wsl.exe --install --distribution $Distro --web-download
                        if ($?) {
                            Show-LogContext 'WSL service installation finished.'
                            Show-LogContext "`nRestart the system and run the script again to install the specified WSL distro!`n" -Level WARNING
                        } else {
                            Show-LogContext 'WSL service installation failed.' -Level ERROR
                            exit 1
                        }
                    } else {
                        Show-LogContext "`nInstalling WSL service. Wait for the process to finish and restart the system!`n" -Level WARNING
                        Start-Process pwsh.exe "-NoProfile -Command `"wsl.exe --install --distribution $Distro --web-download`"" -Verb RunAs
                        if ($?) {
                            Show-LogContext 'WSL service installation finished.'
                            Show-LogContext "`nRestart the system and run the script again to install the specified WSL distro!`n" -Level WARNING
                        } else {
                            Show-LogContext 'WSL service installation failed.' -Level ERROR
                            exit 1
                        }
                    }
                    exit 0
                }
            } else {
                Show-LogContext "The specified distro does not exist ($Distro)." -Level WARNING
                exit 1
            }
        } elseif ($lxss.Where({ $_.Name -eq $Distro }).Version -eq 1) {
            Show-LogContext "The distribution `"$Distro`" is currently using WSL1!" -Level WARNING
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
                        Show-LogContext 'unregistering current distro'
                        wsl.exe --unregister $Distro
                        break
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
                        Show-LogContext "installing selected distro ($Distro)"
                        break
                    }
                }
                wsl.exe --install --distribution $Distro --web-download --no-launch
            }
        }
        Show-LogContext 'getting GitHub authentication config from the default distro'
        $defDistro = $lxss.Where({ $_.Default }).Name
        if ($defDistro -ne $Distro) {
            $cmdArgs = @('-u', (wsl.exe --distribution $defDistro -- id -un), '-k')
            $gh_cfg = wsl.exe --distribution $defDistro --user root --exec .assets/provision/setup_gh_https.sh @cmdArgs
        }
        # get installed distro details
        $lxss = Get-WslDistro -FromRegistry | Where-Object Name -EQ $Distro
    } elseif ($lxss) {
        Write-Host "Found $($lxss.Count) distro$($lxss.Count -eq 1 ? '' : 's') to update:" -ForegroundColor White
        $lxss.Name.ForEach({ Write-Host " - $_" })
    } else {
        Show-LogContext 'No installed WSL distributions found.' -Level WARNING
        exit 0
    }

    # determine GTK theme if not provided, based on system theme
    if (-not $GtkTheme) {
        $systemUsesLightTheme = Get-ItemPropertyValue -ErrorAction SilentlyContinue `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' `
            -Name 'SystemUsesLightTheme'
        $GtkTheme = $systemUsesLightTheme ? 'light' : 'dark'
    }

    # script variable that determines if public SSH key has been added to GitHub
    $script:sshStatus = @{ 'sshKey' = 'missing' }

    # sets to track success and failed distros
    $successDistros = [System.Collections.Generic.SortedSet[string]]::new()
    $failDistros = [System.Collections.Generic.SortedSet[string]]::new()
}

process {
    foreach ($lx in $lxss) {
        $Distro = $lx.Name

        #region distro checks
        $chkStr = wsl.exe -d $Distro --exec .assets/provision/distro_check.sh
        try {
            $chk = $chkStr | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        } catch {
            Show-LogContext $_
            Show-LogContext "Failed to check the distro '$Distro'." -Level WARNING
            Write-Host "`nThe WSL seems to be not responding correctly. Run the script again!"
            Write-Host 'If the problem persists, run the wsl/wsl_restart.ps1 script as administrator and try again.'
            exit 1
        }
        if ($chk.uid -eq 0) {
            if ($chk.def_uid -ge 1000) {
                Write-Host "`nSetting up user profile in WSL distro. Type 'exit' when finished to proceed with WSL setup!`n" -ForegroundColor Yellow
                wsl.exe --distribution $Distro
                # rerun distro_check to get updated user
                $chk = wsl.exe -d $Distro --exec .assets/provision/distro_check.sh | ConvertFrom-Json -AsHashtable
            } else {
                $msg = [string]::Join("`n",
                    "`n`e[93;1mWARNING: The '$Distro' WSL distro is set to use the root user.`e[0m`n",
                    'This setup requires the non-root user to be configured as the default one.',
                    "`e[97;1mRun the script again after creating a non-root user profile.`e[0m"
                )
                Write-Host $msg
                # mark distro as failed
                $failDistros.Add($Distro) | Out-Null
                continue
            }
        }

        $scopeSet = [System.Collections.Generic.HashSet[string]]::new()
        $Scope.ForEach({ $scopeSet.Add($_) | Out-Null })
        # *determine additional scopes from distro check
        switch ($chk) {
            { $_.az } { $scopeSet.Add('az') | Out-Null }
            { $_.conda } { $scopeSet.Add('conda') | Out-Null }
            { $_.gcloud } { $scopeSet.Add('gcloud') | Out-Null }
            { $_.k8s_base } { $scopeSet.Add('k8s_base') | Out-Null }
            { $_.k8s_dev } { $scopeSet.Add('k8s_dev') | Out-Null }
            { $_.k8s_ext } { $scopeSet.Add('k8s_ext') | Out-Null }
            { $_.pwsh } { $scopeSet.Add('pwsh') | Out-Null }
            { $_.python } { $scopeSet.Add('python') | Out-Null }
            { $_.shell } { $scopeSet.Add('shell') | Out-Null }
            { $_.terraform } { $scopeSet.Add('terraform') | Out-Null }
        }
        # add corresponding scopes
        switch (@($scopeSet)) {
            az { $scopeSet.Add('python') | Out-Null }
            k8s_dev { $scopeSet.Add('k8s_base') | Out-Null }
            k8s_ext { @('docker', 'k8s_base', 'k8s_dev').ForEach({ $scopeSet.Add($_) | Out-Null }) }
            pwsh { $scopeSet.Add('shell') | Out-Null }
            zsh { $scopeSet.Add('shell') | Out-Null }
        }
        # determine 'oh_my_posh' scope
        if ($lx.Version -eq 2 -and ($chk.oh_my_posh -or $OmpTheme)) {
            @('oh_my_posh', 'shell').ForEach({ $scopeSet.Add($_) | Out-Null })
        }
        # remove scopes unavailable in WSL1
        if ($lx.Version -eq 1) {
            $scopeSet.Remove('distrobox') | Out-Null
            $scopeSet.Remove('docker') | Out-Null
            $scopeSet.Remove('k8s_ext') | Out-Null
            $scopeSet.Remove('oh_my_posh') | Out-Null
        }

        # sort scopes for the specific installation order
        [string[]]$scopes = $scopeSet | Sort-Object -Unique {
            switch ($_) {
                'docker' { 1 }
                'k8s_base' { 2 }
                'k8s_dev' { 3 }
                'k8s_ext' { 4 }
                'python' { 5 }
                'conda' { 6 }
                'az' { 7 }
                'gcloud' { 8 }
                'nodejs' { 9 }
                'terraform' { 10 }
                'oh_my_posh' { 11 }
                'shell' { 12 }
                'zsh' { 13 }
                'pwsh' { 14 }
                'distrobox' { 15 }
                'rice' { 16 }
                default { 17 }
            }
        }
        # display distro name and installed scopes
        Write-Host "`n`e[95;1m${Distro}$($scopes.Count ? " :`e[0;90m $($scopes -join ', ')`e[0m" : "`e[0m")"
        #endregion

        #region perform base setup
        # *fix WSL networking
        if ($FixNetwork) {
            Show-LogContext 'fixing network'
            wsl/wsl_network_fix.ps1 $Distro
        }

        # *install certificates
        if ($AddCertificate) {
            Show-LogContext 'adding certificates in chain'
            wsl/wsl_certs_add.ps1 $Distro
        }
        if (wsl.exe --distribution $Distro -- bash -c 'curl https://www.google.com 2>&1 | grep -q "(60) SSL certificate problem" && echo 1') {
            Show-LogContext 'SSL certificate problem: self-signed certificate in certificate chain. Script execution halted.' -Level ERROR
            exit 1
        }

        # *install packages
        Show-LogContext 'updating system'
        wsl.exe --distribution $Distro --user root --exec .assets/provision/fix_secure_path.sh
        wsl.exe --distribution $Distro --user root --exec .assets/provision/upgrade_system.sh
        wsl.exe --distribution $Distro --user root --exec .assets/provision/install_base.sh $chk.user
        if ($PsCmdlet.ParameterSetName -eq 'Update' -and $chk.pixi) {
            Show-LogContext 'updating pixi packages'
            wsl.exe --distribution $Distro --cd ~ --exec .pixi/bin/pixi global update
        }

        # *boot setup
        wsl.exe --distribution $Distro --user root install -m 0755 .assets/provision/autoexec.sh /etc
        if (-not $chk.wsl_boot) {
            Set-WslConf -Distro $Distro -ConfDict ([ordered]@{ boot = @{ command = '"[ -x /etc/autoexec.sh ] && /etc/autoexec.sh || true"' } })
        }
        #endregion

        #region setup GitHub authentication
        # *setup GitHub CLI
        wsl.exe --distribution $Distro --user root --exec .assets/provision/install_gh.sh
        $cmdArgs = [System.Collections.Generic.List[string]]::new([string[]]@('-u', $chk.user))
        if ($sshStatus.sshKey -eq 'missing') {
            $cmdArgs.Add('-k')
        }
        if ($Script:gh_cfg -match 'github\.com') {
            $cmdArgs.AddRange([string[]]@('-c', ($gh_cfg -join "`n")))
        }
        $gh_cfg = wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_gh_https.sh @cmdArgs
        if (-not $?) {
            Write-Host "`nRun the script again to reconfigure GitHub authentication!`n" -ForegroundColor Yellow
            exit 1
        }

        # *check SSH keys and create if necessary
        $sshKey = 'id_ed25519'
        $winKey = "$HOME\.ssh\$sshKey"
        $winKeyPub = "$HOME\.ssh\$sshKey.pub"
        $sshWinPath = "/mnt/$($env:HOMEDRIVE.Replace(':', '').ToLower())$($env:HOMEPATH.Replace('\', '/'))/.ssh"

        $winKeyExists = (Test-Path $winKey) -and (Test-Path $winKeyPub)
        if (-not $chk.ssh_key -and $winKeyExists) {
            # copy Windows SSH keys to WSL
            $cmnd = [string]::Join("`n",
                'mkdir -p $HOME/.ssh',
                "install -m 0600 '$sshWinPath/$sshKey' `$HOME/.ssh",
                "install -m 0644 '$sshWinPath/$sshKey.pub' `$HOME/.ssh"
            )
            wsl.exe --distribution $Distro --exec sh -c $cmnd
        } elseif (-not $winKeyExists) {
            # copy WSL SSH keys to Windows
            if (Test-Path "$HOME\.ssh") {
                Remove-Item $winKey, $winKeyPub -ErrorAction SilentlyContinue
            } else {
                New-Item "$HOME\.ssh" -ItemType Directory | Out-Null
            }
            # build bash command to generate SSH key if needed and copy to Windows
            $cmnd = [string]::Join("`n",
                '# copy SSH key to Windows',
                "cp `"`$HOME/.ssh/id_ed25519`" $sshWinPath/id_ed25519",
                "cp `"`$HOME/.ssh/id_ed25519.pub`" $sshWinPath/id_ed25519.pub"
            )
            if (-not $chk.ssh_key) {
                # generate new SSH key inside WSL if it does not exist
                $cmnd = [string]::Join("`n",
                    '# generate SSH key if missing',
                    '.assets/provision/setup_ssh.sh',
                    $cmnd
                )
            }
            wsl.exe --distribution $Distro --exec sh -c $cmnd
        }

        # *add SSH key to GitHub if needed
        if ($sshStatus.sshKey -eq 'missing') {
            try {
                $sshStatus = wsl.exe --distribution $Distro --exec .assets/provision/setup_gh_ssh.sh | ConvertFrom-Json -AsHashtable -ErrorAction Stop
                if ($sshStatus.sshKey -eq 'added') {
                    Clear-Host
                    # display message asking to authorize the SSH key
                    $msg = [string]::Join("`n",
                        "`e[97;1mSSH key added to GitHub:`e[0;90m $($sshStatus.title)`e[0m`n",
                        "`e[97mTo finish setting up SSH authentication, open `e[34;4mhttps://github.com/settings/ssh`e[97;24m",
                        "and authorize the newly added key for your organization (enable SSO if required).`e[0m",
                        "`npress Enter to continue"
                    )
                    Read-Host $msg
                }
            } catch {
                $sshStatus.sshKey = 'missing'
            }
        }
        #endregion

        #region install scopes
        switch ($scopes) {
            az {
                Show-LogContext 'installing azure-cli'
                wsl.exe --distribution $Distro --exec .assets/provision/install_azurecli_uv.sh --fix_certify true
                $rel_azcopy = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_azcopy.sh $Script:rel_azcopy
                continue
            }
            conda {
                Show-LogContext 'installing conda tools'
                wsl.exe --distribution $Distro --exec .assets/provision/install_miniforge.sh --fix_certify true
                wsl.exe --distribution $Distro --exec .assets/provision/install_pixi.sh
                continue
            }
            distrobox {
                Show-LogContext 'installing distrobox'
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_podman.sh
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_distrobox.sh $chk.user
                continue
            }
            docker {
                Show-LogContext 'installing docker'
                if (-not $chk.systemd) {
                    # turn on systemd for docker autostart
                    wsl/wsl_systemd.ps1 $Distro -Systemd 'true'
                    wsl.exe --shutdown
                }
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_docker.sh $chk.user
                continue
            }
            gcloud {
                Show-LogContext 'installing google-cloud-cli'
                $rel_gcloud = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_gcloud.sh $Script:rel_gcloud
                wsl.exe --distribution $Distro --user root --exec .assets/provision/fix_gcloud_certs.sh
                continue
            }
            k8s_base {
                Show-LogContext 'installing kubernetes base packages'
                $rel_kubectl = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubectl.sh $Script:rel_kubectl && $($chk.k8s_base = $true)
                $rel_kubelogin = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubelogin.sh $Script:rel_kubelogin
                $rel_k9s = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k9s.sh $Script:rel_k9s
                $rel_kubecolor = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubecolor.sh $Script:rel_kubecolor
                $rel_kubectx = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kubectx.sh $Script:rel_kubectx
                continue
            }
            k8s_dev {
                Show-LogContext 'installing kubernetes dev packages'
                $rel_argoroll = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_argorolloutscli.sh $Script:rel_argoroll
                $rel_cilium = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_cilium.sh $Script:rel_cilium
                $rel_flux = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_flux.sh $Script:rel_flux
                $rel_helm = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_helm.sh $Script:rel_helm
                $rel_kustomize = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kustomize.sh $Script:rel_kustomize
                continue
            }
            k8s_ext {
                wsl.exe --distribution $Distro --exec sh -c '[ -f /usr/bin/docker ] && true || false'
                if ($?) {
                    Show-LogContext 'installing local kubernetes tools'
                    $rel_minikube = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_minikube.sh $Script:rel_minikube
                    $rel_k3d = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_k3d.sh $Script:rel_k3d
                    $rel_kind = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_kind.sh $Script:rel_kind
                } else {
                    Show-LogContext 'docker not found, skipping local kubernetes tools installation' -Level WARNING
                }
                continue
            }
            nodejs {
                Show-LogContext 'installing Node.js'
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_nodejs.sh
                if ($AddCertificate) {
                    wsl.exe --distribution $Distro --user root --exec .assets/provision/fix_nodejs_certs.sh
                }
                continue
            }
            oh_my_posh {
                Show-LogContext 'installing oh-my-posh'
                $rel_omp = try { wsl.exe --distribution $Distro --user root --exec .assets/provision/install_omp.sh $Script:rel_omp.version $Script:rel_omp.download_url | ConvertFrom-Json } catch { $null }
                if ($OmpTheme) {
                    wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_omp.sh --theme $OmpTheme --user $chk.user
                }
                continue
            }
            pwsh {
                Show-LogContext 'installing pwsh'
                $rel_pwsh = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_pwsh.sh $Script:rel_pwsh && $($chk.pwsh = $true)
                # setup profiles
                Show-LogContext 'setting up profile for all users'
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.ps1 -UserName $chk.user
                Show-LogContext 'setting up profile for current user'
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.ps1

                # *install PowerShell modules from ps-modules repository
                # clone/refresh szymonos/ps-modules repository
                $repoClone = Invoke-GhRepoClone -OrgRepo 'szymonos/ps-modules' -Path '..'
                if ($repoClone) {
                    Write-Verbose "Repository `"ps-modules`" $($repoClone -eq 1 ? 'cloned': 'refreshed') successfully."
                } else {
                    Write-Error 'Cloning ps-modules repository failed.'
                }
                Show-LogContext 'installing ps-modules'
                Write-Host "`e[32mAllUsers    :`e[0;90m do-common`e[0m"
                wsl.exe --distribution $Distro --user root --exec ../ps-modules/module_manage.ps1 'do-common' -CleanUp
                # instantiate psmodules generic lists
                $modules = [System.Collections.Generic.SortedSet[String]]::new([string[]]@('aliases-git', 'do-linux'))
                # determine modules to install
                if ('az' -in $scopes) {
                    $modules.Add('do-az') | Out-Null
                    Write-Verbose "Added `e[3mdo-az`e[23m to be installed from ps-modules."
                }
                if ('k8s_base' -in $scopes) {
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
                        "`tInvoke-CommandRetry { Install-PSResource Az -WarningAction SilentlyContinue -ErrorAction Stop }`n}",
                        'if (-not (Get-Module -ListAvailable "Az.ResourceGraph")) {',
                        "`tWrite-Host 'installing Az.ResourceGraph...'",
                        "`tInvoke-CommandRetry { Install-PSResource Az.ResourceGraph -ErrorAction Stop }`n}"
                    )
                    wsl.exe --distribution $Distro -- pwsh -nop -c $cmd
                }
                continue
            }
            python {
                Show-LogContext 'installing python tools'
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_python.sh
                $rel_uv = wsl.exe --distribution $Distro --exec .assets/provision/install_uv.sh $Script:rel_uv
                $rel_prek = wsl.exe --distribution $Distro --exec .assets/provision/install_prek.sh $Script:rel_prek
                continue
            }
            rice {
                Show-LogContext 'ricing distro '
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_btop.sh
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_cmatrix.sh
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_cowsay.sh
                $rel_ff = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_fastfetch.sh $Script:rel_ff
                continue
            }
            shell {
                Show-LogContext 'installing shell packages'
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_fzf.sh
                $rel_eza = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_eza.sh $Script:rel_eza
                $rel_bat = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_bat.sh $Script:rel_bat
                $rel_rg = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_ripgrep.sh $Script:rel_rg
                $rel_yq = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_yq.sh $Script:rel_yq
                # setup bash profiles
                Show-LogContext 'setting up profile for all users'
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.sh $chk.user
                Show-LogContext 'setting up profile for current user'
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.sh
                continue
            }
            terraform {
                Show-LogContext 'installing terraform utils'
                $rel_tf = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_terraform.sh $Script:rel_tf
                $rel_trs = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_terrascan.sh $Script:rel_trs
                $rel_tfl = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_tflint.sh $Script:rel_tfl
                $rel_tfs = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_tfswitch.sh $Script:rel_tfs
                continue
            }
            zsh {
                Show-LogContext 'installing zsh'
                wsl.exe --distribution $Distro --user root --exec .assets/provision/install_zsh.sh
                # setup profiles
                Show-LogContext 'setting up zsh profile for current user'
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user_zsh.sh
                continue
            }
        }
        #endregion

        #region set gtk theme for wslg
        if ($lx.Version -eq 2 -and $chk.wslg) {
            $GTK_THEME = if ($GtkTheme -eq 'light') {
                $chk.gtkd ? '"Adwaita"' : $null
            } else {
                $chk.gtkd ? $null : '"Adwaita:dark"'
            }
            if ($GTK_THEME) {
                Show-LogContext "setting `e[3m$GtkTheme`e[23m gtk theme"
                wsl.exe --distribution $Distro --user root -- bash -c "echo 'export GTK_THEME=$GTK_THEME' >/etc/profile.d/gtk_theme.sh"
            }
        }
        #endregion

        #region setup git config
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
            $cmnd = $builder.ToString().Trim() -replace "`r"
            Show-LogContext 'configuring git'
            wsl.exe --distribution $Distro --exec bash -c $cmnd
        }
        #endregion

        # mark distro as successfully set up
        $successDistros.Add($Distro) | Out-Null
    }
    #region clone GitHub repositories
    if ($PsCmdlet.ParameterSetName -eq 'GitHub' -and $Distro -notin $failDistros) {
        Show-LogContext 'cloning GitHub repositories'
        wsl.exe --distribution $Distro --exec .assets/provision/setup_gh_repos.sh --repos "$Repos"
    }
    #endregion
}

end {
    if ($successDistros.Count) {
        if ($successDistros.Count -eq 1) {
            Write-Host "`n`e[95m<< `e[1m$successDistros`e[22m WSL distro was set up successfully >>`e[0m`n"
        } else {
            Write-Host "`n`e[95m<< Successfully set up the following WSL distros >>`e[0m"
            $successDistros.ForEach({ Write-Host " - $_" })
        }
    }
    if ($failDistros.Count) {
        if ($failDistros.Count -eq 1) {
            Write-Host "`n`e[91m<< Failed to set up the `e[4m$failDistros`e[24m WSL distro >>`e[0m`n"
        } else {
            Write-Host "`n`e[91m<< Failed to set up the following WSL distros >>`e[0m"
            $failDistros.ForEach({ Write-Host " - $_" })
        }
    }
}

clean {
    Pop-Location
}
