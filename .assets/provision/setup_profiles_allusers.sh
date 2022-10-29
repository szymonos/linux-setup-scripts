#!/bin/bash
: '
sudo .assets/provision/setup_profiles_allusers.sh
'
# path varaibles
SH_PROFILE_PATH='/etc/profile.d'
PS_PROFILE_PATH=$(pwsh -nop -c '[IO.Path]::GetDirectoryName($PROFILE.AllUsersAllHosts)')
PS_SCRIPTS_PATH='/usr/local/share/powershell/Scripts'
OH_MY_POSH_PATH='/usr/local/share/oh-my-posh'

# *Copy global profiles
if [ -d /tmp/config ]; then
  # bash aliases
  \mv -f /tmp/config/bash_* $SH_PROFILE_PATH
  # oh-my-posh profile
  \mkdir -p $OH_MY_POSH_PATH
  \mv -f /tmp/config/theme.omp.json $OH_MY_POSH_PATH
  # PowerShell profile
  \mv -f /tmp/config/profile.ps1 $PS_PROFILE_PATH
  # PowerShell functions
  \mkdir -p $PS_SCRIPTS_PATH
  \mv -f /tmp/config/ps_aliases_common.ps1 $PS_SCRIPTS_PATH
  # git functions
  if type git &>/dev/null; then
    \mv -f /tmp/config/ps_aliases_git.ps1 $PS_SCRIPTS_PATH
  fi
  # kubectl functions
  if type kubectl &>/dev/null; then
    \mv -f /tmp/config/ps_aliases_kubectl.ps1 $PS_SCRIPTS_PATH
  fi
  # clean config folder
  rm -fr /tmp/config
fi

# *PowerShell profile
pwsh -nop -c 'if (-not ((Get-Module PowerShellGet -ListAvailable -ErrorAction SilentlyContinue).Version.Major -ge 3)) { Install-Module PowerShellGet -AllowPrerelease -Scope AllUsers -Force }'
# install modules and setup experimental features
cat <<'EOF' | pwsh -nop -c -
$WarningPreference = 'Ignore';
if (-not (Get-PSResourceRepository -Name PSGallery).Trusted) { Set-PSResourceRepository -Name PSGallery -Trusted };
if (-not ((Get-Module PSReadLine -ListAvailable -ErrorAction SilentlyContinue).Version.Minor -ge 2)) { Install-PSResource -Name PSReadLine -Scope AllUsers };
if (-not (Get-Module posh-git -ListAvailable)) { Install-PSResource -Name posh-git -Scope AllUsers };
if (-not $PSNativeCommandArgumentPassing) { Enable-ExperimentalFeature PSNativeCommandArgumentPassing };
if (-not $PSStyle) { Enable-ExperimentalFeature PSAnsiRenderingFileInfo };
EOF

# *bash profile
# add common bash aliases
grep -qw 'd/bash_aliases' ~/.bashrc || cat <<EOF >>~/.bashrc
# common aliases
if [ -f $SH_PROFILE_PATH/bash_aliases ]; then
  source $SH_PROFILE_PATH/bash_aliases
fi
EOF
# add oh-my-posh invocation
if ! grep -qw 'oh-my-posh' ~/.bashrc && type oh-my-posh &>/dev/null; then
  cat <<EOF >>~/.bashrc
# initialize oh-my-posh prompt
if [ -f $OH_MY_POSH_PATH/theme.omp.json ] && type oh-my-posh &>/dev/null; then
  eval "\$(oh-my-posh --init --shell bash --config $OH_MY_POSH_PATH/theme.omp.json)"
fi
EOF
fi
# make path autocompletion case insensitive
grep -qw 'completion-ignore-case' /etc/inputrc || echo 'set completion-ignore-case on' >>/etc/inputrc

# *set localtime to UTC
[ -f /etc/localtime ] || ln -s /usr/share/zoneinfo/UTC /etc/localtime
