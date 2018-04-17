#!/usr/bin/env bash
# ____   ____   ____                         _
# |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
# | | | | |     | | | | '__| | | | '_ \ / _  | |
# | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
# |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
#                               |_|
#
# Install and prepare a Drupal 8 project.
# https://github.com/Mogtofu33/docker-compose-drupal
#
# Usage:
#   install_drupal8.sh
#
# Depends on:
#  composer docker
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
# Help
###############################################################################

# _print_help()
#
# Usage:
#   _print_help
#
# Print the program help information.
_print_help() {
  cat <<HEREDOC
  ____   ____   ____                         _
 |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
 | | | | |     | | | | '__| | | | '_ \ / _  | |
 | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
 |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
                                |_|

Install and prepare a Drupal 8 project with Drupal template.
https://github.com/drupal-composer/drupal-project

Usage:
  ${_ME} -h | --helpcd 

Options:
  -h --help  Show this screen.
HEREDOC
}

###############################################################################
# Variables
###############################################################################

# Check where this script is run to fix base path.
if [[ "${_SOURCE}" = ./${_ME} ]]
then
  die "This script must be run from the ROOT DCD project. Invalid command : ${_SOURCE}"
elif [[ "${_SOURCE}" = scripts/${_ME} ]]
then
    _BASE_PATH="./"
elif [[ "${_SOURCE}" = ./scripts/${_ME} ]]
then
    _BASE_PATH="./"
else
  die "This script must be run within DCD project. Invalid command : ${_SOURCE}"
fi

source ${_BASE_PATH}.env

# _DRUPAL_ROOT=$(echo "$(pwd)${HOST_WEB_ROOT}"/drupal | sed -e 's/\.//g')
_DRUPAL_CONTAINER_ROOT="/var/www/localhost/drupal"
_PROJECT_CONTAINER_NAME="dcd-php"
_DRUSH_BIN="/var/www/localhost/drupal/vendor/bin/drush"
_DRUSH_ROOT="--root=/var/www/localhost/drupal/web"
_DRUSH_OPTIONS="--db-url=mysql://drupal:drupal@mysql/drupal --account-pass=password"
_COMPOSER=$(which composer)
_DOCKER=$(which docker)

###############################################################################
# Program Functions
###############################################################################

_check_dependencies() {

  if ! [ -x "$(command -v composer)" ]; then
    die "Composer is not installed. Please install to use this script.\n"
  fi

  if ! [ -x "$(command -v docker)" ]; then
    die "Docker is not installed. Please install to use this script.\n"
  fi

  # Check if containers are up...
  RUNNING=$(docker inspect --format="{{ .State.Running }}" "${_PROJECT_CONTAINER_NAME}" 2> /dev/null)
  if [ $? -eq 1 ]; then
    die "Container ${_PROJECT_CONTAINER_NAME} do not exist or is not running, run docker-compose up -d\n"
  fi
}

_get_drupal() {
  # Setup Drupal 8 composer project.
  $_COMPOSER create-project drupal-composer/drupal-project:8.x-dev "${_DRUPAL_CONTAINER_ROOT}" --stability dev --no-interaction
  $_COMPOSER --working-dir="${_DRUPAL_CONTAINER_ROOT}" require "drupal/devel" "drupal/admin_toolbar"
}

_install_drupal() {
  #docker exec -t $PROJECT_CONTAINER_NAME chown -R apache: /www
  $_DOCKER exec -t --user apache "${_PROJECT_CONTAINER_NAME}" "${_DRUSH_BIN}" "${_DRUSH_ROOT}" -y site:install "${_DRUSH_OPTIONS}" >> "${_DRUPAL_CONTAINER_ROOT}/drupal-install.log"
  $_DOCKER exec -t --user apache "${_PROJECT_CONTAINER_NAME}" "${_DRUSH_BIN}" "${_DRUSH_ROOT}" -y pm:enable admin_toolbar >> /dev/null
}

###############################################################################
# Main
###############################################################################

# _main()
#
# Usage:
#   _main [<options>] [<arguments>]
#
# Description:
#   Entry point for the program, handling basic option parsing and dispatching.
_main() {

  _check_dependencies

  # Run actions.
  if [[ "${1:-}" =~ ^install$ ]]
  then
    _get_drupal
    _install_drupal
  elif [[ "${1:-}" =~ ^get-only$ ]]
  then
    _get_drupal
  elif [[ "${1:-}" =~ ^install-only$ ]]
  then
    _install_drupal
  else
    _print_help
  fi
}

# Call `_main` after everything has been defined.
_main "$@"
