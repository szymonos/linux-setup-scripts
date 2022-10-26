#!/bin/bash
: '
.assets/trigger/set_inotify.sh
'

sysctl -w fs.inotify.max_user_instances=1280 >/etc/sysctl.d/99-custom-inotify.conf
sysctl -w fs.inotify.max_user_watches=655360 >>/etc/sysctl.d/99-custom-inotify.conf
sysctl -p /etc/sysctl.d/99-custom-inotify.conf
