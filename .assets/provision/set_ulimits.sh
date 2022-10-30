#!/bin/bash
: '
sudo .assets/provision/set_ulimits.sh
'

cat << EOF > /etc/security/limits.d/k8slimits.conf
* soft nofile 120000
* hard nofile 524288
root soft nofile 120000
root hard nofile 524288
EOF
sed -i "s/^.*DefaultLimitNOFILE.*$/DefaultLimitNOFILE=120000\:524288/" /etc/systemd/user.conf
sed -i "s/^.*DefaultLimitNOFILE.*$/DefaultLimitNOFILE=120000\:524288/" /etc/systemd/system.conf
