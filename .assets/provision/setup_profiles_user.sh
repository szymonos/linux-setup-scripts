#!/bin/bash
: '
.assets/provision/setup_profiles_user.sh
'
# path varaibles
SH_PROFILE_PATH='/etc/profile.d'
OH_MY_POSH_PATH='/usr/local/share/oh-my-posh'

# *PowerShell profile
cat <<'EOF' | pwsh -nop -c -
$WarningPreference = 'Ignore';
if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) { Set-PSResourceRepository -Name PSGallery -Trusted };
if (-not $PSNativeCommandArgumentPassing) { Enable-ExperimentalFeature PSNativeCommandArgumentPassing };
if (-not $PSStyle) { Enable-ExperimentalFeature PSAnsiRenderingFileInfo };
if (Test-Path /usr/bin/kubectl) { (/usr/bin/kubectl completion powershell).Replace("'kubectl'", "'k'") >$PROFILE }
EOF

# *bash profile
# add common bash aliases
grep -qw 'd/bash_aliases' ~/.bashrc || cat <<EOF >>~/.bashrc
# common aliases
if [ -f $SH_PROFILE_PATH/bash_aliases ]; then
  source $SH_PROFILE_PATH/bash_aliases
fi
EOF
# add git aliases
if ! grep -qw 'd/bash_aliases_git' ~/.bashrc && type git &>/dev/null; then
  cat <<EOF >>~/.bashrc
# git aliases
if [ -f $SH_PROFILE_PATH/bash_aliases_git ] && type git &>/dev/null; then
  source $SH_PROFILE_PATH/bash_aliases_git
fi
EOF
fi
# add kubectl autocompletion and aliases
if ! grep -qw 'kubectl' ~/.bashrc && type -f kubectl &>/dev/null; then
  cat <<EOF >>~/.bashrc
# kubectl autocompletion and aliases
if type -f kubectl &>/dev/null; then
  source <(kubectl completion bash)
  complete -o default -F __start_kubectl k
  function kubectl() {
    echo "\$(tput setaf 5)\$(tput bold)kubectl \@\$(tput sgr0)" >&2
    command kubectl \$@
  }
  if [ -f $SH_PROFILE_PATH/bash_aliases_kubectl ]; then
    source $SH_PROFILE_PATH/bash_aliases_kubectl
  fi
fi
EOF
fi
# add oh-my-posh invocation
if ! grep -qw 'oh-my-posh' ~/.bashrc && type oh-my-posh &>/dev/null; then
  cat <<EOF >>~/.bashrc
# initialize oh-my-posh prompt
if [ -f $OH_MY_POSH_PATH/theme.omp.json ] && type oh-my-posh &>/dev/null; then
  eval "\$(oh-my-posh --init --shell bash --config $OH_MY_POSH_PATH/theme.omp.json)"
fi
EOF
fi
