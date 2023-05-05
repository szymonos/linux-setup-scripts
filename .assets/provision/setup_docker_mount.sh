#!/usr/bin/env bash
: '
sudo .assets\provision\setup_docker_mount.sh
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

disk=${disk:-sdb}
mount=${mount:-/var/lib/docker}
fstype=${fstype:-ext4}

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
    # echo $1 $2 // Optional to see the parameter:value result
  fi
  shift
done
part="${disk}1"

if [ -f /asdf ]; then
  echo 'type=83' | sfdisk "/dev/${disk}"
  mkfs -t $fstype "/dev/${part}"
  mkdir -p $mount
  cp /etc/fstab /etc/fstab.bck
  sed -e "/\/dev\/$part/d" /etc/fstab.bck | sed -e "\$a/dev/$part $mount $fstype defaults 0 0" >/etc/fstab
  mount $mount
fi
