# Other WSL scripts

There are other WSL managements scripts, some of them used by the wsl_setup.ps1 script that some might find useful.  
All scripts should be executed on Windows.

## [wsl_certs_add](../wsl/wsl_certs_add.ps1)

Script intercepts root and intermediate certificates in chain and installs them in the specified WSL distro.  
You can also provide custom URL to intercept certificates in chain against it.

``` powershell
# install certificates in chain, intercepted when sending a request to www.google.com.
wsl/wsl_certs_add.ps1 'Ubuntu'
# install certificates in chain, intercepted when sending a request to custom URL.
wsl/wsl_certs_add.ps1 'Ubuntu' -Uri 'www.powershellgallery.com'
```

## [wsl_distro_move](../wsl/wsl_distro_move.ps1)

Script allows moving WSL distro from the default location e.g. to another disk. If you specify `-NewName` parameter, it will also rename the  distribution - it allows to conveniently *multiply* existing distros.  
Imagine, that you have Ubuntu distro installed, but you want to have another, fresh one. You can use the script to move distro to existing location with the new name, and then you can type `ubuntu.exe` in therminal and it will setup new, fresh Ubuntu distro.

``` powershell
# Copy existing WSL distro to new location
wsl/wsl_distro_move.ps1 'Ubuntu' -Destination 'D:\WSL'
# Copy existing WSL distro to new location and rename it
wsl/wsl_distro_move.ps1 'Ubuntu' -Destination 'D:\WSL' -NewName 'Ubuntu2'
```

## [wsl_files_copy](../wsl/wsl_files_copy.ps1)

Copy files between WSL distributions. It mounts source distro and copy files from the mount to destination distro.
It is much faster than copying files in the Windows Explorer and preserves Linux files attributes and links.

``` powershell
# Copy files as default user between distros
wsl/wsl_files_copy.ps1 -Source 'Ubuntu:~/source/repos' -Destination 'Debian'
# Copy files as root between distros
wsl/wsl_files_copy.ps1 -Source 'Ubuntu:~/source/repos' -Destination 'Debian' -Root
```

## [wsl_flags_manage](../wsl/wsl_flags_manage.ps1)

Allows modify WSL distro flags for interop, appending Windows paths and mounting Windows drives inside WSL.

``` powershell
# Disable WSL_DISTRIBUTION_FLAGS_APPEND_NT_PATH flag inside WSL distro. Speeds up finding applications in PATH.
wsl/wsl_flags_manage.ps1 'Ubuntu' -AppendWindowsPath $false
```

## [wsl_network_fix](../wsl/wsl_network_fix.ps1)

Copies existing Windows network interface properties to `resolv.conf` inside WSL distro, and some other tricks, to fix network connectivity inside WSL. Useful with some VPN solutions which messes up WSL networking.

``` powershell
# copy Windows network interface properties to WSL
wsl/wsl_network_fix.ps1 'Ubuntu'
# copy Windows network interface properties to WSL and disables WSL swap
wsl/wsl_network_fix.ps1 'Ubuntu' -DisableSwap
# copy Windows network interface properties to WSL, disables WSL swap and shuts down distro
wsl/wsl_network_fix.ps1 'Ubuntu' -Shutdown -DisableSwap
```

## [wsl_restart](../wsl/wsl_restart.ps1)

Restarts WSL. Useful when WSL distro hangs.

``` powershell
wsl/wsl_restart.ps1
```

## [wsl_systemd](../wsl/wsl_systemd.ps1)

Enables/disables systemd in the specified distro.

``` powershell
# enable systemd
wsl/wsl_systemd.ps1 'Ubuntu' -Systemd 'true'
# disable systemd
wsl/wsl_systemd.ps1 'Ubuntu' -Systemd 'false'
```

## [wsl_win_path](../wsl/wsl_win_path.ps1)

> OBSOLETE script, the functionality has been replaced with the `wsl_flags_manage.ps1` script.
