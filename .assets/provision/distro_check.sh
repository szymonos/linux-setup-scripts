#!/usr/bin/env bash
: '
.assets/provision/distro_check.sh | jq
.assets/provision/distro_check.sh array
'
# store the state in an associative array
declare -A state=(
  ["user"]="$(id -un)"
  ["az"]=$([ -f $HOME/.local/bin/az ] && echo "true" || echo "false")
  ["conda"]=$([ -d $HOME/miniconda3 ] && echo "true" || echo "false")
  ["git_user"]=$([ -n "$(git config --global --get user.name 2>/dev/null)" ] && echo "true" || echo "false")
  ["git_email"]=$([ -n "$(git config --global --get user.email 2>/dev/null)" ] && echo "true" || echo "false")
  ["gtkd"]=$(grep -Fqw "dark" /etc/profile.d/gtk_theme.sh 2>/dev/null && echo "true" || echo "false")
  ["k8s_base"]=$([ -f /usr/bin/kubectl ] && echo "true" || echo "false")
  ["k8s_ext"]=$([ -f /usr/local/bin/k3d ] && echo "true" || echo "false")
  ["omp"]=$([ -f /usr/bin/oh-my-posh ] && echo "true" || echo "false")
  ["pwsh"]=$([ -f /usr/bin/pwsh ] && echo "true" || echo "false")
  ["shell"]=$([ -f /usr/bin/rg ] && echo "true" || echo "false")
  ["ssh_key"]=$([ -f $HOME/.ssh/id_ed25519 ] && echo "true" || echo "false")
  ["systemd"]=$(grep -qw "systemd.*true" /etc/wsl.conf 2>/dev/null && echo "true" || echo "false")
  ["tf"]=$([ -f /usr/bin/terraform ] && echo "true" || echo "false")
  ["wsl_boot"]=$(grep -Fqw "autoexec.sh" /etc/wsl.conf 2>/dev/null && echo "true" || echo "false")
  ["wslg"]=$([ -d /mnt/wslg ] && echo "true" || echo "false")
  ["zsh"]=$([ -f /usr/bin/zsh ] && echo "true" || echo "false")
)

# function to check if a key is in the exclude list
is_excluded() {
  local key="$1"
  for exclude_key in "${exclude_keys[@]}"; do
    if [ "$key" = "$exclude_key" ]; then
      return 0
    fi
  done
  return 1
}

# check if array parameter is provided
if [ "$1" = 'array' ]; then
  # keys to exclude
  exclude_keys=('git_user' 'git_email' 'ssh_key' 'systemd' 'wslg' 'wsl_boot' 'gtkd')
  # print only the keys with true values, excluding specified keys
  for key in "${!state[@]}"; do
    if [ "${state[$key]}" = "true" ] && ! is_excluded "$key"; then
      echo "$key"
    fi
  done
else
  # print the state as JSON
  json="{"
  for key in "${!state[@]}"; do
    [ "$key" = 'user' ] && value="\"${state[$key]}\"" || value="${state[$key]}"
    json+="\"$key\":$value,"
  done
  json="${json%,}}"
  echo "$json"
fi
