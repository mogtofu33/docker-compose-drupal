#!/usr/bin/env bash
# ____   ____   ____                         _
# |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
# | | | | |     | | | | '__| | | | '_ \ / _  | |
# | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
# |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
#                               |_|
#
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

# Get Stack values.
if [ -f $_DIR/../../.env ]; then
  source $_DIR/../../.env
fi

# Get global values.
if [ -f $_DIR/../.env ]; then
  source $_DIR/../.env
fi

_NOW="$(date +'%Y%m%d.%H-%M-%S')"
tty=
tty -s && tty=--tty

_DRUPAL_ROOT="/drupal"

_DOCKER=$(which docker)
_COMPOSER=$(which composer)
_DOCKER=$(which docker)

###############################################################################
# Common Program Functions
###############################################################################

# Helper to run docker run command.
_docker_run() {
  $_DOCKER run \
    $tty \
    --interactive \
    --rm \
    --user "${LOCAL_UID}":"${LOCAL_GID}" \
    --volume /etc/passwd:/etc/passwd:ro \
    --volume /etc/group:/etc/group:ro \
    "$@"
}

# Helper to run docker exec command.
_docker_exec() {
  $_DOCKER exec \
    $tty \
    --interactive \
    "$@"
}

_check_dependencies_docker() {

  if ! [ -x "$(command -v docker)" ]; then
    die "Docker is not installed. Please install to use this script.\n"
  fi

}

_check_dependencies_git() {

  if ! [ -x "$(command -v git)" ]; then
    die "Git is not installed. Please install to use this script.\n"
  fi

}

_check_dependencies_composer() {

  if ! [ -x "$(command -v composer)" ]; then
    die "Composer is not installed. Please install to use this script.\n"
  fi

}

_check_dependencies_compass() {

  if ! [ -x "$(command -v compass)" ]; then
    die "Compass is not installed. Please install to use this script.\n"
  fi

}

_set_container_mysql() {

  RUNNING=$(docker ps -f "name=mysql" -f "status=running" -q | head -1 2> /dev/null)
  if [ -z "$RUNNING" ]; then
    die "No running MySQL container found, do you run docker-compose up -d ?"
  else
    PROJECT_CONTAINER_MYSQL=$(docker inspect --format="{{ .Name }}" $RUNNING)
    PROJECT_CONTAINER_MYSQL="${PROJECT_CONTAINER_MYSQL///}"
  fi

}

_set_container_pgsql() {

  RUNNING=$(docker ps -f "name=pgsql" -f "status=running" -q | head -1 2> /dev/null)
  if [ -z "$RUNNING" ]; then
    die "No running PGSQL container found, do you run docker-compose up -d ?"
  else
    PROJECT_CONTAINER_PGSQL=$(docker inspect --format="{{ .Name }}" $RUNNING)
    PROJECT_CONTAINER_PGSQL="${PROJECT_CONTAINER_PGSQL///}"
  fi

}

_set_project_container_name() {

    RUNNING=$(docker ps -f "name=php" -f "status=running" -q | head -1 2> /dev/null)
  if [ -z "$RUNNING" ]; then
    die "No running PHP container found, do you run docker-compose up -d ?"
  else
    PROJECT_CONTAINER_NAME=$(docker inspect --format="{{ .Name }}" $RUNNING)
    PROJECT_CONTAINER_NAME="${PROJECT_CONTAINER_NAME///}"
  fi

}

_set_drush_bin() {

  # Check if this drush is valid.
  TEST_DRUSH=$(docker exec $PROJECT_CONTAINER_NAME cat $DRUSH_BIN 2> /dev/null)
  if [ $? -eq 1 ]; then
    die "Project do not contain drush, please install or check path. Path tested: ${PROJECT_CONTAINER_NAME}:${DRUSH_BIN}"
  fi

}

_set_drupal_bin() {

  # Check if this drupal console is valid.
  TEST_DRUPAL=$(docker exec $PROJECT_CONTAINER_NAME cat $DRUPAL_BIN 2> /dev/null)
  if [ $? -eq 1 ]; then
    die "Project do not contain Drupal Console, please install or check path. Path tested: ${PROJECT_CONTAINER_NAME}:${DRUPAL_BIN}"
  fi

}

###############################################################################
# Init
###############################################################################

# _init()
#
# Description:
#   Entry point for all programs, check and set minimum variables.
_init() {

  _set_project_container_name
  _set_drush_bin
  _set_drupal_bin

}

# Call `_init` after everything has been defined.
_init
