#!/usr/bin/pwsh -nop
<#
.SYNOPSIS
Setting up PowerShell for the all users.
.EXAMPLE
sudo .assets/provision/setup_profile_allusers.ps1 -UserName $(id -un)
#>
param (
    [Parameter(Position = 0)]
    [string]$UserName
)

begin {
    $ErrorActionPreference = 'SilentlyContinue'
    $WarningPreference = 'Ignore'

    # check if script is executed as root
    if ((id -u) -ne 0) {
        Write-Error 'Run the script as root.'
    }

    # check if specified user exists
    $user = $UserName ? $UserName : $(id -un 1000 2>$null)
    if ($user) {
        $me = sudo -u $user id -un 2>$null || ''
        if ($me -ne $user) {
            Write-Error "User does not exist ($user)."
        }
    } else {
        Write-Error 'User ID 1000 not found.'
    }
    # calculate path variables
    $CFG_PATH = sudo -u $user sh -c 'echo $HOME/tmp/config/pwsh_cfg'
    $SCRIPTS_PATH = '/usr/local/share/powershell/Scripts'

    # copy config files for WSL setup
    if (Test-Path .assets/config/pwsh_cfg -PathType Container) {
        if (-not (Test-Path $CFG_PATH)) {
            sudo -u $user mkdir -p $CFG_PATH
        }
        Copy-Item .assets/config/pwsh_cfg/* $CFG_PATH -Force
    }
}

process {
    # *modify exa alias
    if (Test-Path $CFG_PATH/_aliases_linux.ps1) {
        $exa_git = exa --version | Select-String '+git' -SimpleMatch -Quiet
        $exa_nerd = Select-String '' -Path /usr/local/share/oh-my-posh/theme.omp.json -SimpleMatch -Quiet
        $exa_param = ($exa_git ? '--git ' : '') + ($exa_nerd ? '--icons ' : '')
        $content = [IO.File]::ReadAllLines("$CFG_PATH/_aliases_linux.ps1").Replace('exa -g ', "exa -g $exa_param")
        [IO.File]::WriteAllLines("$CFG_PATH/_aliases_linux.ps1", $content)
    }

    # *Copy global profiles
    if (Test-Path $CFG_PATH -PathType Container) {
        if (-not (Test-Path $SCRIPTS_PATH)) {
            New-Item $SCRIPTS_PATH -ItemType Directory | Out-Null
        }
        # TODO to be removed, cleanup legacy aliases
        Get-ChildItem -Path $SCRIPTS_PATH -Filter '*_aliases_*.ps1' -File | Remove-Item -Force
        # PowerShell profile
        install -m 0644 $CFG_PATH/profile.ps1 $PROFILE.AllUsersAllHosts
        # PowerShell functions
        if (-not (Test-Path $SCRIPTS_PATH)) {
            New-Item $SCRIPTS_PATH -ItemType Directory | Out-Null
        }
        install -m 0644 $CFG_PATH/_aliases_common.ps1 $SCRIPTS_PATH
        install -m 0644 $CFG_PATH/_aliases_linux.ps1 $SCRIPTS_PATH
        # clean config folder
        Remove-Item $CFG_PATH -Recurse -Force
    }

    # *PowerShell profile
    $psGetVer = (Find-Module PowerShellGet -AllowPrerelease).Version
    for ($i = 0; $psGetVer -and ($psGetVer -notin (Get-InstalledModule -Name PowerShellGet -AllVersions).Version) -and $i -lt 10; $i++) {
        Write-Host 'installing PowerShellGet...'
        Install-Module PowerShellGet -AllowPrerelease -Scope AllUsers -Force -SkipPublisherCheck
    }
    # install/update modules
    if (Get-InstalledModule -Name PowerShellGet) {
        if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) {
            Write-Host 'setting PSGallery trusted...'
            Set-PSResourceRepository -Name PSGallery -Trusted
        }
        for ($i = 0; (Test-Path /usr/bin/git) -and -not (Get-Module posh-git -ListAvailable) -and $i -lt 10; $i++) {
            Write-Host 'installing posh-git...'
            Install-PSResource -Name posh-git -Scope AllUsers
        }
        # update existing modules
        if (Test-Path .assets/provision/update_psresources.ps1 -PathType Leaf) {
            .assets/provision/update_psresources.ps1
        }
    }
}
