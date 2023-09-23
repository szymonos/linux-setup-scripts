#Requires -PSEdition Core
<#
.SYNOPSIS
Setting up WSL distro(s).
.DESCRIPTION
You can use the script for:
- installing base packages and setting up bash and pwsh shells,
- installing tools for interacting with kubernetes,
- installing Python environment management tools: venv and miniconda,
- cloning GH repositories and setting up VSCode workspace,
- updating packages in all existing WSL distros.
When GH repositories cloning is used, you need to generate and add an SSH key to your GH account.

.PARAMETER Distro
Name of the WSL distro to set up. If not specified, script will update all existing distros.
.PARAMETER Scope
List of installation scopes. Valid values:
- az: azure-cli if python scope specified, do-az from ps-modules if shell scope specified.
- python: pip, venv, miniconda
- shell: bat, exa, oh-my-posh, pwsh, ripgrep
Default: @('shell').
.PARAMETER OmpTheme
Specify to install oh-my-posh prompt theme engine and name of the theme to be used.
You can specify one of the three included profiles: base, powerline, nerd,
or use any theme available on the page: https://ohmyposh.dev/docs/themes/
Default: 'base'
.PARAMETER Repos
List of GitHub repositories in format "Owner/RepoName" to clone into the WSL.
.PARAMETER AddCertificate
Intercept and add certificates from chain into selected distro.

.EXAMPLE
$Distro = 'Ubuntu'
# :set up WSL distro using default values
wsl/wsl1_setup.ps1 $Distro
wsl/wsl1_setup.ps1 $Distro -AddCertificate
# :set up WSL distro using specified values
$Scope = @('az', 'python', 'shell')
wsl/wsl1_setup.ps1 $Distro -s $Scope
wsl/wsl1_setup.ps1 $Distro -s $Scope -AddCertificate
$OmpTheme = 'nerd'
wsl/wsl1_setup.ps1 $Distro -s $Scope -o $OmpTheme
wsl/wsl1_setup.ps1 $Distro -s $Scope -o $OmpTheme -AddCertificate
# :set up WSL distro and clone specified GitHub repositories
$Repos = @('szymonos/linux-setup-scripts', 'szymonos/ps-modules')
wsl/wsl1_setup.ps1 $Distro -r $Repos -s $Scope -o $OmpTheme
wsl/wsl1_setup.ps1 $Distro -r $Repos -s $Scope -o $OmpTheme -AddCertificate
# :update all existing WSL distros
wsl/wsl1_setup.ps1
#>
[CmdletBinding(DefaultParameterSetName = 'Update')]
param (
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Setup')]
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'GitHub')]
    [string]$Distro,

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateScript({ $_.ForEach({ $_ -in @('az', 'oh_my_posh', 'python', 'shell') }) -notcontains $false },
        ErrorMessage = 'Wrong scope provided. Valid values: az distrobox docker k8s_base k8s_ext python rice shell')]
    [string[]]$Scope,

    [Parameter(ParameterSetName = 'Update')]
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [ValidateNotNullOrEmpty()]
    [string]$OmpTheme,

    [Parameter(Mandatory, ParameterSetName = 'GitHub')]
    [ValidateScript({ $_.ForEach({ $_ -match '^[\w-]+/[\w-]+$' }) -notcontains $false },
        ErrorMessage = 'Repos should be provided in "Owner/RepoName" format.')]
    [string[]]$Repos,

    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'GitHub')]
    [switch]$AddCertificate
)

