#!/bin/bash
: '
sudo .assets/provision/setup_profiles_allusers.sh
'
# path varaibles
PROFILE_PATH='/etc/profile.d'
OMP_PATH='/usr/local/share/oh-my-posh'

# *Copy global profiles
if [ -d /tmp/config/bash_cfg ]; then
  # bash aliases
  \mv -f /tmp/config/bash_cfg/bash_aliases $PROFILE_PATH
  # git aliases
  if type git &>/dev/null; then
    \mv -f /tmp/config/bash_cfg/bash_aliases_git $PROFILE_PATH
  fi
  # kubectl aliases
  if type -f kubectl &>/dev/null; then
    \mv -f /tmp/config/bash_cfg/bash_aliases_kubectl $PROFILE_PATH
  fi
  # clean config folder
  \rm -fr /tmp/config/bash_cfg
fi

# *bash profile
# add common bash aliases
grep -qw 'd/bash_aliases' ~/.bashrc 2>/dev/null || cat <<EOF >>~/.bashrc
# common aliases
if [ -f $PROFILE_PATH/bash_aliases ]; then
  source $PROFILE_PATH/bash_aliases
fi
EOF

# add oh-my-posh invocation
if ! grep -qw 'oh-my-posh' ~/.bashrc 2>/dev/null && type oh-my-posh &>/dev/null; then
  cat <<EOF >>~/.bashrc
# initialize oh-my-posh prompt
if [ -f $OMP_PATH/theme.omp.json ] && type oh-my-posh &>/dev/null; then
  eval "\$(oh-my-posh --init --shell bash --config $OMP_PATH/theme.omp.json)"
fi
EOF
fi

# make path autocompletion case insensitive
grep -qw 'completion-ignore-case' /etc/inputrc || echo 'set completion-ignore-case on' >>/etc/inputrc

# *set localtime to UTC
[ -f /etc/localtime ] || ln -s /usr/share/zoneinfo/UTC /etc/localtime

# *add reboot/shutdown polkit rule for vagrant group
if getent group | grep -qw '^vagrant' && [ ! -f /usr/share/polkit-1/rules.d/49-nopasswd_shutdown.rules ]; then
  cat <<EOF >/usr/share/polkit-1/rules.d/49-nopasswd_shutdown.rules
/* Allow members of the vagrant group to shutdown or restart
 * without password authentication.
 */
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.login1.power-off" ||
         action.id == "org.freedesktop.login1.reboot") &&
        subject.isInGroup("vagrant"))
    {
        return polkit.Result.YES;
    }
});
EOF
fi
