# Linux Setup Scripts

This is a scripts repository for setting up Linux OS. Scripts can be used for setting up bare-metal Linux OS, provisioning Linux VMs using Vagrant or setting up WSL distros.  

Provisioning scripts are most of the time distro agnostic and work with the commonly used distros based on Fedora/RHEL, Debian/Ubuntu, Arch, OpenSUSE, Alpine with an emphasis on Fedora, Debian and Ubuntu which are the most extensively used distros by me.

## Setup scenarios

Depending on the use case you can use scripts in the repository for different scenarios for setting up your Linux.

### Windows Subsystem for Linux (WSL)

To set up the distro from scratch, run the [wsl/wsl_setup.ps1](wsl/wsl_setup.ps1) script, following the examples included in the script.  
For more detailed instructions about setting up the WSL read the [WSL Setup Guideline](docs/wsl_setup.md).  
To learn about other WSL management scripts, please read the [Other WSL scripts](docs/wsl_scripts.md) page.

### VM provisioning with Vagrant

Set location to one of the Vagrantfiles depending on the used provider and target distro and run the command

``` sh
PS C:\..\vagrant\hyperv\fedora> vagrant up
```

For more detailed instructions about provisioning VMs using Vagrant read the [Vagrant Provisioning Guideline](docs/vagrant.md).

### Already provisioned Linux OS

Run the [.assets/scripts/linux_setup.sh](.assets/scripts/linux_setup.sh) script following the examples included in the script.  
The script can be used to set up an already provisioned Linux OS, it may be a bare-metal OS, VM or WSL.

## Repository directories structure

``` sh
.
├── .assets         # all helper scripts and assets used for deployments
│   ├── config        # shell configuration assets
│   │   ├── bash_cfg    # bash aliases
│   │   ├── omp_cfg     # oh-my-posh themes
│   │   └── pwsh_cfg    # PowerShell profile and aliases functions
│   ├── config        # bash and PowerShell profiles along the themes, aliases, etc...
│   ├── docker        # dockerfiles
│   ├── playbooks     # ansible playbooks
│   ├── provision     # scripts used during vm provisioning for apps install, os setup, etc...
│   ├── scripts       # other scripts not used for setting up VMs or WSLs.
│   ├── tools         # tools scripts not related to Linux provisioning
│   └── trigger       # scripts used externally to setup the VM in hypervisor, etc...
├── .github         # GitHub Actions
├── docs            # repository documentation
├── vagrant         # Vagrant configuration files
│   ├── hyperv        # Hyper-V provider VM deployments
│   │   └── ...
│   ├── libvirt       # Libvirt provider VM deployments
│   │   └── ...
│   └── virtualbox    # VirtualBox provider VM deployments
│   │   └── ...
└── wsl             # WSL configuration scripts
```