begin {
    $ErrorActionPreference = 'Stop'
    # check if the script is running on Windows
    if (-not $IsWindows) {
        Write-Warning 'Run the script on Windows!'
        exit 0
    }
    # check if repository is up to date
    git fetch
    $remote = "$(git remote)/$(git branch --show-current)"
    if ((git rev-parse HEAD) -ne (git rev-parse $remote)) {
        Write-Warning "Current branch is behind remote, performing hard reset.`n`t Run the script again!`n"
        git reset --hard $remote
        exit 0
    }

    # *get list of distros
    $lxss = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss `
    | ForEach-Object { $_ | Get-ItemProperty } `
    | Where-Object { $_.DistributionName -notmatch '^docker-desktop' -and $_.Flags -lt 8 } `
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

    # set location to workspace folder
    Push-Location "$PSScriptRoot/.."
}

process {
    foreach ($lx in $lxss) {
        $Distro = $lx.DistributionName
        # *perform distro checks
        $cmd = [string]::Join('',
            '[ -f /usr/bin/pwsh ] && shell="true" || shell="false";',
            '[ -f /usr/bin/oh-my-posh ] && omp="true" || omp="false";',
            '[ -d ~/.local/share/powershell/Modules/Az ] && az="true" || az="false";',
            '[ -d "$HOME/miniconda3" ] && python="true" || python="false";',
            'printf "{\"user\":\"$(id -un)\",\"shell\":$shell,',
            '\"az\":$az,\"omp\":$omp,\"python\":$python}"'
        )
        # check existing packages
        $chk = wsl.exe -d $Distro --exec sh -c $cmd | ConvertFrom-Json -AsHashtable
        # instantiate scope generic sorted set
        $scopes = [System.Collections.Generic.SortedSet[string]]::new()
        $Scope.ForEach({ $scopes.Add($_) | Out-Null })
        # *determine scope if not provided
        if ($scopes.Count -eq 0) {
            switch ($chk) {
                { $_.python } { $scopes.Add('python') | Out-Null }
                { $_.shell } { $scopes.Add('shell') | Out-Null }
                { $_.az } { $scopes.Add('az') | Out-Null }
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
            shell {
                Write-Host 'installing shell packages...' -ForegroundColor Cyan
                $rel_pwsh = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_pwsh.sh $Script:rel_pwsh && $($chk.shell = $true)
                $rel_eza = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_eza.sh $Script:rel_eza
                $rel_bat = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_bat.sh $Script:rel_bat
                $rel_rg = wsl.exe --distribution $Distro --user root --exec .assets/provision/install_ripgrep.sh $Script:rel_rg
                # *setup profiles
                Write-Host 'setting up profile for all users...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.ps1 -UserName $chk.user
                wsl.exe --distribution $Distro --user root --exec .assets/provision/setup_profile_allusers.sh $chk.user
                Write-Host 'setting up profile for current user...' -ForegroundColor Cyan
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.ps1
                if ('az' -in $scopes) {
                    $cmd = [string]::Join("`n",
                        'if (-not (Get-Module -ListAvailable Az))',
                        '{ Write-Host "installing Az..."; Install-PSResource Az }',
                        'if (-not (Get-Module -ListAvailable Az.ResourceGraph))',
                        '{ Write-Host "installing Az.ResourceGraph..."; Install-PSResource Az.ResourceGraph }'
                    )
                    wsl.exe --distribution $Distro -- pwsh -nop -c $cmd
                }
                wsl.exe --distribution $Distro --exec .assets/provision/setup_profile_user.sh
                continue
            }
        }
        # *install PowerShell modules from ps-modules repository
        if ($chk.shell) {
            # ps-modules repo is being cloned/refreshed on adding certificates
            if (-not $AddCertificate) {
                if (.assets/tools/gh_repo_clone.ps1 -OrgRepo 'szymonos/ps-modules') {
                    Write-Verbose 'ps-modules repository cloned successfully.'
                } else {
                    Write-Error 'Cloning ps-modules repository failed.'
                }
            }
            Write-Host 'installing ps-modules...' -ForegroundColor Cyan
            Write-Host "`e[3mAllUsers`e[23m    : do-common" -ForegroundColor DarkGreen
            wsl.exe --distribution $Distro --user root --exec ../ps-modules/module_manage.ps1 'do-common' -CleanUp

            # instantiate psmodules generic lists
            $modules = [System.Collections.Generic.SortedSet[String]]::new([string[]]@('aliases-git', 'do-linux'))
            # determine modules to install
            if ('az' -in $scopes) {
                $modules.Add('do-az') | Out-Null
                Write-Verbose "Added `e[3mdo-az`e[23m to be installed from ps-modules."
            }
            Write-Host "`e[3mCurrentUser`e[23m : $modules" -ForegroundColor DarkGreen
            $cmd = "@($($modules | Join-String -SingleQuote -Separator ',')) | ../ps-modules/module_manage.ps1 -CleanUp"
            wsl.exe --distribution $Distro --exec pwsh -nop -c $cmd
        }
    }

    if ($PsCmdlet.ParameterSetName -eq 'GitHub') {
        # *install GitHub CLI
        wsl.exe --distribution $Distro --user root --exec .assets/provision/install_gh.sh

        # *setup git config
        $builder = [System.Text.StringBuilder]::new()
        # set up git author identity
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
        # setup eol/crlf settings
        $builder.AppendLine("git config --global user.name '$user'") | Out-Null
        $builder.AppendLine("git config --global user.email '$email'") | Out-Null
        $builder.AppendLine('git config --global core.eol lf') | Out-Null
        $builder.AppendLine('git config --global core.autocrlf input') | Out-Null
        $builder.AppendLine('git config --global push.autoSetupRemote true') | Out-Null
        wsl.exe --distribution $Distro --exec bash -c $builder.ToString().Trim()

        # *check ssh keys and create if necessary
        if (-not (Test-Path "$HOME/.ssh/id_*")) {
            ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -q -N ''
            $idPub = Get-ChildItem "$HOME/.ssh/id_ed25519.pub" | Get-Content
            if ($idPub) {
                $msg = [string]::Join("`n",
                    "`e[97mUse the following values to add new SSH Key on https://github.com/settings/ssh/new.",
                    "`n`e[1;96mTitle`e[0m`n$($idPub.Split()[-1])",
                    "`n`e[1;96mKey type`e[30m`n<Authentication Key>",
                    "`n`e[1;96mKey`e[0m`n$idPub",
                    "`npress any key to continue..."
                )
                Write-Host $msg
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
