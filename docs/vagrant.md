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

### Vagrant application

On Windows, it can be installed using the command:  

``` powershell
winget install --id Hashicorp.Vagrant
```

### Hypervisor

To provision virtual machines Hypervisor needs to be present oh the host machine.

#### Windows  
  
On Windows, you can install it depending on the provider of choice using the command:

- **Hyper-V**

  ``` powershell
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
  ```

  > Hyper-V will offer better performance than VirtualBox as it is type 1 hypervisor and will offer best experience when using along with  the WSL.

- **VirtualBox**

  ``` powershell
  winget install --id Oracle.VirtualBox
  ```

  > VirtualBox is Type 2 hypervisor and offers worse performance than Hyper-V, but is available cross platform and easier to use for desktop purposes.

#### Linux  

On Linux, hypervisor installation vary depending on distro. Personally I recommend the **Libvirt**, as it is also Type-1 hypervisor, has great Vagrant provider (which also has to be installed individually), and is insanely fast.

### `vagrant-reload` plugin

I use the `vagrant-reload` plugin to reliably set static IP on any distro/provider combination.
It can be installed after installing the Vagrant application, using the command:  

``` sh
vagrant plugin install vagrant-reload
```

> If you encounter the *"SSL verification error"* during plugin installation caused by missing `gems.hashicorp.com` certificates or mitm proxy, run the below script:

``` powershell
.assets/scripts/vg_cacert_fix.ps1
```

## SSH configuration

For convenience's sake, newly provisioned virtual machines are being added automatically to the SSH config and known_hosts file, so you don't need to use the `vagrant ssh` command which is much slower than the built-in `ssh` one, but also allows you to use the Remote SSH feature of the Visual Studio Code, for remote development. All the VMs should be instantly visible in the VSCode Remote SSH extension pane after provisioning.

## MITM Proxy

When using Vagrant in corporate environment you can face the issue with self-signed certificate in certificate chain error,
caused by the *"man in the middle"* proxy injected certificates.

To fix the issue during virtual machines provisioning, you need to install self-signed certificates from chain at the box provisioning start by using the following script:

```powershell
$Path = 'vagrant/<hypervisor_provider>/<distro_name>/Vagrantfile'
.assets/scripts/vg_certs_add.ps1 -p $Path
```
