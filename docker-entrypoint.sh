#!/bin/bash

# Allow Shell access if needed
if [ "${1:-}" = "bash" ]; then
  shift
  exec bash "$@"
fi

pushd ${CODE_DIR} > /dev/null

exec bundle exec ruby ./bitbucket-update-script.rb "$@"