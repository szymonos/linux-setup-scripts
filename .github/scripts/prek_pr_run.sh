#!/usr/bin/env bash
: '
Run pre-commit hooks using prek for pull request or all files.

# :example
.github/scripts/prek_pr_run.sh --event_name pull_request
.github/scripts/prek_pr_run.sh
'

# parse named parameters
event_name=${event_name}
base_ref=${base_ref:-main}
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

if [ "$event_name" = "pull_request" ]; then
  printf "\033[1;34mRunning pre-commit hooks for pull request...\033[0m\n"
  prek run \
    --show-diff-on-failure --color=always \
    --from-ref "origin/$base_ref" --to-ref HEAD
else
  # for manual runs / main branch runs, fall back to checking all files
  printf "\033[1;34mRunning pre-commit hooks for all files...\033[0m\n"
  prek run \
    --show-diff-on-failure --color=always \
    --all-files
fi
