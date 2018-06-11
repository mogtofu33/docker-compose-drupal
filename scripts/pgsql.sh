#!/usr/bin/env bash
# ____   ____   ____                         _
# |  _ \ / ___| |  _ \ _ __ _   _ _ __   __ _| |
# | | | | |     | | | | '__| | | | '_ \ / _  | |
# | |_| | |___  | |_| | |  | |_| | |_) | (_| | |
# |____/ \____| |____/|_|   \__,_| .__/ \__,_|_|
#                               |_|
#
# Helper to run postgres dump/restore, part of Docker Compose Drupal project.
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

Helper to dump and restore PGSQL db with pg_dump and pg_restore.

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
  docker exec $tty "${PROJECT_CONTAINER_PGSQL}" mkdir -p "${PROJECT_CONTAINER_DUMP}"
  docker exec $tty "${PROJECT_CONTAINER_PGSQL}" chown -R "$PGSQL_USER_ID" "${PROJECT_CONTAINER_DUMP}"

  # If we have an existing dump.
  docker exec $tty "${PROJECT_CONTAINER_PGSQL}" rm -f "${PROJECT_CONTAINER_DUMP}"/dump_${_NOW}.pg_dump

  docker exec \
    $tty \
    --user "${PGSQL_USER}" \
    "${PROJECT_CONTAINER_PGSQL}" \
      pg_dump -d "${POSTGRES_DB}" -U "${PGSQL_USER}" -hlocalhost -Fc -c -b -v -f ${PROJECT_CONTAINER_DUMP}/dump_${_NOW}.pg_dump \
      --exclude-table-data '*.cache*' --exclude-table-data '*.cachetags*' \
      --exclude-table-data '*.watchdog*' --exclude-table-data '*.node_access*' \
      --exclude-table-data '*.search_api_db_*' --exclude-table-data '*.sessions*' \
      --exclude-table-data '*.sessions*' --exclude-table-data '*.webprofiler*' 
}

_restore() {

  docker exec $tty "${PROJECT_CONTAINER_PGSQL}" mkdir -p "${PROJECT_CONTAINER_DUMP}"
  docker exec $tty "${PROJECT_CONTAINER_PGSQL}" chown -R "${PGSQL_USER_ID}" "${PROJECT_CONTAINER_DUMP}"

  docker exec \
    $tty \
    --user "${PGSQL_USER}" \
    "${PROJECT_CONTAINER_PGSQL}" \
      dropdb --if-exists "${POSTGRES_DB}"
  docker exec \
    $tty \
    --user "${PGSQL_USER}" \
    "${PROJECT_CONTAINER_PGSQL}" \
      createdb -e --owner="${PGSQL_USER}" "${POSTGRES_DB}"
  docker exec \
    $tty \
    --user "${PGSQL_USER}" \
    "${PROJECT_CONTAINER_PGSQL}" \
      psql -e -d ${POSTGRES_DB} -c "GRANT ALL ON database ${POSTGRES_DB} TO ${PGSQL_USER}"
  docker exec \
    $tty \
    --user "${PGSQL_USER}" \
    "${PROJECT_CONTAINER_PGSQL}" \
      pg_restore -h localhost -p 5432 --no-owner --role="${PGSQL_USER}" -U "${PGSQL_USER}" -d "${POSTGRES_DB}" -v ${PROJECT_CONTAINER_DUMP}/dump.pg_dump
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

