#!/usr/bin/env bash
: '
.assets/provision/check_dns.sh
'
getent hosts github.com >/dev/null 2>&1 && echo true || echo false
