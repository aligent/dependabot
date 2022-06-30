#!/bin/bash
#set -x

APP_ROOT="/home/dependabot/dependabot-script"

cd $APP_ROOT

exec "bundle exec ruby ./bitbucket-update-script.rb"

