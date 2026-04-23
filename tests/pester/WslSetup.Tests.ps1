#Requires -Modules Pester
# Integration tests for wsl/wsl_setup.ps1 orchestration logic.
# Mocks wsl.exe and Windows-only functions to verify the correct sequence
# of provisioning calls for each scope and mode (legacy vs Nix).

BeforeAll {
    $Script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path

    # allow the script to run on Linux (bypasses $IsLinux guard)
    $env:WSL_SETUP_TESTING = '1'
    # provide Windows-like env vars for SSH path computation (line 448)
    $env:HOMEDRIVE = 'C:'
    $env:HOMEPATH = '\Users\testuser'

    # import modules so the real functions exist (we will mock them)
    Import-Module "$Script:RepoRoot/modules/InstallUtils" -Force
    Import-Module "$Script:RepoRoot/modules/SetupUtils" -Force

    # helper: build a check_distro JSON response
    function New-CheckDistro {
        param(
            [string]$User = 'testuser',
            [int]$Uid = 1000,
            [hashtable]$Flags = @{}
        )
        $defaults = @{
            user = $User; uid = $Uid; def_uid = $Uid
            az = $false; bun = $false; conda = $false; gcloud = $false
            git_user = $true; git_email = $true; gtkd = $false
            k8s_base = $false; k8s_dev = $false; k8s_ext = $false
            nix = $false; oh_my_posh = $false
            python = $false; pwsh = $false; shell = $false
            ssh_key = $true; systemd = $true; terraform = $false
            wsl_boot = $true; wslg = $false; zsh = $false
        }
        foreach ($key in $Flags.Keys) { $defaults[$key] = $Flags[$key] }
        $defaults | ConvertTo-Json -Compress
    }

    # collector for wsl.exe invocations
    $global:WslTestCalls = [System.Collections.Generic.List[string[]]]::new()

    # define wsl.exe stub so Pester can mock it on Linux (where it does not exist)
    if (-not (Get-Command 'wsl.exe' -ErrorAction SilentlyContinue)) {
        function global:wsl.exe { }
    }

    # default check_distro response (overridden per test)
    $global:WslTestCheckDistroJson = New-CheckDistro
    # default ssh setup response
    $global:WslTestSshSetupJson = '{"sshKey":"exists"}'
}

AfterAll {
    $env:WSL_SETUP_TESTING = $null
    $env:HOMEDRIVE = $null
    $env:HOMEPATH = $null
    Remove-Variable -Name WslTestCalls, WslTestCheckDistroJson, WslTestSshSetupJson -Scope Global -ErrorAction SilentlyContinue
}

