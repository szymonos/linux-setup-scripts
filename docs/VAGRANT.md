# Vagrant Provisioning Guideline

Folder with Vagrant VM deployments using different hypervisor providers.
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

## Supported providers and distros

Hypervisor providers:

- Hyper-V
- Libvirt
- VirtualBox

Linux distributions (vary depending on the provider):

- Alpine
- Arch
- Debian
- Fedora
- OpenSUSE
- Ubuntu

## Prerequisites

To provision any box using provided Vagrantfiles you need to have:

- **Vagrant** application itself. On Windows, it can be installed using the command:  
  
  ``` powershell
  winget install --id Hashicorp.Vagrant
  ```

- **Hypervisor** for hosting virtual machines. On Windows, you can install it depending on the provider of choice using the command:
  - *Hyper-V*

    ``` powershell
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    ```

    > Hyper-V will offer better performance than VirtualBox as it is type 1 hypervisor and will offer best experience when using along with  the WSL.

  - *VirtualBox*

    ``` powershell
    winget install --id Oracle.VirtualBox
    ```

    > VirtualBox is Type 2 hypervisor and offers worse performance than Hyper-V, but is available cross platform and easier to use for desktop purposes.

  - *Libvirt* - can be installed only on Linux and the installation method depends on the used distro.
    > Libvirt is also Type 1 hypervisor and is insanely fast on Linux. Highly recommend it.

- **vagrant-reload** plugin. It can be installed after installing the Vagrant application, using the command:  

  ``` sh
  vagrant plugin install vagrant-reload
  ```

## SSH configuration

For convenience's sake, newly provisioned virtual machines are being added automatically to the SSH config and known_hosts file, so you don't need to use the `vagrant ssh` command which is much slower than the built-in `ssh` one, but also allows you to use the Remote SSH feature of the Visual Studio Code, for remote development. All the VMs should be instantly visible in the VSCode Remote SSH extension pane after provisioning.
