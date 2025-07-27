#!/usr/bin/env bash
: '
.assets/scripts/enforce_ssh_git_protocol.sh
'

git config --global url.git@github.com:.insteadOf https://github.com/
git config --global url.git@gist.github.com:.insteadOf https://gist.github.com/