Describe 'wsl_setup.ps1 orchestration' {
    BeforeEach {
        $global:WslTestCalls.Clear()

        # mock wsl.exe - record calls and return canned responses
        Mock wsl.exe {
            $global:WslTestCalls.Add([string[]]$args)
            $argStr = $args -join ' '
            # return appropriate responses based on the script being called
            if ($argStr -match 'check_distro\.sh') {
                return $global:WslTestCheckDistroJson
            }
            if ($argStr -match 'check_dns\.sh') {
                return 'true'
            }
            if ($argStr -match 'check_ssl\.sh') {
                return 'true'
            }
            if ($argStr -match 'setup_gh_https\.sh') {
                return 'github.com'
            }
            if ($argStr -match 'setup_gh_ssh\.sh') {
                return $global:WslTestSshSetupJson
            }
            if ($argStr -match 'id -un') {
                return 'testuser'
            }
            if ($argStr -match 'command -v pwsh') {
                return 'true'
            }
            # provision/install scripts: return a fake version string
            if ($argStr -match 'install_\w+\.sh') {
                return 'v1.0.0'
            }
            return ''
        }

        # mock Windows-only functions
        Mock Get-WslDistro {
            [PSCustomObject]@{ Default = $true; Name = 'Ubuntu'; State = 'Running'; Version = 2 }
        }
        Mock Get-WslDistro -ParameterFilter { $FromRegistry } {
            [PSCustomObject]@{
                Name = 'Ubuntu'; DefaultUid = 1000; Version = 2
                Flags = 15; BasePath = 'C:\fake'; Default = $true
            }
        }
        Mock Set-WslConf {}
        Mock Update-GitRepository { return 1 }
        Mock Invoke-GhRepoClone { return 2 }
        Mock Test-IsAdmin { return $false }

        # mock filesystem operations that would create side-effect dirs
        Mock New-Item {}
        Mock Remove-Item {}

        # prevent the script from re-importing modules (which overwrites our mocks)
        Mock Import-Module {}
    }

    BeforeAll {
        # helper: extract the script path from recorded wsl.exe calls
        function Get-WslScripts {
            $global:WslTestCalls | ForEach-Object {
                $joined = $_ -join ' '
                if ($joined -match '(?:--exec\s+)(\S+\.(?:sh|ps1))') {
                    $Matches[1]
                }
            } | Where-Object { $_ }
        }
    }

    Context 'Legacy mode with shell scope' {
        It 'calls correct provision scripts in order' {
            $global:WslTestCheckDistroJson = New-CheckDistro

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('shell') -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            # base setup
            $scripts | Should -Contain '.assets/fix/fix_no_file.sh'
            $scripts | Should -Contain '.assets/fix/fix_secure_path.sh'
            $scripts | Should -Contain '.assets/provision/upgrade_system.sh'
            $scripts | Should -Contain '.assets/provision/install_base.sh'
            # gh setup
            $scripts | Should -Contain '.assets/provision/install_gh.sh'
            $scripts | Should -Contain '.assets/setup/setup_gh_https.sh'
            # shell scope scripts
            $scripts | Should -Contain '.assets/provision/install_fzf.sh'
            $scripts | Should -Contain '.assets/provision/install_eza.sh'
            $scripts | Should -Contain '.assets/provision/install_bat.sh'
            $scripts | Should -Contain '.assets/provision/install_ripgrep.sh'
            $scripts | Should -Contain '.assets/provision/install_yq.sh'
            $scripts | Should -Contain '.assets/setup/setup_profile_allusers.sh'
            $scripts | Should -Contain '.assets/setup/setup_profile_user.sh'
            $scripts | Should -Contain '.assets/provision/install_copilot.sh'
            # should NOT contain nix setup
            $scripts | Should -Not -Contain 'nix/setup.sh'
        }
    }

    Context 'Legacy mode with python and rice scopes' {
        It 'installs python and rice tools' {
            $global:WslTestCheckDistroJson = New-CheckDistro

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('python', 'rice') -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            # python
            $scripts | Should -Contain '.assets/setup/setup_python.sh'
            $scripts | Should -Contain '.assets/provision/install_uv.sh'
            $scripts | Should -Contain '.assets/provision/install_prek.sh'
            # rice
            $scripts | Should -Contain '.assets/provision/install_btop.sh'
            $scripts | Should -Contain '.assets/provision/install_cmatrix.sh'
            $scripts | Should -Contain '.assets/provision/install_cowsay.sh'
            $scripts | Should -Contain '.assets/provision/install_fastfetch.sh'
        }
    }

    Context 'Legacy mode with docker scope (systemd already enabled)' {
        It 'installs docker without systemd restart' {
            # systemd = $true so we skip wsl_systemd.ps1 call (not mockable on Linux)
            $global:WslTestCheckDistroJson = New-CheckDistro -Flags @{ systemd = $true }

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('docker') -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            $scripts | Should -Contain '.assets/provision/install_docker.sh'
            # should NOT have called wsl.exe --shutdown (systemd already on)
            $shutdownCalls = $global:WslTestCalls | Where-Object { ($_ -join ' ') -match '--shutdown' }
            $shutdownCalls | Should -BeNullOrEmpty
        }
    }

    Context 'Legacy mode with az scope resolves python dependency' {
        It 'includes python scope scripts when az is specified' {
            $global:WslTestCheckDistroJson = New-CheckDistro

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('az') -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            # az
            $scripts | Should -Contain '.assets/provision/install_azurecli_uv.sh'
            $scripts | Should -Contain '.assets/provision/install_azcopy.sh'
            # python (dependency of az)
            $scripts | Should -Contain '.assets/setup/setup_python.sh'
            $scripts | Should -Contain '.assets/provision/install_uv.sh'
        }
    }

    Context 'Legacy mode detects existing scopes from check_distro' {
        It 'adds scopes detected from distro check' {
            $global:WslTestCheckDistroJson = New-CheckDistro -Flags @{ python = $true; shell = $true }

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('rice') -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            # rice (explicitly requested)
            $scripts | Should -Contain '.assets/provision/install_btop.sh'
            # shell (detected from distro)
            $scripts | Should -Contain '.assets/provision/install_fzf.sh'
            # python (detected from distro)
            $scripts | Should -Contain '.assets/setup/setup_python.sh'
        }
    }

    Context 'Nix mode with shell and python scopes' {
        It 'calls nix/setup.sh instead of individual install scripts' {
            $global:WslTestCheckDistroJson = New-CheckDistro

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('shell', 'python') -Nix -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            # should use nix path
            $scripts | Should -Contain '.assets/provision/install_base_nix.sh'
            $scripts | Should -Contain '.assets/provision/install_nix.sh'
            $scripts | Should -Contain 'nix/setup.sh'
            # should NOT call individual shell/python install scripts
            $scripts | Should -Not -Contain '.assets/provision/install_fzf.sh'
            $scripts | Should -Not -Contain '.assets/provision/install_uv.sh'
            $scripts | Should -Not -Contain '.assets/setup/setup_python.sh'
        }

        It 'passes correct flags to nix/setup.sh' {
            $global:WslTestCheckDistroJson = New-CheckDistro

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('shell', 'python') -Nix -SkipRepoUpdate 6>$null

            $nixCall = $global:WslTestCalls | Where-Object { ($_ -join ' ') -match 'nix/setup\.sh' } | Select-Object -First 1
            $nixArgs = $nixCall -join ' '
            $nixArgs | Should -Match '--shell'
            $nixArgs | Should -Match '--python'
            $nixArgs | Should -Match '--unattended'
        }
    }

    Context 'Nix mode with docker falls back to traditional install' {
        It 'installs docker traditionally even in Nix mode' {
            $global:WslTestCheckDistroJson = New-CheckDistro -Flags @{ systemd = $true }

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('shell', 'docker') -Nix -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            $scripts | Should -Contain 'nix/setup.sh'
            $scripts | Should -Contain '.assets/provision/install_docker.sh'
        }
    }

    Context 'Nix mode auto-detected from distro' {
        It 'uses Nix path when distro has nix installed' {
            $global:WslTestCheckDistroJson = New-CheckDistro -Flags @{ nix = $true }

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('shell') -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            $scripts | Should -Contain '.assets/provision/install_base_nix.sh'
            $scripts | Should -Contain 'nix/setup.sh'
            $scripts | Should -Not -Contain '.assets/provision/install_fzf.sh'
        }
    }

    Context 'Nix mode with OmpTheme' {
        It 'passes --omp-theme to nix/setup.sh' {
            $global:WslTestCheckDistroJson = New-CheckDistro

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('shell') -Nix -OmpTheme 'nerd' -SkipRepoUpdate 6>$null

            $nixCall = $global:WslTestCalls | Where-Object { ($_ -join ' ') -match 'nix/setup\.sh' } | Select-Object -First 1
            $nixArgs = $nixCall -join ' '
            $nixArgs | Should -Match '--omp-theme'
            $nixArgs | Should -Match 'nerd'
        }
    }

    Context 'WSL1 distro removes incompatible scopes' {
        BeforeEach {
            # initial Get-WslDistro returns Version=2 to skip the interactive WSL1 prompt
            # but -FromRegistry returns Version=1 which is used for scope filtering in process{}
            Mock Get-WslDistro {
                [PSCustomObject]@{ Default = $true; Name = 'Ubuntu'; State = 'Running'; Version = 2 }
            }
            Mock Get-WslDistro -ParameterFilter { $FromRegistry } {
                [PSCustomObject]@{
                    Name = 'Ubuntu'; DefaultUid = 1000; Version = 1
                    Flags = 15; BasePath = 'C:\fake'; Default = $true
                }
            }
        }

        It 'does not install docker or k8s_ext on WSL1' {
            $global:WslTestCheckDistroJson = New-CheckDistro

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('docker', 'shell') -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            $scripts | Should -Not -Contain '.assets/provision/install_docker.sh'
            # shell should still be installed
            $scripts | Should -Contain '.assets/provision/install_fzf.sh'
        }
    }

    Context 'DNS failure halts execution' {
        It 'exits with non-zero when DNS check fails' {
            # run in subprocess since `exit 1` terminates the process
            $result = pwsh -NoProfile -Command @"
                `$env:WSL_SETUP_TESTING = '1'
                `$env:HOMEDRIVE = 'C:'
                `$env:HOMEPATH = '\Users\testuser'
                Set-Location '$Script:RepoRoot'
                Import-Module './modules/InstallUtils' -Force
                Import-Module './modules/SetupUtils' -Force
                function wsl.exe {
                    `$argStr = `$args -join ' '
                    if (`$argStr -match 'check_distro\.sh') { return '$(New-CheckDistro)' }
                    if (`$argStr -match 'check_dns\.sh') { return 'false' }
                    if (`$argStr -match 'check_ssl\.sh') { return 'true' }
                    if (`$argStr -match 'setup_gh_https') { return 'github.com' }
                    if (`$argStr -match 'id -un') { return 'testuser' }
                    return ''
                }
                function Get-WslDistro {
                    [CmdletBinding()]param([switch]`$FromRegistry, [switch]`$Online)
                    if (`$FromRegistry) {
                        [PSCustomObject]@{ Name='Ubuntu'; DefaultUid=1000; Version=2; Flags=15; BasePath='C:\fake'; Default=`$true }
                    } else {
                        [PSCustomObject]@{ Default=`$true; Name='Ubuntu'; State='Running'; Version=2 }
                    }
                }
                function Set-WslConf {}
                function Update-GitRepository { return 1 }
                function Invoke-GhRepoClone { return 2 }
                function Test-IsAdmin { return `$false }
                & './wsl/wsl_setup.ps1' -Distro 'Ubuntu' -Scope @('shell') -SkipRepoUpdate *>`$null
"@
            $LASTEXITCODE | Should -Not -Be 0
        }
    }

    Context 'Legacy mode with k8s scopes' {
        It 'installs kubernetes base and dev packages' {
            $global:WslTestCheckDistroJson = New-CheckDistro

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('k8s_dev') -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            # k8s_base (dependency of k8s_dev)
            $scripts | Should -Contain '.assets/provision/install_kubectl.sh'
            $scripts | Should -Contain '.assets/provision/install_kubelogin.sh'
            $scripts | Should -Contain '.assets/provision/install_k9s.sh'
            $scripts | Should -Contain '.assets/provision/install_kubecolor.sh'
            $scripts | Should -Contain '.assets/provision/install_kubectx.sh'
            # k8s_dev
            $scripts | Should -Contain '.assets/provision/install_argorolloutscli.sh'
            $scripts | Should -Contain '.assets/provision/install_helm.sh'
            $scripts | Should -Contain '.assets/provision/install_flux.sh'
            $scripts | Should -Contain '.assets/provision/install_kustomize.sh'
            $scripts | Should -Contain '.assets/provision/install_trivy.sh'
        }
    }

    Context 'Legacy mode with terraform scope' {
        It 'installs terraform tools' {
            $global:WslTestCheckDistroJson = New-CheckDistro

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('terraform') -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            $scripts | Should -Contain '.assets/provision/install_terraform.sh'
            $scripts | Should -Contain '.assets/provision/install_terrascan.sh'
            $scripts | Should -Contain '.assets/provision/install_tflint.sh'
            $scripts | Should -Contain '.assets/provision/install_tfswitch.sh'
        }
    }

    Context 'Legacy mode with oh_my_posh via OmpTheme' {
        It 'installs oh-my-posh when OmpTheme is specified' {
            $global:WslTestCheckDistroJson = New-CheckDistro

            & "$Script:RepoRoot/wsl/wsl_setup.ps1" -Distro 'Ubuntu' -Scope @('shell') -OmpTheme 'base' -SkipRepoUpdate 6>$null

            $scripts = Get-WslScripts
            $scripts | Should -Contain '.assets/provision/install_omp.sh'
            $scripts | Should -Contain '.assets/setup/setup_omp.sh'
        }
    }
}
