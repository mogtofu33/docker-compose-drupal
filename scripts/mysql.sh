#!/usr/bin/env bash
# ____   ____   ____                         _
# |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
# | | | | |     | | | | '__| | | | '_ \ / _  | |
# | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
# |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
#                               |_|
#
# Helper to run mysql dump/restore, part of Docker Compose Drupal project.
# Based on Bash simple Boilerplate.
# https://github.com/Mogtofu33/docker-compose-drupal
#
# Usage:
#   pgsql dump | restore
#
# Depends on:
#  docker
#
# Bash Boilerplate: https://github.com/alphabetum/bash-boilerplate
# Bash Boilerplate: Copyright (c) 2015 William Melody • hi@williammelody.com

_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$_SOURCE" ]; do # resolve $_SOURCE until the file is no longer a symlink
  _DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"
  _SOURCE="$(readlink "$_SOURCE")"
  [[ $_SOURCE != /* ]] && _SOURCE="$_DIR/$_SOURCE" # if $_SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
_DIR="$( cd -P "$( dirname "$_SOURCE" )" && pwd )"

source $_DIR/helpers/common.sh

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

Helper to dump and restore MYSQL db with drush.

Usage:
  ${_ME} [dump | restore]
  ${_ME} -h | --help

Options:
  -h --help  Show this screen.
HEREDOC
}

###############################################################################
# Program Functions
###############################################################################

_dump() {

  $_DOCKER exec $tty "${PROJECT_CONTAINER_PHP}" mkdir -p "${PROJECT_CONTAINER_DUMP}"

  $_DOCKER exec \
    $tty \
    --interactive \
    --user "${PROJECT_CONTAINER_USER}" \
    "${PROJECT_CONTAINER_NAME}" \
    "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}" sql-dump \
      --skip-tables-list=migrate_* \
      --structure-tables-list=cache*,history,node_counter,search_*,sessions,watchdog \
      --result-file=${PROJECT_CONTAINER_DUMP}/dump_${_NOW}.sql
}

_restore() {

  $_DOCKER exec \
    $tty \
    --interactive \
    --user "${PROJECT_CONTAINER_USER}" \
    "${PROJECT_CONTAINER_NAME}" \
    "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}" -y sql-drop

  $_DOCKER exec \
    $tty \
    --interactive \
    --user "${PROJECT_CONTAINER_USER}" \
    "${PROJECT_CONTAINER_NAME}" \
    "${DRUSH_BIN}" "${PROJECT_CONTAINER_ROOT}"  sql-cli < "${PROJECT_CONTAINER_DUMP}"/dump.sql
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

  _check_dependencies_docker

  # Run actions.
  if [[ "${1:-}" =~ ^dump$ ]]
  then
    _dump
  elif [[ "${1:-}" =~ ^restore$ ]]
  then
    _restore
  else
    _print_help
  fi
}

# Call `_main` after everything has been defined.
_main "$@"

