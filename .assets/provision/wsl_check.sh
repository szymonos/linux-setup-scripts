#!/usr/bin/env sh
: '
.assets/provision/wsl_check.sh
'
# get state of distro environment
[ -f /usr/bin/rg ] && shell="true" || shell="false"
[ -f /usr/bin/pwsh ] && pwsh="true" || pwsh="false"
[ -f /usr/bin/zsh ] && zsh="true" || zsh="false"
[ -f /usr/bin/kubectl ] && k8s_base="true" || k8s_base="false"
[ -f /usr/local/bin/k3d ] && k8s_ext="true" || k8s_ext="false"
[ -f /usr/bin/oh-my-posh ] && omp="true" || omp="false"
[ -f /usr/bin/terraform ] && tf="true" || tf="false"
[ -d $HOME/.local/share/powershell/Modules/Az ] && az="true" || az="false"
[ -d $HOME/miniconda3 ] && conda="true" || conda="false"
[ -f $HOME/.ssh/id_ed25519 ] && ssh_key="true" || ssh_key="false"
[ -d /mnt/wslg ] && wslg="true" || wslg="false"
grep -qw "autoexec\.sh" /etc/wsl.conf 2>/dev/null && wsl_boot="true" || wsl_boot="false"
git_user_name="$(git config --global --get user.name 2>/dev/null)"
[ -n "$git_user_name" ] && git_user="true" || git_user="false"
git_user_email="$(git config --global --get user.email 2>/dev/null)"
[ -n "$git_user_email" ] && git_email="true" || git_email="false"
grep -qw "systemd.*true" /etc/wsl.conf 2>/dev/null && systemd="true" || systemd="false"
grep -Fqw "dark" /etc/profile.d/gtk_theme.sh 2>/dev/null && gtkd="true" || gtkd="false"

# print the state as JSON
printf '{
  "user": "%s",
  "shell": %s,
  "k8s_base": %s,
  "k8s_ext": %s,
  "omp": %s,
  "az": %s,
  "wslg": %s,
  "wsl_boot": %s,
  "conda": %s,
  "systemd": %s,
  "gtkd": %s,
  "pwsh": %s,
  "tf": %s,
  "zsh": %s,
  "git_user": %s,
  "git_email": %s,
  "ssh_key": %s
}' "$(id -un)" "$shell" "$k8s_base" "$k8s_ext" "$omp" "$az" "$wslg" "$wsl_boot" "$conda" "$systemd" "$gtkd" "$pwsh" "$tf" "$zsh" "$git_user" "$git_email" "$ssh_key"
