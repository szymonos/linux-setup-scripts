<#
.LINK
https://app.vagrantup.com/generic/boxes/fedora36
https://superuser.com/questions/1354658/hyperv-static-ip-with-vagrant
https://github.com/Shinzu/vagrant-hyperv
https://github.com/ShaunLawrie/vagrant-hyperv-v2/pull/1
https://technology.amis.nl/tech/vagrant-and-hyper-v-dont-do-it/
https://github.com/HonkinWaffles/Public-Guides/blob/main/Vagrant+WSL2+Hyper-V.md
https://github.com/secana/EnhancedSessionMode/blob/master/install_esm_fedora3x.sh
.EXAMPLE
.assets/scripts/vagrant.ps1
#>

# change vagrant.d location
[System.Environment]::GetEnvironmentVariable('VAGRANT_HOME')
[System.Environment]::SetEnvironmentVariable('VAGRANT_HOME', "$HOME\.vagrant.d", 'Machine')
$env:VAGRANT_HOME

# *Install vagrant-reload plugin
vagrant plugin install vagrant-reload
# fix self-signed certificate in certificate chain
.assets/scripts/vg_cacert_fix.ps1
# You can also point to the existing certificate file
$env:SSL_CERT_FILE = 'C:\path\to\self-signed.crt'

# initialize vagrant box
vagrant init generic/fedora37
vagrant init hashicorp/bionic64
# create virtual machine
vagrant up
vagrant up --provider=hyperv

# Change switch in all existing VMs
Get-VM | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName 'NatSwitch'

# *Install libvirt plugin on Fedora
# https://vagrant-libvirt.github.io/vagrant-libvirt/
sudo dnf install -y vagrant libvirt-devel
sudo dnf install -y @development-tools
# install plugins
vagrant plugin install pkg-config
vagrant plugin install vagrant-libvirt
# check vagrant plugins
vagrant plugin list

# isntall scp plugin
vagrant plugin install vagrant-scp
vagrant ssh-config
vagrant scp .vagrant/machines/centos/libvirt/private_key rhel:stream.key
vagrant scp .vagrant/machines/ubuntu/libvirt/private_key rhel:ubuntu.key
