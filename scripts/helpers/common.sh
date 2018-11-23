#!/usr/bin/env bash
# Helper to have common bash settings for most of the scripts.
# Based on Bash simple Boilerplate.
# https://github.com/Mogtofu33/docker-compose-drupal
#
# Bash Boilerplate: https://github.com/alphabetum/bash-boilerplate
# Bash Boilerplate: Copyright (c) 2015 William Melody • hi@williammelody.com

# Short form: set -u
set -o nounset

# Exit immediately if a pipeline returns non-zero.
set -o errexit

# Print a helpful message if a pipeline with non-zero exit code causes the
# script to exit as described above.
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR

# Allow the above trap be inherited by all functions in the script.
# Short form: set -E
set -o errtrace

# Return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
set -o pipefail

# Set IFS to just newline and tab at the start
SAFER_IFS=$'\n\t'
IFS="${SAFER_IFS}"

###############################################################################
# Environment
###############################################################################

# $_ME
#
# Set to the program's basename.
_ME=$(basename "${0}")

# $_SOURCE
#
# Set to the program's source.
_SOURCE="${BASH_SOURCE[0]}"

while [ -h "$_SOURCE" ]; do # resolve $_SOURCE until the file is no longer a symlink
  _DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"
  _SOURCE="$(readlink "$_SOURCE")"
  [[ $_SOURCE != /* ]] && _SOURCE="$_DIR/$_SOURCE" # if $_SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
_DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"

# Use on a lot of scripts.
STACK_ROOT=${_DIR%"scripts/helpers"}

###############################################################################
# Die
###############################################################################

# _die()
#
# Usage:
#   _die printf "Error message. Variable: %s\n" "$0"
#
# A simple function for exiting with an error after executing the specified
# command. The command is expected to print a message and should typically
# be either `echo`, `printf`, or `cat`.
_die() {
  # Prefix die message with "cross mark (U+274C)", often displayed as a red x.
  printf "❌  "
  "${@}" 1>&2
  exit 1
}
# die()
#
# Usage:
#   die "Error message. Variable: $0"
#
# Exit with an error and print the specified message.
#
# This is a shortcut for the _die() function that simply echos the message.
die() {
  _die echo "${@}"
}

###############################################################################
# Variables
###############################################################################

# Get Stack values if any.
if [ -f $_DIR/../../.env ]; then
  source $_DIR/../../.env
fi

# Get scripts values.
if [ -f $_DIR/../.env ]; then
  source $_DIR/../.env
fi

# Get local overrides.
if [ -f $_DIR/../.env.local ]; then
  source $_DIR/../.env.local
fi

# Basic variables.
_NOW="$(date +'%Y%m%d.%H-%M-%S')"
tty=
tty -s && tty=--tty

_DOCKER=$(which docker)

###############################################################################
# Common Program Functions
###############################################################################

# Helpers to run docker exec command.
_docker_exec() {
  $_DOCKER exec \
    $tty \
    --interactive \
    --user ${PROJECT_UID} \
    "${PROJECT_CONTAINER_NAME}" \
    "$@"
}

_docker_exec_noi() {
  $_DOCKER exec \
    $tty \
    --user ${PROJECT_UID} \
    "${PROJECT_CONTAINER_NAME}" \
    "$@"
}

_docker_exec_noi_u() {
  $_DOCKER exec \
    "${PROJECT_CONTAINER_NAME}" \
    "$@"
}

# Helper to run docker run command.
_docker_run() {
  $_DOCKER run \
    $tty \
    --interactive \
    --rm \
    --user $(id -u):$(id -g) \
    --volume /etc/passwd:/etc/passwd:ro \
    --volume /etc/group:/etc/group:ro \
    "$@"
}

# Helper to ensure mysql container is runing.
_set_container_mysql() {
  RUNNING=$(docker ps -f "name=mariadb" -f "name=mysql" -f "status=running" -q | head -1 2> /dev/null)
  if [ -z "$RUNNING" ]; then
    die "No running MySQL container found, did you run docker-compose up -d ?"
  else
    PROJECT_CONTAINER_MYSQL=$(docker inspect --format="{{ .Name }}" $RUNNING)
    PROJECT_CONTAINER_MYSQL="${PROJECT_CONTAINER_MYSQL///}"
  fi
}

# Helper to ensure postgres container is runing.
_set_container_pgsql() {
  RUNNING=$(docker ps -f "name=pgsql" -f "status=running" -q | head -1 2> /dev/null)
  if [ -z "$RUNNING" ]; then
    die "No running PGSQL container found, did you run docker-compose up -d ?"
  else
    PROJECT_CONTAINER_PGSQL=$(docker inspect --format="{{ .Name }}" $RUNNING)
    PROJECT_CONTAINER_PGSQL="${PROJECT_CONTAINER_PGSQL///}"
  fi
}

# Helper to ensure php container is runing.
_set_project_container_php() {
    RUNNING=$(docker ps -f "name=php" -f "status=running" -q | head -1 2> /dev/null)
  if [ -z "$RUNNING" ]; then
    die "No running PHP container found, did you run docker-compose up -d ?"
  else
    PROJECT_CONTAINER_NAME=$(docker inspect --format="{{ .Name }}" $RUNNING)
    PROJECT_CONTAINER_NAME="${PROJECT_CONTAINER_NAME///}"
  fi
}

# A logo, because it's cool.
_help_logo() {
  cat <<HEREDOC
   ___  _____  __  __  ____    ___   ___  ____  ____  ____  ____  ___  
  / __)(  _  )(  \/  )( ___)  / __) / __)(  _ \(_  _)(  _ \(_  _)/ __) 
  \__ \ )(_)(  )    (  )__)   \__ \( (__  )   / _)(_  )___/  )(  \__ \ 
  (___/(_____)(_/\/\_)(____)  (___/ \___)(_)\_)(____)(__)   (__) (___/ 
HEREDOC
}

###############################################################################
# _prompt_yn()
#
# Description:
#   Display a simple yes/no prompt and stop if no.
_prompt_yn() {
  printf "Are you sure?\\n"
  select yn in "Yes" "No"; do
      case $yn in
          Yes ) break;;
          No ) die "Canceled";;
      esac
  done
}

###############################################################################
# Init
###############################################################################

# _init()
#
# Description:
#   Entry point for all programs, check and set minimum variables.
_init() {

  # The php container is used basically for all scripts.
  _set_project_container_php

}

# Call `_init` after everything has been defined.
_init $@
