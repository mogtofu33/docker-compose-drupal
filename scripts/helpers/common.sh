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

# Check where this script is run to fix base path.
# if [[ "${_SOURCE}" = ./${_ME} ]]
# then
#   die "This script must be run from the ROOT DCD project. Invalid command : ${_SOURCE}"
# elif [[ "${_SOURCE}" = scripts/${_ME} ]]
# then
#     _BASE_PATH="./"
# elif [[ "${_SOURCE}" = ./scripts/${_ME} ]]
# then
#     _BASE_PATH="./"
# else
#   die "This script must be run within DCD project. Invalid command : ${_SOURCE}"
# fi

###############################################################################
# Variables
###############################################################################

# Get Stack values.
source $_DIR/../../.env

# Get global values.
source $_DIR/../.env

_NOW="$(date +'%Y%m%d.%H-%M-%S')"
tty=
tty -s && tty=--tty

_DRUPAL_ROOT="/drupal"
# _BASE_SOURCE=$(pwd)
# _BASE_SOURCE=${_BASE_SOURCE%/scripts}

# _DRUPAL_ROOT=$(echo "${_BASE_SOURCE}${HOST_WEB_ROOT}${_DRUPAL_ROOT}" | sed -e 's/\.//g')
_DOCKER=$(which docker)
_COMPOSER=$(which composer)
_DOCKER=$(which docker)

###############################################################################
# Common Program Functions
###############################################################################

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

_check_dependencies_docker_up() {

  # Check if containers are up...
  RUNNING=$(docker inspect --format="{{ .State.Running }}" "${_PROJECT_CONTAINER_NAME}" 2> /dev/null)
  if [ $? -eq 1 ]; then
    die "Container ${_PROJECT_CONTAINER_NAME} do not exist or is not running, run docker-compose up -d\n"
  fi

}