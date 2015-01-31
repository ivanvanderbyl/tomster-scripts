#!/bin/bash

# Causes this script to exit if a variable isn't present
set -u

##############################################################
#
# BOOTSTRAP FUNCTIONS
# These functions are used throughout the bootstrap.sh file
#
##############################################################

TOMSTER_PROMPT="\033[90m$\033[0m"

function tomster-prompt-and-run {
  echo -e "$TOMSTER_PROMPT $1"
  eval $1
}

function tomster-run {
  echo -e "$TOMSTER_PROMPT $1"
  eval $1
  EVAL_EXIT_STATUS=$?

  if [[ $EVAL_EXIT_STATUS -ne 0 ]]; then
    exit $EVAL_EXIT_STATUS
  fi
}

##############################################################
#
# PATH DEFAULTS
# Come up with the paths used throughout the bootstrap.sh file
#
##############################################################

# Add the $TOMSTER_BIN_PATH to the $PATH
# export PATH="$TOMSTER_BIN_PATH:$PATH"

##############################################################
#
# REPOSITORY HANDLING
# Creates the build folder and makes sure we're running the
# build at the right commit.
#
##############################################################

# Remove the checkout folder if TOMSTER_CLEAN_CHECKOUT is present
echo '--- Cleaning up workspace'
tomster-run "rm -rf /opt/app"

echo '--- Preparing build workspace'

tomster-run "mkdir -p /opt/app"
tomster-run "cd /opt/app"

# Do we need to do a git checkout?
if [[ ! -d ".git" ]]; then
  tomster-run "git clone \"$CLONE_URL\" . -qv"
fi

# Calling `git clean` with the -x will also remove all ignored files, to create
# a pristine working directory
tomster-run "git clean -fdqx"
tomster-run "git submodule foreach --recursive git clean -fdqx"

tomster-run "git fetch -q"

# Allow checkouts of forked pull requests on GitHub only. See:
# https://help.github.com/articles/checking-out-pull-requests-locally/#modifying-an-inactive-pull-request-locally
if [[ "$TOMSTER_PULL_REQUEST" != "false" ]] && [[ "$TOMSTER_PROJECT_PROVIDER" == *"github"* ]]; then
  tomster-run "git fetch origin \"+refs/pull/$TOMSTER_PULL_REQUEST/head:\""
elif [[ "$TOMSTER_TAG" == "" ]]; then
  # Default empty branch names
  : ${TOMSTER_BRANCH:=master}

  tomster-run "git reset --hard origin/$TOMSTER_BRANCH"
fi

tomster-run "git checkout -qf \"$TOMSTER_COMMIT\""

# `submodule sync` will ensure the .git/config matches the .gitmodules file
tomster-run "git submodule sync"
tomster-run "git submodule update --init --recursive"
tomster-run "git submodule foreach --recursive git reset --hard"

##############################################################
#
# RUN THE BUILD
# Determines how to run the build, and then runs it
#
##############################################################

echo '--- Running npm install'
tomster-run "npm install --silent"
echo '--- Running bower install'
tomster-run "bower --allow-root --silent install"

echo '--- Configuring app for Tomster deployment'
tomster-run "mkdir -p /opt/app/config/deploy/"
tomster-run "cp -f /opt/setup/production.js /opt/app/config/deploy/production.js"
tomster-run "npm install ivanvanderbyl/ember-cli-deploy --save-dev"

echo '--- Building...'
tomster-run "ember build --environment=production"
tomster-run "ember deploy:assets --environment=production"

# Capture the exit status for the end
EXIT_STATUS=$?

# Be sure to exit this script with the same exit status that the users build
# script exited with.
exit $EXIT_STATUS
