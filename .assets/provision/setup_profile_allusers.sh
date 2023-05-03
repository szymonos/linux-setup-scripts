#!/usr/bin/env bash
: '
sudo .assets/provision/setup_profile_allusers.sh
sudo .assets/provision/setup_profile_allusers.sh $(id -un)
'
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n'
  exit 1
fi

# check if specified user exists
user=${1:-$(id -un 1000 2>/dev/null)}
if ! grep -qw "^$user" /etc/passwd; then
  if [ -n "$user" ]; then
    printf "\e[31;1mUser does not exist ($user).\e[0m\n"
  else
    printf "\e[31;1mUser ID 1000 not found.\e[0m\n"
  fi
  exit 1
fi

# path variables
CFG_PATH="$(sudo -u $user sh -c 'echo $HOME/tmp/config/bash_cfg')"
PROFILE_PATH='/etc/profile.d'
OMP_PATH='/usr/local/share/oh-my-posh'
# copy config files for WSL setup
if [ -d .assets/config/bash_cfg ]; then
  sudo -u $user mkdir -p $CFG_PATH
  cp -f .assets/config/bash_cfg/* $CFG_PATH
fi
# *modify exa alias
if [ -f $CFG_PATH/aliases.sh ]; then
  # *set nerd fonts if oh-my-posh uses them
  exa_param=''
  exa --version 2>/dev/null | grep -Fqw '+git' && exa_param+='--git ' || true
  grep -Fqw '' $OMP_PATH/theme.omp.json 2>/dev/null && exa_param+='--icons ' || true
  sed -i "s/exa -g /exa -g $exa_param/" $CFG_PATH/aliases.sh
fi

# *Copy global profiles
if [ -d $CFG_PATH ]; then
  # bash aliases
  install -m 0644 $CFG_PATH/aliases.sh $PROFILE_PATH
  # git aliases
  if type git &>/dev/null; then
    install -m 0644 $CFG_PATH/aliases_git.sh $PROFILE_PATH
  fi
  # kubectl aliases
  if type -f kubectl &>/dev/null; then
    install -m 0644 $CFG_PATH/aliases_kubectl.sh $PROFILE_PATH
  fi
  # clean config folder
  rm -fr $CFG_PATH
  # TODO to be removed, cleanup legacy aliases
  rm -f $PROFILE_PATH/bash_aliases $PROFILE_PATH/bash_aliases_git $PROFILE_PATH/bash_aliases_kubectl
fi

# *bash profile
# add common bash aliases
grep -qw 'd/aliases.sh' ~/.bashrc 2>/dev/null || cat <<EOF >>~/.bashrc
# common aliases
if [ -f $PROFILE_PATH/aliases.sh ]; then
  source $PROFILE_PATH/aliases.sh
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
if grep -qw '^vagrant' <<<$(getent group) && [[ ! -f /usr/share/polkit-1/rules.d/49-nopasswd_shutdown.rules && -d /usr/share/polkit-1/rules.d ]]; then
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
