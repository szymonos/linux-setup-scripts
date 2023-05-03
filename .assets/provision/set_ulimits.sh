#!/usr/bin/env bash
: '
sudo .assets/provision/set_ulimits.sh
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

cat << EOF > /etc/security/limits.d/k8slimits.conf
* soft nofile 120000
* hard nofile 524288
root soft nofile 120000
root hard nofile 524288
EOF
sed -i "s/^.*DefaultLimitNOFILE.*$/DefaultLimitNOFILE=120000\:524288/" /etc/systemd/user.conf
sed -i "s/^.*DefaultLimitNOFILE.*$/DefaultLimitNOFILE=120000\:524288/" /etc/systemd/system.conf
