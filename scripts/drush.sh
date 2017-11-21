#!/usr/bin/env bash
# ____   ____   ____                         _
# |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
# | | | | |     | | | | '__| | | | '_ \ / _  | |
# | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
# |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
#                               |_|
#
# Helper to set drush alias for Docker Compose Drupal project, so every Drush cmd
# will be executed on the Docker container.
# https://github.com/Mogtofu33/docker-compose-drupal
#
# Usage:
#   source drush.sh
#   source drush.sh --end
#
# Depends on:
#  docker
#
# Bash Boilerplate: https://github.com/alphabetum/bash-boilerplate
# Bash Boilerplate: Copyright (c) 2015 William Melody • hi@williammelody.com

# Set IFS to just newline and tab at the start
SAFER_IFS=$'\n\t'
IFS="${SAFER_IFS}"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE_BOLD='\033[1;36m'
NC='\033[0m'

# Error or bypass actions, as we source this script we cannot exit.
_ERROR=0

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
  printf "${RED}❌${NC}  "
  "${@}" 1>&2
  _ERROR=1
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
  _die echo -e "${@}"
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

Helper to set drush alias for Docker Compose Drupal project, so every Drush cmd
will be executed on the Docker container.

Usage:
  source drush.sh [ROOT] [DRUSH] [CONTAINER] [USER:GROUP]
  drush.sh -h | --help

To stop this Drush session, source with end option:
  source drush.sh --end

Arguments (optional):
  first argument
    Drupal root path in the container, default /var/www/localhost/drupal
  second argument
    Drush bin path in the container, default /var/www/localhost/drupal/vendor/bin/drush
  third argument
    Container user and group, default apache:www-data

Options:
  -e --end
    End the drush session and remove alias.
  -h --help
    Show this screen and exit.
HEREDOC
}

###############################################################################
# Program Functions
###############################################################################

# Default local variables.
container='dcd-php'
user='apache'
drupal_root='--root=/var/www/localhost/drupal/web'
drush_bin='/var/www/localhost/drupal/vendor/bin/drush'

_check_docker() {
  if ! [ -x "$(command -v docker)" ]; then
    die "Docker is not installed. Please install to use this script."
  fi
}

_set_variables_container() {
  # Get first apache container running.
  WEB_RUNNING=$(docker ps -f "name=php" -f "status=running" -q | head -1 2> /dev/null)
  if [ -z "$WEB_RUNNING" ]; then
    die "No running Apache container found, do you run docker-compose up -d ?"
  else
    container=$(docker inspect --format="{{ .Name }}" $WEB_RUNNING)
    container="${container///}"
  fi

  # Check if this container exist.
  RUNNING=$(docker inspect --format="{{ .State.Running }}" $container 2> /dev/null)
  if [ $? -eq 1 ]; then
    _die printf "Container %s does not exist, here is all running containers:\n%s\n" \
      "$container" \
      "$(docker ps --format "table {{.Names}}\t{{.Status}}" -f 'status=running')"
  fi
}

_set_variables() {
  if [[ $1 ]]; then
    drupal_root="--root=${1}"
  fi

  if [[ !$2 ]]; then
    # Check if this drush is valid.
    TEST_DRUSH_BIN=$(docker exec $container cat $drush_bin 2> /dev/null)
    if [ $? -eq 1 ]; then
      die "Project do not contain drush, please specify a path within the container. Path tested:\n${drush_bin}"
    fi
  else
    drush_bin=$2
  fi

  if [[ $3 ]]; then
    user=$3
  fi
}

_set_alias() {
  export DK_USER=$user
  export DK_CONTAINER=$container
  export DK_DRUSH_BIN=$drush_bin
  export DK_DRUPAL_ROOT=$drupal_root
  export DK_TMP_PS1=$PS1
  alias drush="docker exec --user $DK_USER --interactive $DK_CONTAINER $DK_DRUSH_BIN $DK_DRUPAL_ROOT"
  PS1="$PS1\[${BLUE_BOLD}[drush|$DK_CONTAINER]> ${NC}"
  echo -e "${GREEN}Alias set!${NC} to stop it and restore your drush, run:\nsource drush.sh --end"
}

_remove_alias() {
  PS1="${DK_TMP_PS1}"
  unset DK_USER
  unset DK_CONTAINER
  unset DK_DRUPAL_ROOT
  unset DK_TMP_PS1
  unalias drush
  echo -e "${GREEN}Drush alias successfully restored, bye!${NC}"
}

_check_help() {
  if [ "${1:-}" == "--help" ] || [ "${1:-}" == "-h" ] ; then
    _print_help
    _ERROR=1
  fi
}

_check_end() {
  if [ "${1:-}" == "--end" ] || [ "${1:-}" == "-e" ] ; then
    if [ -z ${DK_TMP_PS1+x} ]; then
      echo -e "${BLUE_BOLD}[info]${NC} Drush alias is not set, nothing to restore."
      _ERROR=1
    else
      _remove_alias
      _ERROR=1
    fi
  fi
}

_check_source() {
  if [[ "$(basename -- "$0")" == "drush.sh" ]]; then
    die "Do not run $0, source it:\nsource $0" >&2
    # Only exit case as the script is not sourced.
    exit
  fi
}

_check_alias() {
  if [ ${DK_TMP_PS1+x} ]; then
    echo -e "${BLUE_BOLD}[info]${NC} Drush alias is already set, to restore close this terminal or run:\nsource drush.sh --end"
    _ERROR=1
  fi
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
  _check_source
  if [ "${_ERROR}" == 0 ]; then
    _check_docker
    if [ "${_ERROR}" == 0 ]; then
      _check_help "$@"
      if [ "${_ERROR}" == 0 ]; then
        _check_end "$@"
        if [ "${_ERROR}" == 0 ]; then
          _check_alias
          if [ "${_ERROR}" == 0 ]; then
            _set_variables_container "$@"
            if [ "${_ERROR}" == 0 ]; then
              _set_variables "$@"
              if [ "${_ERROR}" == 0 ]; then
                _set_alias
              fi
            fi
          fi
        fi
      fi
    fi
  fi
}

# Call `_main` after everything has been defined.
_main "$@"
