# Vagrant

Repository for vagrant VM deployments using different hypervisor providers.
The main idea for writing Vagrantfiles is to make them as generic as possible, by separating all the provisioning scripts and triggers into separate files, that may be called from any box provisioning, and keeping inside Vagrantfile, only the code, that is specific to the used provider and box combo.

Vagranfile consists of the following sections:

- **Variables declaration**
  - hypervisor provider
  - VM specification
  - ...
- **Scripts**
  - box specific packages installation
  - box specific network configuration
- **VM Provisioning**
  - common configuration, that can be used among all boxes
  - node specific configuration
  - node installation scripts
  - reload trigger for applying network changes /*optional for specific box/provider*/

## SSH configuration

For convenience's sake, newly provisioned virtual machines are being added automatically to the SSH config and known_hosts file, so you don't need to use the `vagrant ssh` command which is much slower than the built-in `ssh` one, but also allows you to use the Remote SSH feature of the Visual Studio Code, for remote development. All the VMs should be instantly visible in the VSCode Remote SSH extension pane after provisioning.

## Repository structure

``` sh
.
├── .assets         # All helper scripts and assets used for deployments
│   ├── config        # bash and PowerShell profiles along the themes, aliases, etc...
│   ├── playbooks     # ansible playbooks
│   ├── provision     # scripts used during vm provisioning for apps install, os setup, etc...
│   ├── scripts       # other scripts not used directly by vagrant
│   └── trigger       # scripts used externally to setup the VM in hypervisor, etc...
├── hyperv          # Hyper-V provider VM deployments
│   ├── ansible       # multiple VMs deployment for ansible testing
│   ├── FedoraHV      # Fedora VM with Gnome DE for kubernetes development
│   └── ...
├── libvirt         # libvirt provider VM deployments
│   ├── ansible       # multiple VMs deployment for ansible testing
│   ├── fedora        # Fedora VM with Gnome DE for kubernetes development
│   └── ...
└── virtualbox      # VirtualBox provider VM deployments
    ├── ansible       # multiple VMs deployment for ansible testing
    ├── FedoraVB      # Fedora VM with Gnome DE for kubernetes development
    └── ...
```

## Prerequisites

To provision any box using provided Vagrantfiles you need to have:

- **vagrant-reload** plugin. Can be installed using the command:\
  `vagrant plugin install vagrant-reload`
