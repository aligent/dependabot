#!/bin/bash

# Allow Shell access if needed
if [ "${1:-}" = "bash" ]; then
  shift
  exec bash "$@"
fi

# Stash the current directory to the REPOSITORY_PATH env var (if it isn't already set)
# In BB pipelines this will be where the local copy of the repository is mounted
export REPOSITORY_PATH=${REPOSITORY_PATH:-${PWD}}

pushd ${CODE_DIR} > /dev/null

exec bundle exec ruby ./bitbucket-update-script.rb "$@"